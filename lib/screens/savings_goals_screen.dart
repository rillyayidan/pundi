import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/savings_goal_model.dart';
import '../providers/app_features_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  Future<void> _contribute(BuildContext context, SavingsGoalModel goal) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah ke ${goal.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(prefixText: 'Rp '),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, parseRupiahInput(controller.text) ?? 0),
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null && amount > 0 && context.mounted) {
      await context.read<AppFeaturesProvider>().addGoalContribution(
        goal,
        amount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = context.watch<AppFeaturesProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Target tabungan')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: pundiCoral,
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => const _GoalEditor(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Target baru'),
      ),
      body: features.savingsGoals.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(38),
                child: Text(
                  'Buat target seperti dana darurat, laptop, atau liburan.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              itemCount: features.savingsGoals.length,
              itemBuilder: (context, index) {
                final goal = features.savingsGoals[index];
                final color = Color(goal.colorValue);
                final months =
                    ((goal.targetDate.difference(DateTime.now()).inDays) / 30)
                        .ceil()
                        .clamp(1, 1200);
                final monthly = goal.remaining / months;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: .14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.savings_rounded, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text('Target ${formatDate(goal.targetDate)}'),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (_) => _GoalEditor(goal: goal),
                                  );
                                } else {
                                  await features.deleteSavingsGoal(goal);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: goal.progress,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(99),
                          color: color,
                          backgroundColor: color.withValues(alpha: .12),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${formatRupiah(goal.currentAmount)} dari ${formatRupiah(goal.targetAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text('${(goal.progress * 100).round()}%'),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          goal.remaining <= 0
                              ? 'Target tercapai!'
                              : 'Saran setoran ${formatRupiah(monthly)} per bulan',
                          style: TextStyle(
                            color: goal.remaining <= 0
                                ? successTeal
                                : pundiViolet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: goal.remaining <= 0
                              ? null
                              : () => _contribute(context, goal),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tambah tabungan'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({this.goal});
  final SavingsGoalModel? goal;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.goal?.name ?? '');
    _target = TextEditingController(
      text: widget.goal == null
          ? ''
          : widget.goal!.targetAmount.toStringAsFixed(0),
    );
    _date =
        widget.goal?.targetDate ??
        DateTime.now().add(const Duration(days: 180));
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final target = parseRupiahInput(_target.text) ?? 0;
    if (_name.text.trim().isEmpty || target <= 0) return;
    await context.read<AppFeaturesProvider>().saveSavingsGoal(
      SavingsGoalModel(
        id: widget.goal?.id,
        name: _name.text.trim(),
        targetAmount: target,
        currentAmount: widget.goal?.currentAmount ?? 0,
        targetDate: _date,
        colorValue: widget.goal?.colorValue ?? pundiViolet.toARGB32(),
        createdAt: widget.goal?.createdAt,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target tabungan',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nama target'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Jumlah target',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              leading: const Icon(Icons.event_rounded),
              title: const Text('Tanggal target'),
              subtitle: Text(formatDate(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Simpan target'),
            ),
          ],
        ),
      ),
    ),
  );
}
