import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/recurring_rule_model.dart';
import '../models/transaction_model.dart';
import '../providers/app_features_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/category_picker.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  Future<void> _record(BuildContext context, RecurringRuleModel rule) async {
    await context.read<TransactionProvider>().add(
      rule.toTransaction(date: DateTime.now()),
    );
    if (!context.mounted) return;
    await context.read<AppFeaturesProvider>().advanceRecurring(rule);
    if (!context.mounted) return;
    await context.read<DashboardProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final features = context.watch<AppFeaturesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Transaksi berulang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecurringEditorScreen()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Jadwal baru'),
      ),
      body: features.recurringRules.isEmpty
          ? const _RecurringEmpty()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                if (features.dueRules.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      '${features.dueRules.length} transaksi menunggu konfirmasi. Pundi tidak akan mencatatnya tanpa persetujuanmu.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                ...features.recurringRules.map(
                  (rule) => _RecurringCard(
                    rule: rule,
                    due: features.dueRules.any((item) => item.id == rule.id),
                    onRecord: () => _record(context, rule),
                    onSkip: () => features.advanceRecurring(rule),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecurringEditorScreen(rule: rule),
                      ),
                    ),
                    onDelete: () => features.deleteRecurringRule(rule),
                  ),
                ),
              ],
            ),
    );
  }
}

class RecurringEditorScreen extends StatefulWidget {
  const RecurringEditorScreen({super.key, this.rule});
  final RecurringRuleModel? rule;

  @override
  State<RecurringEditorScreen> createState() => _RecurringEditorScreenState();
}

class _RecurringEditorScreenState extends State<RecurringEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _merchant;
  late final TextEditingController _note;
  late TransactionType _type;
  late String _category;
  late RecurrenceFrequency _frequency;
  late DateTime _nextDate;
  late bool _active;
  late int _walletId;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _type = rule?.type ?? TransactionType.expense;
    _category = rule?.category ?? categoriesFor(_type).first.name;
    _frequency = rule?.frequency ?? RecurrenceFrequency.monthly;
    _nextDate = rule?.nextDate ?? DateTime.now().add(const Duration(days: 1));
    _active = rule?.isActive ?? true;
    _walletId = rule?.walletId ?? 1;
    _amount = TextEditingController(
      text: rule == null ? '' : rule.amount.toStringAsFixed(0),
    );
    _merchant = TextEditingController(text: rule?.merchant ?? '');
    _note = TextEditingController(text: rule?.note ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(
        () => _nextDate = DateTime(picked.year, picked.month, picked.day, 9),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AppFeaturesProvider>().saveRecurringRule(
      RecurringRuleModel(
        id: widget.rule?.id,
        type: _type,
        amount: parseRupiahInput(_amount.text)!,
        category: _category,
        frequency: _frequency,
        nextDate: _nextDate,
        walletId: _walletId,
        merchant: _merchant.text.trim().isEmpty ? null : _merchant.text.trim(),
        note: _note.text.trim(),
        isActive: _active,
        createdAt: widget.rule?.createdAt,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.rule == null ? 'Jadwal baru' : 'Edit jadwal'),
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Pengeluaran'),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Pemasukan'),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (value) => setState(() {
              _type = value.first;
              _category = categoriesFor(_type).first.name;
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
            controller: _merchant,
            decoration: const InputDecoration(
              labelText: 'Nama transaksi / merchant',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 18),
          const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          CategoryPicker(
            type: _type,
            value: _category,
            onChanged: (value) => setState(() => _category = value),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<RecurrenceFrequency>(
            initialValue: _frequency,
            decoration: const InputDecoration(
              labelText: 'Frekuensi',
              prefixIcon: Icon(Icons.repeat_rounded),
            ),
            items: RecurrenceFrequency.values
                .map(
                  (frequency) => DropdownMenuItem(
                    value: frequency,
                    child: Text(frequency.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(
              () => _frequency = value ?? RecurrenceFrequency.monthly,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            tileColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            leading: Icon(
              Icons.event_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Jadwal berikutnya'),
            subtitle: Text(formatDate(_nextDate)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Catatan'),
          ),
          SwitchListTile(
            value: _active,
            onChanged: (value) => setState(() => _active = value),
            title: const Text('Jadwal aktif'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 14),
          Consumer<WalletProvider>(
            builder: (context, provider, _) {
              if (provider.wallets.isEmpty) return const SizedBox.shrink();
              if (!provider.wallets.any((wallet) => wallet.id == _walletId)) {
                _walletId = provider.wallets.first.id!;
              }
              return DropdownButtonFormField<int>(
                initialValue: _walletId,
                decoration: const InputDecoration(
                  labelText: 'Sumber dana',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                items: provider.wallets
                    .map(
                      (wallet) => DropdownMenuItem(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _walletId = value ?? _walletId),
              );
            },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Simpan jadwal'),
          ),
        ],
      ),
    ),
  );
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.rule,
    required this.due,
    required this.onRecord,
    required this.onSkip,
    required this.onEdit,
    required this.onDelete,
  });
  final RecurringRuleModel rule;
  final bool due;
  final VoidCallback onRecord;
  final VoidCallback onSkip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = categoryByName(rule.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(category.icon, color: category.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.merchant ?? rule.category,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${rule.frequency.label} · ${formatDate(rule.nextDate)}',
                      ),
                    ],
                  ),
                ),
                Text(
                  formatRupiah(rule.amount),
                  style: TextStyle(
                    color: rule.type == TransactionType.expense
                        ? pundiCoral
                        : successTeal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            if (due) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkip,
                      child: const Text('Lewati kali ini'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: onRecord,
                      child: const Text('Catat sekarang'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecurringEmpty extends StatelessWidget {
  const _RecurringEmpty();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(38),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_repeat_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum ada transaksi rutin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buat pengingat untuk gaji, kos, cicilan, atau langganan.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
