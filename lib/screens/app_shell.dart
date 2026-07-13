import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'scan_bill_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    HistoryScreen(),
    ScanBillScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _select(int value) {
    setState(() => _index = value);
    if (value == 0 || value == 3 || value == 4) {
      context.read<DashboardProvider>().load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(index: _index, children: _pages),
    ),
    floatingActionButton: _index == 0 || _index == 1
        ? FloatingActionButton.extended(
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
              );
              if (saved == true && context.mounted) {
                context.read<DashboardProvider>().load();
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Transaksi'),
          )
        : null,
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: _select,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Beranda',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Riwayat',
        ),
        NavigationDestination(
          icon: Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(Icons.document_scanner_rounded),
          label: 'Pindai',
        ),
        NavigationDestination(
          icon: Icon(Icons.donut_large_outlined),
          selectedIcon: Icon(Icons.donut_large_rounded),
          label: 'Statistik',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Pengaturan',
        ),
      ],
    ),
  );
}
