import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import '../providers/dashboard_provider.dart';
import '../providers/category_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../services/receipt_image_service.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  Future<void> _delete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text(
          'Transaksi dipindahkan ke Sampah dan bisa dipulihkan selama 30 hari.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: pundiCoral),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await context.read<TransactionProvider>().delete(transaction.id!);
    if (!context.mounted) {
      return;
    }
    await context.read<DashboardProvider>().load();
    if (!context.mounted) return;
    await context.read<WalletProvider>().load();
    if (!context.mounted) return;
    final provider = context.read<TransactionProvider>();
    final dashboard = context.read<DashboardProvider>();
    final wallets = context.read<WalletProvider>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, true);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaksi dipindahkan ke Sampah.'),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () async {
            await provider.restore(transaction.id!);
            await Future.wait([dashboard.load(), wallets.load()]);
          },
        ),
      ),
    );
  }

  Future<void> _removeReceiptImage(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final path = transaction.receiptImagePath;
    if (path == null) return;
    await context.read<TransactionProvider>().update(
      transaction.copyWith(clearReceiptImage: true),
    );
    final references = await DatabaseHelper.instance
        .countTransactionsUsingReceiptImage(path);
    if (references == 0) await ReceiptImageService().delete(path);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = context.watch<TransactionProvider>().findById(
      transactionId,
    );
    context.watch<CategoryProvider>();
    final wallet = context.watch<WalletProvider>().walletFor(
      transaction?.walletId ?? 1,
    );
    if (transaction == null) {
      return const Scaffold(
        body: Center(child: Text('Transaksi tidak ditemukan')),
      );
    }
    final category = categoryByName(transaction.category);
    final expense = transaction.type == TransactionType.expense;
    final accent = expense ? pundiCoral : successTeal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail transaksi'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            onPressed: () => Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(transaction: transaction),
              ),
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: .22),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 15),
                Text(
                  transaction.merchant?.isNotEmpty == true
                      ? transaction.merchant!
                      : transaction.category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${expense ? '-' : '+'}${formatRupiah(transaction.amount)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 33,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.category_outlined,
                  label: 'Kategori',
                  value: transaction.category,
                ),
                const Divider(height: 27),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Sumber dana',
                  value: wallet.name,
                ),
                const Divider(height: 27),
                _DetailRow(
                  icon: Icons.event_rounded,
                  label: 'Tanggal & jam',
                  value: formatDateTime(transaction.date),
                ),
                const Divider(height: 27),
                _DetailRow(
                  icon: Icons.notes_rounded,
                  label: 'Catatan',
                  value: transaction.note.isEmpty
                      ? 'Tidak ada catatan'
                      : transaction.note,
                ),
              ],
            ),
          ),
          if (transaction.receiptText?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              backgroundColor: Theme.of(context).cardColor,
              collapsedBackgroundColor: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              collapsedShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              leading: const Icon(Icons.document_scanner_outlined),
              title: const Text(
                'Teks hasil pindai',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SelectableText(transaction.receiptText!),
                ),
              ],
            ),
          ],
          if (transaction.receiptImagePath?.isNotEmpty == true &&
              File(transaction.receiptImagePath!).existsSync()) ...[
            const SizedBox(height: 16),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.file(
                            File(transaction.receiptImagePath!),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.file(
                        File(transaction.receiptImagePath!),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Foto struk tersimpan lokal',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              _removeReceiptImage(context, transaction),
                          child: const Text('Hapus foto'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(transaction: transaction),
              ),
            ),
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit transaksi'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: pundiCoral),
            onPressed: () => _delete(context, transaction),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Hapus transaksi'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    ],
  );
}
