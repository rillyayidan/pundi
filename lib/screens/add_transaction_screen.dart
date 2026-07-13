import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/parsed_bill_model.dart';
import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/category_suggester_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/category_picker.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.parsedBill});

  final ParsedBillModel? parsedBill;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  TransactionType _type = TransactionType.expense;
  late String _category;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final parsed = widget.parsedBill;
    _amountController = TextEditingController(
      text: parsed?.amount == null ? '' : digitsOnlyRupiah(parsed!.amount!),
    );
    _merchantController = TextEditingController(text: parsed?.merchant ?? '');
    _noteController = TextEditingController();
    _date = parsed?.date ?? DateTime.now();
    _category = parsed == null
        ? expenseCategories.first.name
        : CategorySuggesterService().suggest(
            parsed.merchant,
            rawText: parsed.rawText,
          );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<TransactionProvider>().add(
        TransactionModel(
          type: _type,
          amount: parseRupiahInput(_amountController.text)!,
          category: _category,
          date: _date,
          note: _noteController.text.trim(),
          merchant: _merchantController.text.trim().isEmpty
              ? null
              : _merchantController.text.trim(),
          receiptText: widget.parsedBill?.rawText,
        ),
      );
      if (!mounted) {
        return;
      }
      await context.read<DashboardProvider>().load();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.parsedBill == null
            ? 'Tambah transaksi'
            : 'Konfirmasi hasil pindai',
      ),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Pengeluaran'),
                icon: Icon(Icons.north_east_rounded),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Pemasukan'),
                icon: Icon(Icons.south_west_rounded),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() {
              _type = value.first;
              _category = categoriesFor(_type).first.name;
            }),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _amountController,
            autofocus: widget.parsedBill == null,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(
              labelText: 'Jumlah',
              prefixText: 'Rp ',
            ),
            validator: (value) => (parseRupiahInput(value ?? '') ?? 0) <= 0
                ? 'Masukkan jumlah lebih dari 0'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _merchantController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Merchant (opsional)',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Kategori',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          CategoryPicker(
            type: _type,
            value: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 22),
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Tanggal',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                formatDate(_date),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            label: Text(_saving ? 'Menyimpan...' : 'Simpan transaksi'),
          ),
        ],
      ),
    ),
  );
}
