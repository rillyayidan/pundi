import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_features_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _pages = [
    (
      Icons.account_balance_wallet_rounded,
      'Kenali arus uangmu',
      'Catat pemasukan, pengeluaran, anggaran, dan target tabungan dalam satu aplikasi.',
      pundiViolet,
    ),
    (
      Icons.document_scanner_rounded,
      'Struk dibaca di HP',
      'OCR, merchant memory, dan pemisahan item bekerja langsung di perangkat tanpa server.',
      fintechAccent,
    ),
    (
      Icons.lock_rounded,
      'Privat sejak awal',
      'Database dienkripsi. Backup tetap menjadi kendalimu dan tidak dikirim ke cloud Pundi.',
      successTeal,
    ),
  ];

  Future<void> _finish(bool demo) async {
    setState(() => _finishing = true);
    await context.read<AppFeaturesProvider>().finishOnboarding(
      addDemoData: demo,
    );
    if (!mounted) return;
    await context.read<TransactionProvider>().load();
    if (!mounted) return;
    await context.read<DashboardProvider>().load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _page = value),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(34),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: page.$4.withValues(alpha: .14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(page.$1, size: 62, color: page.$4),
                      ),
                      const SizedBox(height: 34),
                      Text(
                        page.$2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page.$3,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.45),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: index == _page ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: index == _page ? pundiViolet : pundiLilac,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: _page < _pages.length - 1
                ? FilledButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    ),
                    child: const Text('Lanjut'),
                  )
                : Column(
                    children: [
                      FilledButton.icon(
                        onPressed: _finishing ? null : () => _finish(false),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Mulai dengan data kosong'),
                      ),
                      TextButton(
                        onPressed: _finishing ? null : () => _finish(true),
                        child: const Text('Coba dengan data demo'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}
