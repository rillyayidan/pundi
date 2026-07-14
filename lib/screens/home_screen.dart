import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/app_features_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/recurring_rule_model.dart';
import '../models/savings_goal_model.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';
import 'recurring_screen.dart';
import 'savings_goals_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _recordRecurring(
    BuildContext context,
    RecurringRuleModel rule,
  ) async {
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
    final transactions = context.watch<TransactionProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final features = context.watch<AppFeaturesProvider>();
    final wallets = context.watch<WalletProvider>();
    final now = DateTime.now();
    final thisMonth = transactions.allTransactions.where(
      (item) => item.date.year == now.year && item.date.month == now.month,
    );
    final income = thisMonth
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expense = thisMonth
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return RefreshIndicator(
      color: pundiViolet,
      onRefresh: () => Future.wait([
        context.read<TransactionProvider>().load(),
        context.read<DashboardProvider>().load(),
        context.read<WalletProvider>().load(),
      ]),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Header(
              month: formatMonth(now),
              dueCount: features.dueRules.length,
              onNotificationsTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecurringScreen()),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 160),
            sliver: SliverList.list(
              children: [
                _BalanceCard(
                  balance: wallets.totalBalance,
                  income: income,
                  expense: expense,
                ),
                if (features.dueRules.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _DueRecurringCard(
                    rule: features.dueRules.first,
                    remaining: features.dueRules.length - 1,
                    onRecord: () =>
                        _recordRecurring(context, features.dueRules.first),
                    onOpen: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecurringScreen(),
                      ),
                    ),
                  ),
                ],
                if (features.backupReminderNeeded) ...[
                  const SizedBox(height: 12),
                  const _BackupNudge(),
                ],
                if (dashboard.overBudgetCategories.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _BudgetWarning(dashboard: dashboard),
                ],
                const SizedBox(height: 28),
                _SectionHeader(
                  eyebrow: 'KONTROL BULANAN',
                  title: 'Jaga ritme belanja',
                  trailing: '${dashboard.budgets.length} anggaran',
                ),
                const SizedBox(height: 12),
                if (dashboard.budgets.isEmpty)
                  const _EmptyBudget()
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: .45),
                      ),
                    ),
                    child: Column(
                      children: dashboard.budgets.entries
                          .take(4)
                          .map(
                            (entry) => BudgetProgressBar(
                              category: entry.key,
                              spent: dashboard.spentFor(entry.key),
                              limit: entry.value,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (dashboard.forecasts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ForecastCard(forecast: dashboard.forecasts.first),
                ],
                if (features.savingsGoals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SavingsGoalCard(
                    goal: features.savingsGoals.first,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SavingsGoalsScreen(),
                      ),
                    ),
                  ),
                ],
                if (transactions.allTransactions.isNotEmpty) ...[
                  const SizedBox(height: 30),
                  _MonthlyInsights(dashboard: dashboard),
                ],
                const SizedBox(height: 30),
                _SectionHeader(
                  eyebrow: 'TERKINI',
                  title: 'Jejak uangmu',
                  trailing: '${transactions.allTransactions.length} transaksi',
                ),
                const SizedBox(height: 12),
                if (transactions.loading &&
                    transactions.allTransactions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (transactions.allTransactions.isEmpty)
                  const _EmptyTransactions()
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: .45),
                      ),
                    ),
                    child: Column(
                      children: transactions.allTransactions.take(5).map((
                        item,
                      ) {
                        return TransactionTile(
                          transaction: item,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailScreen(
                                transactionId: item.id!,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.month,
    required this.dueCount,
    required this.onNotificationsTap,
  });
  final String month;
  final int dueCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .45),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/images/pundi_icon.png'),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan keuangan',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                month,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.7,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: onNotificationsTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: dueCount > 0
                  ? dangerRed.withValues(alpha: .12)
                  : pundiLilac,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  dueCount > 0
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: dueCount > 0 ? dangerRed : fintechBlue,
                ),
                if (dueCount > 0)
                  Positioned(
                    right: 5,
                    top: 4,
                    child: Container(
                      width: 15,
                      height: 15,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: dangerRed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$dueCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DueRecurringCard extends StatelessWidget {
  const _DueRecurringCard({
    required this.rule,
    required this.remaining,
    required this.onRecord,
    required this.onOpen,
  });
  final RecurringRuleModel rule;
  final int remaining;
  final VoidCallback onRecord;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: pundiLilac,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.event_repeat_rounded, color: pundiViolet),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaksi rutin menunggu',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${rule.merchant ?? rule.category} · ${formatRupiah(rule.amount)}${remaining > 0 ? ' +$remaining lainnya' : ''}',
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onOpen,
                child: const Text('Lihat semua'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: onRecord,
                child: const Text('Catat'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BackupNudge extends StatelessWidget {
  const _BackupNudge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: pundiAmber.withValues(alpha: .24),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Row(
      children: [
        Icon(Icons.backup_rounded, color: Color(0xFF8A5D00)),
        SizedBox(width: 11),
        Expanded(
          child: Text(
            'Data baru belum dicadangkan. Buka Atur untuk membuat backup terenkripsi.',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.forecast});
  final BudgetForecast forecast;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: pundiLilac,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        const Icon(Icons.auto_graph_rounded, color: pundiViolet),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'Prediksi: ',
              style: const TextStyle(fontWeight: FontWeight.w900),
              children: [
                TextSpan(
                  text:
                      'anggaran ${forecast.category} bisa habis sekitar ${formatDate(forecast.estimatedDate)}.',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SavingsGoalCard extends StatelessWidget {
  const _SavingsGoalCard({required this.goal, required this.onTap});
  final SavingsGoalModel goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorValue);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.savings_rounded, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text('${(goal.progress * 100).round()}%'),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: goal.progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(99),
              color: color,
              backgroundColor: color.withValues(alpha: .12),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatRupiah(goal.currentAmount)} dari ${formatRupiah(goal.targetAmount)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyInsights extends StatelessWidget {
  const _MonthlyInsights({required this.dashboard});
  final DashboardProvider dashboard;

  @override
  Widget build(BuildContext context) {
    final change = dashboard.monthChangePercent;
    final biggest = dashboard.largestIncreaseCategory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'INSIGHT BULANAN',
          title: 'Yang berubah',
          trailing: 'offline',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InsightTile(
                icon: change != null && change > 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                title: change == null
                    ? 'Belum ada pembanding'
                    : '${change.abs().toStringAsFixed(0)}% ${change >= 0 ? 'naik' : 'turun'}',
                caption: 'vs bulan lalu',
                color: change != null && change > 0 ? pundiCoral : successTeal,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _InsightTile(
                icon: Icons.category_rounded,
                title: biggest ?? 'Belum terlihat',
                caption: 'kenaikan terbesar',
                color: pundiViolet,
              ),
            ),
          ],
        ),
        if (dashboard.unusualCategories.isNotEmpty) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dangerRed.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Tidak biasa: ${dashboard.unusualCategories.join(', ')} diproyeksikan naik setidaknya 50% dari rata-rata 3 bulan.',
              style: const TextStyle(
                color: dangerRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        if (dashboard.weekendExpenseShare >= .35) ...[
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pundiAmber.withValues(alpha: .22),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '${(dashboard.weekendExpenseShare * 100).round()}% pengeluaran 90 hari terakhir terjadi saat akhir pekan.',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.title,
    required this.caption,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        Text(caption, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
  });
  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [fintechNavy, Color(0xFF164E9A), fintechBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: fintechBlue.withValues(alpha: .2),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SALDO TERSEDIA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.25,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.white70,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'OFFLINE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatRupiah(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MoneyStat(
                    icon: Icons.south_west_rounded,
                    label: 'Pemasukan',
                    value: income,
                    color: const Color(0xFF5EEAD4),
                  ),
                ),
                Container(width: 1, height: 38, color: Colors.white12),
                const SizedBox(width: 14),
                Expanded(
                  child: _MoneyStat(
                    icon: Icons.north_east_rounded,
                    label: 'Pengeluaran',
                    value: expense,
                    color: const Color(0xFFFDA4AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MoneyStat extends StatelessWidget {
  const _MoneyStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatRupiah(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BudgetWarning extends StatelessWidget {
  const _BudgetWarning({required this.dashboard});
  final DashboardProvider dashboard;

  @override
  Widget build(BuildContext context) {
    final names = dashboard.overBudgetCategories;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: dangerRed.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dangerRed.withValues(alpha: .2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: dangerRed,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.priority_high_rounded, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anggaran terlewati',
                  style: TextStyle(
                    color: dangerRed,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${names.join(', ')} sudah melewati batas bulan ini. Sebaiknya tekan pengeluaran kategori ini sampai periode berikutnya.',
                  style: const TextStyle(color: dangerRed, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.trailing,
  });
  final String eyebrow;
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              style: const TextStyle(
                color: fintechAccent,
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
        ),
      ),
      Text(
        trailing,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(26),
    ),
    child: const Row(
      children: [
        Icon(Icons.flag_outlined, color: pundiViolet),
        SizedBox(width: 13),
        Expanded(
          child: Text(
            'Belum ada anggaran. Kamu bisa mengaturnya dari menu Atur.',
          ),
        ),
      ],
    ),
  );
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: pundiLilac,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.savings_outlined,
            color: pundiViolet,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Pundi masih sepi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 5),
        Text(
          'Tambahkan transaksi atau pindai struk pertamamu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}
