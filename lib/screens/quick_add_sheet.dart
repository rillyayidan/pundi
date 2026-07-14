import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/category_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'add_transaction_screen.dart';

Future<bool?> showQuickAddSheet(
  BuildContext context, {
  TransactionType initialType = TransactionType.expense,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => QuickAddSheet(initialType: initialType),
);

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key, required this.initialType});

  final TransactionType initialType;

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _amount = TextEditingController();
  late TransactionType _type;
  late String _category;
  int _walletId = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _category = categoriesFor(_type).first.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wallets = context.read<WalletProvider>().wallets;
      if (wallets.isNotEmpty) setState(() => _walletId = wallets.first.id ?? 1);
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setType(TransactionType value) {
    setState(() {
      _type = value;
      _category = context.read<CategoryProvider>().forType(value).first.name;
    });
  }

  Future<void> _save() async {
    final amount = parseRupiahInput(_amount.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal yang valid.')),
      );
      return;
    }
    final transaction = TransactionModel(
      type: _type,
      amount: amount,
      category: _category,
      date: DateTime.now(),
      walletId: _walletId,
    );
    final provider = context.read<TransactionProvider>();
    final duplicate = provider.findPotentialDuplicate(transaction);
    if (duplicate != null) {
      final keep = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kemungkinan transaksi ganda'),
          content: Text(
            '${formatRupiah(duplicate.amount)} pada ${duplicate.category} baru saja dicatat. Tetap simpan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tetap simpan'),
            ),
          ],
        ),
      );
      if (keep != true || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await provider.add(transaction);
      if (!mounted) return;
      await Future.wait([
        context.read<DashboardProvider>().load(),
        context.read<WalletProvider>().load(),
      ]);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openFullForm() async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await navigator.push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(initialType: _type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().forType(_type);
    final wallets = context.watch<WalletProvider>().wallets;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Catat cepat',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    icon: Icon(Icons.arrow_upward_rounded),
                    label: Text('Pengeluaran'),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    icon: Icon(Icons.arrow_downward_rounded),
                    label: Text('Pemasukan'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) => _setType(value.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          categories.any((item) => item.name == _category)
                          ? _category
                          : categories.first.name,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.name,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _category = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: wallets.any((item) => item.id == _walletId)
                          ? _walletId
                          : wallets.firstOrNull?.id,
                      decoration: const InputDecoration(labelText: 'Dompet'),
                      items: wallets
                          .map(
                            (wallet) => DropdownMenuItem(
                              value: wallet.id,
                              child: Text(
                                wallet.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _walletId = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: const Text('Simpan sekarang'),
              ),
              TextButton(
                onPressed: _saving ? null : _openFullForm,
                child: const Text('Buka form lengkap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
