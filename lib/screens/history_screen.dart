import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  String _period = 'all';
  bool _showCategories = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    context.watch<CategoryProvider>();
    final items = provider.transactions;
    final categories = [...expenseCategories, ...incomeCategories];
    return Scaffold(
      body: RefreshIndicator(
        color: pundiViolet,
        onRefresh: () => provider.load(keepFilters: true),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RIWAYAT',
                      style: TextStyle(
                        color: fintechAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Semua jejak uang',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 17),
                    _PeriodControl(value: _period, onChanged: _applyPeriod),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: provider.setSearchQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari merchant, catatan, nominal...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: provider.searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () =>
                          setState(() => _showCategories = !_showCategories),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: provider.filterCategory == null
                              ? Theme.of(context).cardColor
                              : fintechBlue,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: provider.filterCategory == null
                                ? Theme.of(context).colorScheme.outlineVariant
                                      .withValues(alpha: .45)
                                : fintechBlue,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: provider.filterCategory == null
                                  ? fintechBlue
                                  : Colors.white,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                provider.filterCategory ?? 'Semua kategori',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: provider.filterCategory == null
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: _showCategories ? .5 : 0,
                              duration: const Duration(milliseconds: 220),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: provider.filterCategory == null
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _showCategories
                          ? Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 9),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  _CategoryChoice(
                                    label: 'Semua',
                                    selected: provider.filterCategory == null,
                                    onTap: () {
                                      provider.applyFilter(
                                        from: provider.filterFrom,
                                        toExclusive: provider.filterToExclusive,
                                      );
                                      setState(() => _showCategories = false);
                                    },
                                  ),
                                  ...categories.map(
                                    (category) => _CategoryChoice(
                                      label: category.name,
                                      selected:
                                          provider.filterCategory ==
                                          category.name,
                                      onTap: () {
                                        provider.applyFilter(
                                          from: provider.filterFrom,
                                          toExclusive:
                                              provider.filterToExclusive,
                                          category: category.name,
                                        );
                                        setState(() => _showCategories = false);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 17),
                    Row(
                      children: [
                        Text(
                          '${items.length} transaksi',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_period == 'custom' && provider.filterFrom != null)
                          Text(
                            '${formatShortDate(provider.filterFrom!)} – ${formatShortDate(provider.filterToExclusive!.subtract(const Duration(days: 1)))}',
                            style: const TextStyle(
                              color: pundiViolet,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(36, 0, 36, 100),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: pundiLilac,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: pundiViolet,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tidak ada transaksi',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Coba ganti rentang waktu atau kategori.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 160),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outlineVariant.withValues(alpha: .4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: TransactionTile(
                        transaction: item,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailScreen(
                              transactionId: item.id!,
                            ),
                          ),
                        ),
                      ),
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

class _PeriodControl extends StatelessWidget {
  const _PeriodControl({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 54,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        _PeriodOption(
          label: 'Bulan ini',
          selected: value == 'month',
          onTap: () => onChanged('month'),
        ),
        _PeriodOption(
          label: 'Semua',
          selected: value == 'all',
          onTap: () => onChanged('all'),
        ),
        _PeriodOption(
          label: 'Kustom',
          selected: value == 'custom',
          onTap: () => onChanged('custom'),
        ),
      ],
    ),
  );
}

class _PeriodOption extends StatelessWidget {
  const _PeriodOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? pundiViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
      ),
    ),
  );
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? pundiViolet : pundiLilac.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          color: selected ? Colors.white : pundiVioletDark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}
