import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dashboard_provider.dart';
import '../utils/constants.dart';
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
    body: Stack(
      children: [
        SafeArea(
          bottom: false,
          child: IndexedStack(index: _index, children: _pages),
        ),
        Positioned(
          left: 14,
          right: 14,
          bottom: 10,
          child: SafeArea(
            top: false,
            child: _BottomDock(index: _index, onSelect: _select),
          ),
        ),
        if (_index == 0 || _index == 1)
          Positioned(
            right: 24,
            bottom: 92,
            child: SafeArea(
              top: false,
              child: _AddButton(
                onTap: () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const AddTransactionScreen(),
                    ),
                  );
                  if (saved == true && context.mounted) {
                    context.read<DashboardProvider>().load();
                  }
                },
              ),
            ),
          ),
      ],
    ),
  );
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.receipt_long_rounded, 'Riwayat'),
    (Icons.document_scanner_rounded, 'Pindai'),
    (Icons.insights_rounded, 'Statistik'),
    (Icons.tune_rounded, 'Atur'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: dark ? const Color(0xF52B2735) : const Color(0xF7FFFCF8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? .28 : .1),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
        child: Row(
          children: List.generate(_items.length, (itemIndex) {
            final item = _items[itemIndex];
            final selected = index == itemIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onSelect(itemIndex),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? (itemIndex == 2 ? pundiCoral : pundiViolet)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 21,
                        color: selected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: pundiCoral,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 8,
    shadowColor: pundiCoral.withValues(alpha: .35),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: const SizedBox(
        width: 58,
        height: 58,
        child: Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    ),
  );
}
