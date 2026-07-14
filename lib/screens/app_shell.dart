import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/home_widget_service.dart';
import '../utils/constants.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'quick_add_sheet.dart';
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
  final _homeWidget = HomeWidgetService();
  StreamSubscription<Uri?>? _widgetClicks;
  WalletProvider? _walletProvider;
  bool _quickAddOpen = false;

  static const _pages = [
    HomeScreen(),
    HistoryScreen(),
    ScanBillScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _widgetClicks = HomeWidget.widgetClicked.listen(_handleWidgetUri);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _handleWidgetUri(await HomeWidget.initiallyLaunchedFromHomeWidget());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<WalletProvider>();
    if (!identical(provider, _walletProvider)) {
      _walletProvider?.removeListener(_syncHomeWidget);
      _walletProvider = provider..addListener(_syncHomeWidget);
      _syncHomeWidget();
    }
  }

  @override
  void dispose() {
    _widgetClicks?.cancel();
    _walletProvider?.removeListener(_syncHomeWidget);
    super.dispose();
  }

  void _syncHomeWidget() {
    final provider = _walletProvider;
    if (provider != null && !provider.loading) {
      _homeWidget.syncBalance(provider.totalBalance);
    }
  }

  void _handleWidgetUri(Uri? uri) {
    final type = HomeWidgetService.typeFromUri(uri);
    if (type == null || !mounted || _quickAddOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showQuickAdd(type);
    });
  }

  Future<void> _showQuickAdd([
    TransactionType type = TransactionType.expense,
  ]) async {
    if (_quickAddOpen) return;
    _quickAddOpen = true;
    try {
      final saved = await showQuickAddSheet(context, initialType: type);
      if (saved == true && mounted) {
        context.read<DashboardProvider>().load();
      }
    } finally {
      _quickAddOpen = false;
    }
  }

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
          child: Stack(
            children: List.generate(_pages.length, (pageIndex) {
              final active = pageIndex == _index;
              return Positioned.fill(
                child: IgnorePointer(
                  ignoring: !active,
                  child: TickerMode(
                    enabled: active,
                    child: AnimatedOpacity(
                      opacity: active ? 1 : 0,
                      duration: const Duration(milliseconds: 210),
                      curve: Curves.easeOutCubic,
                      child: _pages[pageIndex],
                    ),
                  ),
                ),
              );
            }),
          ),
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
                onTap: _showQuickAdd,
                onLongPress: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const AddTransactionScreen(),
                  ),
                ),
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
        color: dark ? const Color(0xF2111D2F) : const Color(0xFAFFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .35),
        ),
        boxShadow: [
          BoxShadow(
            color: fintechNavy.withValues(alpha: dark ? .3 : .09),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selected
                        ? (itemIndex == 2
                              ? fintechAccent.withValues(alpha: .14)
                              : pundiLilac)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.$1,
                        size: 21,
                        color: selected
                            ? (itemIndex == 2 ? fintechAccent : fintechBlue)
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
                              ? (itemIndex == 2 ? fintechAccent : fintechBlue)
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
  const _AddButton({required this.onTap, required this.onLongPress});
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    elevation: 10,
    shadowColor: fintechBlue.withValues(alpha: .28),
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [fintechBlue, Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 29),
      ),
    ),
  );
}
