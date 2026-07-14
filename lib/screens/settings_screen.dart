import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_features_provider.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/debt_provider.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/home_widget_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/budget_progress_bar.dart';
import '../utils/date_formatter.dart';
import 'recurring_screen.dart';
import 'custom_categories_screen.dart';
import 'savings_goals_screen.dart';
import 'trash_screen.dart';
import 'wallets_screen.dart';
import 'debts_screen.dart';

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

  Future<String?> _askBackupPassword(
    BuildContext context, {
    required bool confirm,
  }) async {
    final password = TextEditingController();
    final confirmation = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirm ? 'Kunci cadangan' : 'Buka cadangan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                helperText: 'Minimal 8 karakter dan jangan sampai lupa',
              ),
            ),
            if (confirm) ...[
              const SizedBox(height: 12),
              TextField(
                controller: confirmation,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Ulangi password'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, password.text),
            child: Text(confirm ? 'Enkripsi' : 'Buka'),
          ),
        ],
      ),
    );
    final confirmationValue = confirmation.text;
    password.dispose();
    confirmation.dispose();
    if (value == null) return null;
    if (value.length < 8 || (confirm && value != confirmationValue)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value.length < 8
                  ? 'Password minimal 8 karakter.'
                  : 'Konfirmasi password tidak sama.',
            ),
          ),
        );
      }
      return null;
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final transactions = context.watch<TransactionProvider>();
    final features = context.watch<AppFeaturesProvider>();
    final categoryProvider = context.watch<CategoryProvider>();
    final walletProvider = context.watch<WalletProvider>();
    final debtProvider = context.watch<DebtProvider>();
    final backup = BackupService(DatabaseHelper.instance);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
        children: [
          const Text(
            'PENGATURAN',
            style: TextStyle(
              color: pundiCoral,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Atur cara Pundi bekerja',
            style: TextStyle(
              fontSize: 29,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(height: 22),
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
          if (dashboard.overBudgetCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4DA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: pundiCoral),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${dashboard.overBudgetCategories.join(', ')} melewati anggaran. Tekan pengeluaran kategori ini sampai bulan berikutnya.',
                      style: const TextStyle(
                        color: Color(0xFF702918),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                children: categoryProvider
                    .forType(TransactionType.expense)
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
            'Otomasi & privasi',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const _SettingsIcon(
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  title: const Text(
                    'Wallet & akun',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${walletProvider.wallets.length} wallet · ${formatRupiah(walletProvider.totalBalance)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await walletProvider.load();
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WalletsScreen(),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.handshake_outlined),
                  title: const Text(
                    'Utang & piutang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Utang ${formatRupiah(debtProvider.totalPayable)} · piutang ${formatRupiah(debtProvider.totalReceivable)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DebtsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.category_rounded),
                  title: const Text(
                    'Kategori khusus',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${categoryProvider.customCategories.length} kategori buatanmu',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomCategoriesScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.savings_rounded),
                  title: const Text(
                    'Target tabungan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${features.savingsGoals.length} target aktif',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SavingsGoalsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(
                    icon: Icons.event_repeat_rounded,
                  ),
                  title: const Text(
                    'Transaksi berulang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    features.recurringRules.isEmpty
                        ? 'Atur gaji, kos, cicilan, atau langganan'
                        : '${features.recurringRules.length} jadwal · ${features.dueRules.length} menunggu',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecurringScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  secondary: const _SettingsIcon(
                    icon: Icons.notifications_active_outlined,
                  ),
                  title: const Text(
                    'Pengingat lokal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Jadwal rutin dan pengingat backup'),
                  value: features.notificationsEnabled,
                  onChanged: (value) async {
                    final success = await features.setNotificationsEnabled(
                      value,
                    );
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Izin notifikasi tidak diberikan oleh perangkat.',
                          ),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, indent: 72),
                SwitchListTile(
                  secondary: const _SettingsIcon(
                    icon: Icons.fingerprint_rounded,
                  ),
                  title: const Text(
                    'Kunci aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    features.securitySupported
                        ? 'Gunakan biometrik atau kunci layar perangkat'
                        : 'Keamanan perangkat tidak tersedia',
                  ),
                  value: features.lockEnabled,
                  onChanged: features.securitySupported
                      ? (value) async {
                          final success = await features.setLockEnabled(value);
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Autentikasi tidak berhasil.'),
                              ),
                            );
                          }
                        }
                      : null,
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.widgets_outlined),
                  title: const Text(
                    'Widget layar utama',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Saldo dan tombol catat cepat'),
                  trailing: const Icon(Icons.add_to_home_screen_rounded),
                  onTap: () => _run(
                    context,
                    HomeWidgetService().requestPin,
                    'Permintaan widget dikirim ke launcher.',
                  ),
                ),
              ],
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
          if (features.backupReminderNeeded) ...[
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: pundiLilac,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.backup_rounded, color: pundiViolet),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Ada data baru yang belum dicadangkan. Buat JSON agar aman saat aplikasi dihapus atau HP direset.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                  leading: const _SettingsIcon(
                    icon: Icons.file_download_outlined,
                  ),
                  title: const Text(
                    'Impor CSV',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Tambahkan transaksi dari spreadsheet'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['csv'],
                    );
                    final path = picked?.files.single.path;
                    if (path == null || !context.mounted) return;
                    await _run(context, () async {
                      final imported = await ImportService().parseCsv(path);
                      if (!context.mounted) return;
                      final unique = transactions.withoutDuplicates(imported);
                      final duplicateCount = imported.length - unique.length;
                      final importAll = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Impor ${imported.length} transaksi?'),
                          content: Text(
                            duplicateCount == 0
                                ? 'Data CSV akan ditambahkan tanpa menghapus transaksi yang sudah ada.'
                                : '$duplicateCount transaksi terindikasi ganda. Anda dapat melewatinya atau tetap mengimpor seluruh data.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Batal'),
                            ),
                            if (duplicateCount > 0)
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Lewati duplikat'),
                              ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                duplicateCount > 0 ? 'Impor semua' : 'Impor',
                              ),
                            ),
                          ],
                        ),
                      );
                      if (importAll == null) return;
                      final selected = importAll ? imported : unique;
                      if (selected.isEmpty) {
                        throw const FormatException(
                          'Semua transaksi pada CSV sudah pernah dicatat.',
                        );
                      }
                      await transactions.addAll(selected);
                      await dashboard.load();
                      await features.refresh();
                    }, 'CSV berhasil diimpor.');
                  },
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(icon: Icons.backup_rounded),
                  title: const Text(
                    'Cadangkan terenkripsi',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    features.lastBackupAt == null
                        ? 'Belum pernah dicadangkan'
                        : 'Terakhir ${formatDateTime(features.lastBackupAt!)}',
                  ),
                  trailing: const Icon(Icons.ios_share_rounded),
                  onTap: () async {
                    final password = await _askBackupPassword(
                      context,
                      confirm: true,
                    );
                    if (password == null || !context.mounted) return;
                    await _run(
                      context,
                      () => backup.shareBackup(
                        password,
                        onCreated: features.markBackupCreated,
                      ),
                      'Cadangan terenkripsi siap dibagikan.',
                    );
                  },
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
                    'Dari berkas .pundi atau JSON versi lama',
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
                      allowedExtensions: ['pundi', 'json'],
                    );
                    final path = picked?.files.single.path;
                    if (path == null || !context.mounted) {
                      return;
                    }
                    final transactionProvider = context
                        .read<TransactionProvider>();
                    final dashboardProvider = context.read<DashboardProvider>();
                    String? password;
                    try {
                      if (await backup.isEncryptedFile(path)) {
                        if (!context.mounted) return;
                        password = await _askBackupPassword(
                          context,
                          confirm: false,
                        );
                        if (password == null) return;
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Berkas tidak valid: $error')),
                        );
                      }
                      return;
                    }
                    if (!context.mounted) return;
                    await _run(context, () async {
                      await backup.restoreFromFile(path, password: password);
                      await transactionProvider.load();
                      await dashboardProvider.load();
                    }, 'Cadangan berhasil dipulihkan.');
                  },
                ),
                const Divider(height: 1, indent: 72),
                ListTile(
                  leading: const _SettingsIcon(
                    icon: Icons.delete_sweep_outlined,
                  ),
                  title: const Text(
                    'Sampah',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${transactions.trashedTransactions.length} transaksi · terhapus otomatis 30 hari',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  ),
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
                'Database SQLCipher terenkripsi; data keuangan dan OCR tetap berada di perangkat.',
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
