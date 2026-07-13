import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/budget_progress_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _setBudget(BuildContext context, String category) async {
    final dashboard = context.read<DashboardProvider>();
    final controller = TextEditingController(
      text: dashboard.limitFor(category) <= 0
          ? ''
          : dashboard.limitFor(category).toStringAsFixed(0),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Anggaran $category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Batas per bulan',
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
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && context.mounted) {
      await dashboard.setBudget(category, value);
    }
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() operation,
    String success,
  ) async {
    try {
      await operation();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final transactions = context.watch<TransactionProvider>();
    final backup = BackupService(DatabaseHelper.instance);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          Text(
            'Anggaran kategori',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Ketuk kategori untuk mengatur batas bulanan.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                children: expenseCategories
                    .map(
                      (category) => BudgetProgressBar(
                        category: category.name,
                        spent: dashboard.spentFor(category.name),
                        limit: dashboard.limitFor(category.name),
                        onTap: () => _setBudget(context, category.name),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Data & cadangan',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.table_view_rounded),
                  title: const Text(
                    'Ekspor CSV',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${transactions.allTransactions.length} transaksi',
                  ),
                  trailing: const Icon(Icons.ios_share_rounded),
                  onTap: transactions.allTransactions.isEmpty
                      ? null
                      : () => _run(
                          context,
                          () => ExportService().shareCsv(
                            transactions.allTransactions,
                          ),
                          'CSV siap dibagikan.',
                        ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.backup_rounded),
                  title: const Text(
                    'Cadangkan ke JSON',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Simpan seluruh transaksi & anggaran'),
                  trailing: const Icon(Icons.ios_share_rounded),
                  onTap: () => _run(
                    context,
                    backup.shareBackup,
                    'Cadangan siap dibagikan.',
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(
                    icon: Icons.settings_backup_restore_rounded,
                  ),
                  title: const Text(
                    'Pulihkan cadangan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Mengganti data saat ini dari berkas JSON',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pulihkan cadangan?'),
                        content: const Text(
                          'Semua data Pundi saat ini akan diganti oleh isi cadangan.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Pilih berkas'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) {
                      return;
                    }
                    final picked = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    final path = picked?.files.single.path;
                    if (path == null || !context.mounted) {
                      return;
                    }
                    final transactionProvider = context
                        .read<TransactionProvider>();
                    final dashboardProvider = context.read<DashboardProvider>();
                    await _run(context, () async {
                      await backup.restoreFromFile(path);
                      await transactionProvider.load();
                      await dashboardProvider.load();
                    }, 'Cadangan berhasil dipulihkan.');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Card(
            child: const ListTile(
              leading: _SettingsIcon(icon: Icons.lock_outline_rounded),
              title: Text(
                '100% offline',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Data keuangan dan OCR tetap berada di perangkat. Tidak ada akun atau sinkronisasi cloud.',
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'Pundi 1.0.0 · Dibuat dengan Flutter',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 21),
  );
}
