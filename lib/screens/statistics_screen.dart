import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

enum _StatsRange { week, month, custom }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  _StatsRange _mode = _StatsRange.week;
  late DateTimeRange _range = _rangeFor(_mode);

  DateTimeRange _rangeFor(_StatsRange mode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (mode) {
      _StatsRange.week => DateTimeRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _StatsRange.month => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(
          now.year,
          now.month + 1,
        ).subtract(const Duration(days: 1)),
      ),
      _StatsRange.custom => _range,
    };
  }

  Future<void> _selectMode(_StatsRange mode) async {
    if (mode == _StatsRange.custom) {
      final selected = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: _range,
      );
      if (selected == null || !mounted) {
        return;
      }
      setState(() {
        _mode = mode;
        _range = selected;
      });
      return;
    }
    setState(() {
      _mode = mode;
      _range = _rangeFor(mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TransactionProvider>().allTransactions;
    final endExclusive = DateTime(
      _range.end.year,
      _range.end.month,
      _range.end.day + 1,
    );
    final filtered = all
        .where(
          (item) =>
              !item.date.isBefore(_range.start) &&
              item.date.isBefore(endExclusive),
        )
        .toList(growable: false);
    final categories = <String, double>{};
    for (final item in filtered.where((item) => item.isExpense)) {
      categories.update(
        item.category,
        (value) => value + item.amount,
        ifAbsent: () => item.amount,
      );
    }
    final buckets = _buildBuckets(filtered, _range);
    final income = filtered
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = filtered
        .where((item) => item.isExpense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return Scaffold(
      body: RefreshIndicator(
        color: pundiViolet,
        onRefresh: () => context.read<TransactionProvider>().load(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 160),
          children: [
            const Text(
              'STATISTIK',
              style: TextStyle(
                color: pundiCoral,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Baca pola uangmu',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 17),
            _RangeControl(mode: _mode, onChanged: _selectMode),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: pundiLilac,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    color: pundiViolet,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${formatDate(_range.start)} – ${formatDate(_range.end)}',
                      maxLines: 1,
                      style: const TextStyle(
                        color: pundiVioletDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_mode == _StatsRange.custom)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _selectMode(_StatsRange.custom),
                      icon: const Icon(Icons.edit_calendar_rounded),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TotalCard(
                    label: 'Masuk',
                    amount: income,
                    color: successTeal,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TotalCard(
                    label: 'Keluar',
                    amount: expense,
                    color: pundiCoral,
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _ChartTitle(eyebrow: 'ARUS KAS', title: 'Masuk vs keluar'),
            const SizedBox(height: 12),
            _CashFlowChart(buckets: buckets),
            const SizedBox(height: 28),
            const _ChartTitle(eyebrow: 'PENGELUARAN', title: 'Lari ke mana?'),
            const SizedBox(height: 12),
            _CategoryChart(values: categories),
          ],
        ),
      ),
    );
  }
}

List<_CashBucket> _buildBuckets(
  List<TransactionModel> transactions,
  DateTimeRange range,
) {
  final days = range.end.difference(range.start).inDays + 1;
  if (days > 62) {
    final start = DateTime(range.start.year, range.start.month);
    final end = DateTime(range.end.year, range.end.month);
    final count = (end.year - start.year) * 12 + end.month - start.month + 1;
    return List.generate(count, (index) {
      final month = DateTime(start.year, start.month + index);
      final monthEnd = DateTime(month.year, month.month + 1);
      return _bucket(
        transactions.where(
          (item) => !item.date.isBefore(month) && item.date.isBefore(monthEnd),
        ),
        '${month.month}/${month.year.toString().substring(2)}',
      );
    });
  }
  return List.generate(days, (index) {
    final day = DateTime(
      range.start.year,
      range.start.month,
      range.start.day + index,
    );
    final next = day.add(const Duration(days: 1));
    return _bucket(
      transactions.where(
        (item) => !item.date.isBefore(day) && item.date.isBefore(next),
      ),
      '${day.day}/${day.month}',
    );
  });
}

_CashBucket _bucket(Iterable<TransactionModel> items, String label) {
  var income = 0.0;
  var expense = 0.0;
  for (final item in items) {
    if (item.type == TransactionType.income) {
      income += item.amount;
    } else {
      expense += item.amount;
    }
  }
  return _CashBucket(label: label, income: income, expense: expense);
}

class _CashBucket {
  const _CashBucket({
    required this.label,
    required this.income,
    required this.expense,
  });
  final String label;
  final double income;
  final double expense;
}

class _RangeControl extends StatelessWidget {
  const _RangeControl({required this.mode, required this.onChanged});
  final _StatsRange mode;
  final ValueChanged<_StatsRange> onChanged;

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
        _RangeOption(
          label: '7 hari',
          selected: mode == _StatsRange.week,
          onTap: () => onChanged(_StatsRange.week),
        ),
        _RangeOption(
          label: 'Bulan ini',
          selected: mode == _StatsRange.month,
          onTap: () => onChanged(_StatsRange.month),
        ),
        _RangeOption(
          label: 'Kustom',
          selected: mode == _StatsRange.custom,
          onTap: () => onChanged(_StatsRange.custom),
        ),
      ],
    ),
  );
}

class _RangeOption extends StatelessWidget {
  const _RangeOption({
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
        height: 44,
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
            style: TextStyle(
              color: selected ? Colors.white : null,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 9),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatRupiah(amount),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    ),
  );
}

class _ChartTitle extends StatelessWidget {
  const _ChartTitle({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: const TextStyle(
          color: pundiCoral,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        title,
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w900,
          letterSpacing: -.8,
        ),
      ),
    ],
  );
}

class _CashFlowChart extends StatelessWidget {
  const _CashFlowChart({required this.buckets});
  final List<_CashBucket> buckets;

  @override
  Widget build(BuildContext context) {
    if (buckets.every((item) => item.income == 0 && item.expense == 0)) {
      return const _ChartEmpty(message: 'Belum ada transaksi di rentang ini.');
    }
    final largest = buckets.fold<double>(
      0,
      (value, item) => math.max(value, math.max(item.income, item.expense)),
    );
    final chartWidth = math.max(
      MediaQuery.sizeOf(context).width - 72,
      buckets.length * 38.0,
    );
    final labelStep = math.max(1, (buckets.length / 7).ceil());
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              height: 230,
              child: BarChart(
                BarChartData(
                  maxY: largest * 1.18,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: largest / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: .35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 ||
                              index >= buckets.length ||
                              index % labelStep != 0) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text(
                              buckets[index].label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(buckets.length, (index) {
                    final item = buckets[index];
                    return BarChartGroupData(
                      x: index,
                      barsSpace: 2,
                      barRods: [
                        BarChartRodData(
                          toY: item.income,
                          width: 6,
                          color: successTeal,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                        BarChartRodData(
                          toY: item.expense,
                          width: 6,
                          color: pundiCoral,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: successTeal, label: 'Masuk'),
              SizedBox(width: 18),
              _Legend(color: pundiCoral, label: 'Keluar'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.values});
  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const _ChartEmpty(
        message: 'Belum ada pengeluaran di rentang ini.',
      );
    }
    final sorted = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = values.values.fold<double>(0, (sum, value) => sum + value);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: 55,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                    sections: sorted.map((entry) {
                      final category = categoryByName(entry.key);
                      return PieChartSectionData(
                        value: entry.value,
                        color: category.color,
                        radius: 30,
                        showTitle: false,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      formatRupiah(total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...sorted.map((entry) {
            final category = categoryByName(entry.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: category.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${(entry.value / total * 100).round()}% · ${formatRupiah(entry.value)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: pundiLilac,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: pundiViolet,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
