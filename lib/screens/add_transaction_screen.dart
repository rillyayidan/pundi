import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/parsed_bill_model.dart';
import '../models/transaction_model.dart';
import '../models/split_part_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/category_suggester_service.dart';
import '../services/receipt_image_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/category_picker.dart';
import 'split_receipt_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.parsedBill, this.transaction});

  final ParsedBillModel? parsedBill;
  final TransactionModel? transaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late TransactionType _type;
  late String _category;
  late DateTime _date;
  bool _saving = false;
  bool _merchantRemembered = false;
  List<SplitPartModel>? _splitParts;

  bool get _editing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final parsed = widget.parsedBill;
    final transaction = widget.transaction;
    _type = transaction?.type ?? TransactionType.expense;
    _amountController = TextEditingController(
      text: transaction != null
          ? digitsOnlyRupiah(transaction.amount)
          : parsed?.amount == null
          ? ''
          : digitsOnlyRupiah(parsed!.amount!),
    );
    _merchantController = TextEditingController(
      text: transaction?.merchant ?? parsed?.merchant ?? '',
    );
    _noteController = TextEditingController(text: transaction?.note ?? '');
    final now = DateTime.now();
    _date =
        transaction?.date ??
        (parsed?.date == null
            ? now
            : DateTime(
                parsed!.date!.year,
                parsed.date!.month,
                parsed.date!.day,
                now.hour,
                now.minute,
              ));
    _category =
        transaction?.category ??
        (parsed == null
            ? categoriesFor(_type).first.name
            : CategorySuggesterService().suggest(
                parsed.merchant,
                rawText: parsed.rawText,
              ));
    if ((_merchantController.text.trim()).isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _applyMerchantMemory(),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    try {
      final amount = parseRupiahInput(_amountController.text)!;
      final receiptImagePath =
          widget.transaction?.receiptImagePath ??
          await ReceiptImageService().persist(
            widget.parsedBill?.sourceImagePath,
          );
      if (!mounted) return;
      final splitParts = _splitParts;
      if (splitParts != null &&
          (splitParts.fold<double>(0, (sum, part) => sum + part.amount) -
                      amount)
                  .abs() >
              .5) {
        throw const FormatException(
          'Total pembagian tidak sama dengan nominal transaksi.',
        );
      }
      final transaction = TransactionModel(
        id: widget.transaction?.id,
        type: _type,
        amount: amount,
        category: _category,
        date: _date,
        note: _noteController.text.trim(),
        merchant: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
        receiptText:
            widget.parsedBill?.rawText ?? widget.transaction?.receiptText,
        receiptImagePath: receiptImagePath,
        createdAt: widget.transaction?.createdAt,
      );
      final provider = context.read<TransactionProvider>();
      if (_editing) {
        await provider.update(transaction);
      } else if (splitParts != null) {
        await provider.addAll(
          splitParts
              .map(
                (part) => TransactionModel(
                  type: _type,
                  amount: part.amount,
                  category: part.category,
                  date: _date,
                  note: [
                    if (part.label.isNotEmpty) part.label,
                    if (_noteController.text.trim().isNotEmpty)
                      _noteController.text.trim(),
                  ].join(' — '),
                  merchant: transaction.merchant,
                  receiptText: transaction.receiptText,
                  receiptImagePath: receiptImagePath,
                ),
              )
              .toList(growable: false),
        );
      } else {
        await provider.add(transaction);
      }
      if (!mounted) {
        return;
      }
      final dashboard = context.read<DashboardProvider>();
      await dashboard.load();
      if (_type == TransactionType.expense && mounted) {
        final limit = dashboard.limitFor(_category);
        final spent = dashboard.spentFor(_category);
        if (limit > 0 && spent > limit) {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: pundiCoral,
                size: 44,
              ),
              title: const Text('Anggaran terlewati'),
              content: Text(
                'Pengeluaran $_category sudah ${formatRupiah(spent - limit)} di atas anggaran bulan ini. Sebaiknya tekan pengeluaran kategori ini sampai periode berikutnya.',
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Saya mengerti'),
                ),
              ],
            ),
          );
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _applyMerchantMemory() async {
    final merchant = _merchantController.text.trim();
    if (merchant.isEmpty || !mounted) return;
    final remembered = await context
        .read<TransactionProvider>()
        .rememberedCategory(merchant);
    if (!mounted || remembered == null || remembered == _category) return;
    if (!categoriesFor(_type).any((item) => item.name == remembered)) return;
    setState(() {
      _category = remembered;
      _merchantRemembered = true;
    });
  }

  Future<void> _openSplit() async {
    final total = parseRupiahInput(_amountController.text) ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi nominal total terlebih dahulu.')),
      );
      return;
    }
    final parsedItems = widget.parsedBill?.lineItems ?? const [];
    final initialParts =
        _splitParts ??
        parsedItems
            .map(
              (item) => SplitPartModel(
                amount: item.amount,
                category: item.suggestedCategory,
                label: item.label,
              ),
            )
            .toList(growable: false);
    final result = await Navigator.push<List<SplitPartModel>>(
      context,
      MaterialPageRoute(
        builder: (_) => SplitReceiptScreen(
          total: total,
          initialCategory: _category,
          initialParts: initialParts,
        ),
      ),
    );
    if (result != null && mounted) setState(() => _splitParts = result);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          _date.year,
          _date.month,
          _date.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        _editing
            ? 'Edit transaksi'
            : widget.parsedBill == null
            ? 'Transaksi baru'
            : 'Periksa hasil pindai',
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 38),
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: TransactionType.values.map((type) {
                final selected = _type == type;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      _type = type;
                      _category = categoriesFor(type).first.name;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 48,
                      decoration: BoxDecoration(
                        color: selected
                            ? type == TransactionType.expense
                                  ? pundiCoral
                                  : successTeal
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        type == TransactionType.expense
                            ? 'Pengeluaran'
                            : 'Pemasukan',
                        maxLines: 1,
                        style: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _amountController,
            autofocus: !_editing && widget.parsedBill == null,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
            decoration: const InputDecoration(
              labelText: 'Nominal',
              prefixText: 'Rp ',
            ),
            validator: (value) => (parseRupiahInput(value ?? '') ?? 0) <= 0
                ? 'Masukkan nominal lebih dari 0'
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _merchantController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              FocusScope.of(context).unfocus();
              _applyMerchantMemory();
            },
            decoration: const InputDecoration(
              labelText: 'Merchant (opsional)',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Pilih kategori',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          CategoryPicker(
            type: _type,
            value: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          if (_merchantRemembered) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: pundiViolet, size: 18),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Kategori dipilih dari koreksi merchant sebelumnya.',
                    style: TextStyle(
                      color: pundiVioletDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!_editing && _type == TransactionType.expense) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _openSplit,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _splitParts == null
                      ? Theme.of(context).cardColor
                      : pundiLilac,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _splitParts == null
                        ? Theme.of(context).colorScheme.outlineVariant
                        : pundiViolet.withValues(alpha: .35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.call_split_rounded, color: pundiViolet),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _splitParts == null
                                ? 'Bagi ke beberapa kategori'
                                : '${_splitParts!.length} bagian aktif',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            _splitParts == null
                                ? widget.parsedBill?.lineItems.isNotEmpty ==
                                          true
                                      ? '${widget.parsedBill!.lineItems.length} item OCR siap diperiksa'
                                      : 'Cocok untuk satu struk dengan isi campuran'
                                : 'Ketuk untuk memeriksa pembagian',
                          ),
                        ],
                      ),
                    ),
                    if (_splitParts != null)
                      IconButton(
                        onPressed: () => setState(() => _splitParts = null),
                        icon: const Icon(Icons.close_rounded),
                      )
                    else
                      const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _DateTimeField(
                  label: 'Tanggal',
                  value: formatDate(_date),
                  icon: Icons.calendar_today_outlined,
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _DateTimeField(
                  label: 'Jam',
                  value: formatTime(_date),
                  icon: Icons.schedule_rounded,
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _noteController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _saving
                  ? 'Menyimpan...'
                  : _editing
                  ? 'Simpan perubahan'
                  : 'Simpan transaksi',
            ),
          ),
        ],
      ),
    ),
  );
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.fade,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
