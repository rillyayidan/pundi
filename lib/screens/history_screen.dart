import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../widgets/transaction_tile.dart';
import 'add_transaction_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _period = 'all';

  Future<void> _applyPeriod(String value) async {
    final provider = context.read<TransactionProvider>();
    final now = DateTime.now();
    final previous = _period;
    if (value == 'custom') {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now.add(const Duration(days: 1)),
        initialDateRange:
            provider.filterFrom != null && provider.filterToExclusive != null
            ? DateTimeRange(
                start: provider.filterFrom!,
                end: provider.filterToExclusive!.subtract(
                  const Duration(days: 1),
                ),
              )
            : null,
      );
      if (!mounted) {
        return;
      }
      if (picked == null) {
        setState(() => _period = previous);
        return;
      }
      setState(() => _period = value);
      await provider.applyFilter(
        from: DateTime(picked.start.year, picked.start.month, picked.start.day),
        toExclusive: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day + 1,
        ),
        category: provider.filterCategory,
      );
      return;
    }
    setState(() => _period = value);
    if (value == 'month') {
      await provider.applyFilter(
        from: DateTime(now.year, now.month),
        toExclusive: DateTime(now.year, now.month + 1),
        category: provider.filterCategory,
      );
    } else {
      await provider.applyFilter(category: provider.filterCategory);
    }
  }

  Future<void> _showActions(TransactionModel transaction) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Hapus transaksi'),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus transaksi?'),
                    content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  await context.read<TransactionProvider>().delete(
                    transaction.id!,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final items = provider.transactions;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<TransactionProvider>().load(keepFilters: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'month',
                                label: Text('Bulan ini'),
                              ),
                              ButtonSegment(value: 'all', label: Text('Semua')),
                              ButtonSegment(
                                value: 'custom',
                                label: Text('Kustom'),
                              ),
                            ],
                            selected: {_period},
                            onSelectionChanged: (value) =>
                                _applyPeriod(value.first),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String?>(
                          tooltip: 'Filter kategori',
                          icon: Badge(
                            isLabelVisible: provider.filterCategory != null,
                            child: const Icon(Icons.tune_rounded),
                          ),
                          onSelected: (category) => provider.applyFilter(
                            from: provider.filterFrom,
                            toExclusive: provider.filterToExclusive,
                            category: category,
                          ),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: null,
                              child: Text('Semua kategori'),
                            ),
                            ...[...expenseCategories, ...incomeCategories].map(
                              (category) => PopupMenuItem(
                                value: category.name,
                                child: Text(category.name),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (provider.filterCategory != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InputChip(
                          label: Text(provider.filterCategory!),
                          onDeleted: () => provider.applyFilter(
                            from: provider.filterFrom,
                            toExclusive: provider.filterToExclusive,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Belum ada transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Coba ubah filter atau tambahkan transaksi baru.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddTransactionScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tambah transaksi'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return TransactionTile(
                      transaction: item,
                      onDelete: () => _showActions(item),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
