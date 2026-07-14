import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/debt_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/debt_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class DebtsScreen extends StatelessWidget {
  const DebtsScreen({super.key});

  Future<void> _pay(BuildContext context, DebtModel debt) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bayar ${debt.type.label.toLowerCase()}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Maksimal ${formatRupiah(debt.remaining)}',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, parseRupiahInput(controller.text) ?? 0),
            child: const Text('Catat pembayaran'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null ||
        amount <= 0 ||
        amount > debt.remaining ||
        !context.mounted) {
      return;
    }
    await context.read<DebtProvider>().recordPayment(debt, amount);
    if (!context.mounted) return;
    await Future.wait([
      context.read<TransactionProvider>().load(keepFilters: true),
      context.read<DashboardProvider>().load(),
      context.read<WalletProvider>().load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Utang & piutang')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: pundiCoral,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DebtEditorScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Catatan baru'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: _DebtSummary(
                  label: 'Sisa utang',
                  amount: provider.totalPayable,
                  color: pundiCoral,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DebtSummary(
                  label: 'Sisa piutang',
                  amount: provider.totalReceivable,
                  color: successTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (provider.debts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                'Belum ada utang atau piutang.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ...provider.debts.map((debt) {
              final color = debt.type == DebtType.payable
                  ? pundiCoral
                  : successTeal;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              debt.type.label,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              debt.person,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) => value == 'edit'
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DebtEditorScreen(debt: debt),
                                    ),
                                  )
                                : provider.delete(debt),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Hapus'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: debt.progress,
                        minHeight: 9,
                        color: color,
                        backgroundColor: color.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        debt.isPaid
                            ? 'Lunas'
                            : 'Sisa ${formatRupiah(debt.remaining)} · jatuh tempo ${formatDate(debt.dueDate)}',
                        style: TextStyle(
                          color: debt.isPaid ? successTeal : null,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!debt.isPaid) ...[
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => _pay(context, debt),
                          child: const Text('Catat pembayaran'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DebtSummary extends StatelessWidget {
  const _DebtSummary({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final double amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 5),
        FittedBox(
          child: Text(
            formatRupiah(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class DebtEditorScreen extends StatefulWidget {
  const DebtEditorScreen({super.key, this.debt});
  final DebtModel? debt;
  @override
  State<DebtEditorScreen> createState() => _DebtEditorScreenState();
}

class _DebtEditorScreenState extends State<DebtEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _person;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late DebtType _type;
  late DateTime _dueDate;
  late int _walletId;

  @override
  void initState() {
    super.initState();
    final debt = widget.debt;
    _person = TextEditingController(text: debt?.person ?? '');
    _amount = TextEditingController(
      text: debt == null ? '' : debt.totalAmount.toStringAsFixed(0),
    );
    _note = TextEditingController(text: debt?.note ?? '');
    _type = debt?.type ?? DebtType.payable;
    _dueDate = debt?.dueDate ?? DateTime.now().add(const Duration(days: 30));
    _walletId = debt?.walletId ?? 1;
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<DebtProvider>().save(
      DebtModel(
        id: widget.debt?.id,
        type: _type,
        person: _person.text.trim(),
        totalAmount: parseRupiahInput(_amount.text)!,
        paidAmount: widget.debt?.paidAmount ?? 0,
        dueDate: _dueDate,
        walletId: _walletId,
        note: _note.text.trim(),
        createdAt: widget.debt?.createdAt,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<WalletProvider>().wallets;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debt == null ? 'Catatan baru' : 'Edit catatan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            SegmentedButton<DebtType>(
              segments: const [
                ButtonSegment(
                  value: DebtType.payable,
                  label: Text('Saya berutang'),
                ),
                ButtonSegment(
                  value: DebtType.receivable,
                  label: Text('Dipinjam orang'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (value) =>
                  setState(() => _type = value.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _person,
              decoration: const InputDecoration(
                labelText: 'Nama orang/lembaga',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Nama wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Total',
                prefixText: 'Rp ',
              ),
              validator: (value) => (parseRupiahInput(value ?? '') ?? 0) <= 0
                  ? 'Nominal wajib diisi'
                  : null,
            ),
            const SizedBox(height: 12),
            if (wallets.isNotEmpty)
              DropdownButtonFormField<int>(
                initialValue: _walletId,
                decoration: const InputDecoration(
                  labelText: 'Wallet pembayaran',
                ),
                items: wallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _walletId = value ?? _walletId),
              ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Jatuh tempo'),
              subtitle: Text(formatDate(_dueDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Catatan'),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}
