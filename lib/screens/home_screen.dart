import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_detail_screen.dart';

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
      ]),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(month: formatMonth(now))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 160),
            sliver: SliverList.list(
              children: [
                _BalanceCard(
                  balance: transactions.balance,
                  income: income,
                  expense: expense,
                ),
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
                      borderRadius: BorderRadius.circular(28),
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
                      borderRadius: BorderRadius.circular(28),
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
  const _Header({required this.month});
  final String month;

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
            color: const Color(0xFFFFFCF8),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 16,
              ),
            ],
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
                'Halo, apa kabar?',
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
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: pundiLilac,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: pundiVioletDark,
          ),
        ),
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
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: pundiViolet,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: pundiViolet.withValues(alpha: .24),
          blurRadius: 32,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -35,
          top: -55,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              color: pundiCoral.withValues(alpha: .82),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 50,
          top: 58,
          child: Transform.rotate(
            angle: -.22,
            child: Container(
              width: 90,
              height: 22,
              decoration: BoxDecoration(
                color: pundiAmber.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL SALDO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 35,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.4,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: _MoneyStat(
                      icon: Icons.south_west_rounded,
                      label: 'Masuk',
                      value: income,
                    ),
                  ),
                  Container(width: 1, height: 38, color: Colors.white24),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _MoneyStat(
                      icon: Icons.north_east_rounded,
                      label: 'Keluar',
                      value: expense,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MoneyStat extends StatelessWidget {
  const _MoneyStat({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
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
        color: const Color(0xFFFFE4DA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pundiCoral.withValues(alpha: .25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: pundiCoral,
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
                    color: Color(0xFF702918),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${names.join(', ')} sudah melewati batas bulan ini. Sebaiknya tekan pengeluaran kategori ini sampai periode berikutnya.',
                  style: const TextStyle(
                    color: Color(0xFF702918),
                    height: 1.35,
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
