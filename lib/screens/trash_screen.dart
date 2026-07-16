import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/transaction_tile.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final items = provider.trashedTransactions;
    return Scaffold(
      appBar: AppBar(title: const Text('Sampah')),
      body: items.isEmpty
          ? const Center(child: Text('Sampah kosong.'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final daysLeft =
                    30 - DateTime.now().difference(item.deletedAt!).inDays;
                return Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 8, 10),
                    child: Column(
                      children: [
                        TransactionTile(transaction: item),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Dihapus ${formatDate(item.deletedAt!)} · ${daysLeft.clamp(0, 30)} hari tersisa',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                await provider.restore(item.id!);
                                if (context.mounted) {
                                  await context
                                      .read<DashboardProvider>()
                                      .load();
                                  if (context.mounted) {
                                    await context.read<WalletProvider>().load();
                                  }
                                }
                              },
                              child: const Text('Pulihkan'),
                            ),
                            IconButton(
                              tooltip: 'Hapus permanen',
                              color: pundiCoral,
                              onPressed: () =>
                                  provider.permanentlyDelete(item.id!),
                              icon: const Icon(Icons.delete_forever_outlined),
                            ),
                          ],
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
