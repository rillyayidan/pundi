import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final now = DateTime.now();
    final thisMonth = transactions.allTransactions.where(
      (item) => item.date.year == now.year && item.date.month == now.month,
    );
    final monthIncome = thisMonth
        .where((item) => item.type == TransactionType.income)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final monthExpense = thisMonth
        .where((item) => item.type == TransactionType.expense)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<TransactionProvider>().load(),
          context.read<DashboardProvider>().load(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/images/pundi_icon.png',
                    width: 38,
                    height: 38,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pundi'),
                    Text(
                      'Uangmu, lebih terarah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            sliver: SliverList.list(
              children: [
                _BalanceHero(
                  balance: transactions.balance,
                  monthLabel: formatMonth(now),
                  monthNet: monthIncome - monthExpense,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        label: 'Pemasukan bulan ini',
                        amount: monthIncome,
                        icon: Icons.south_west_rounded,
                        color: brandGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SummaryCard(
                        label: 'Pengeluaran bulan ini',
                        amount: monthExpense,
                        icon: Icons.north_east_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Anggaran bulan ini',
                  action: '${dashboard.budgets.length} aktif',
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: dashboard.budgets.isEmpty
                        ? const _EmptyBudget()
                        : Column(
                            children: dashboard.budgets.entries
                                .take(3)
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
                ),
                const SizedBox(height: 28),
                _SectionTitle(
                  title: 'Transaksi terbaru',
                  action: '${transactions.allTransactions.length} total',
                ),
                const SizedBox(height: 8),
                if (transactions.loading &&
                    transactions.allTransactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (transactions.allTransactions.isEmpty)
                  const _EmptyTransactions()
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Column(
                        children: transactions.allTransactions
                            .take(5)
                            .map((item) => TransactionTile(transaction: item))
                            .toList(),
                      ),
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

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.balance,
    required this.monthLabel,
    required this.monthNet,
  });
  final double balance;
  final String monthLabel;
  final double monthNet;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [brandGreenDark, brandGreen],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: brandGreen.withValues(alpha: .22),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total saldo',
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatRupiah(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                monthLabel,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            Text(
              '${monthNet >= 0 ? '+' : ''}${formatRupiah(monthNet)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      Text(
        action,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ],
  );
}

class _EmptyBudget extends StatelessWidget {
  const _EmptyBudget();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: [
        Icon(Icons.flag_outlined),
        SizedBox(width: 12),
        Expanded(
          child: Text('Belum ada anggaran. Atur batas kategori di Pengaturan.'),
        ),
      ],
    ),
  );
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 14),
          const Text(
            'Pundi masih kosong',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 6),
          Text(
            'Tambahkan transaksi pertama atau pindai struk belanja.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
