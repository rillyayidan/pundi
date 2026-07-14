import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:pundi/database/database_helper.dart';
import 'package:pundi/providers/app_features_provider.dart';
import 'package:pundi/providers/category_provider.dart';
import 'package:pundi/providers/dashboard_provider.dart';
import 'package:pundi/providers/debt_provider.dart';
import 'package:pundi/providers/transaction_provider.dart';
import 'package:pundi/providers/wallet_provider.dart';
import 'package:pundi/screens/app_shell.dart';

void main() {
  testWidgets('bottom navigation can move left and right repeatedly', (
    tester,
  ) async {
    await initializeDateFormatting('id_ID');
    final database = DatabaseHelper.instance;
    final features = AppFeaturesProvider(database)
      ..initialized = true
      ..onboardingSeen = true;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => WalletProvider(database)),
          ChangeNotifierProvider(create: (_) => DebtProvider(database)),
          ChangeNotifierProvider(create: (_) => CategoryProvider(database)),
          ChangeNotifierProvider(create: (_) => TransactionProvider(database)),
          ChangeNotifierProvider(create: (_) => DashboardProvider(database)),
          ChangeNotifierProvider.value(value: features),
        ],
        child: const MaterialApp(
          home: AppShell(enablePlatformIntegrations: false),
        ),
      ),
    );

    expect(find.text('Ringkasan keuangan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('Semua jejak uang'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-0')));
    await tester.pumpAndSettle();
    expect(find.text('Ringkasan keuangan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-4')));
    await tester.pumpAndSettle();
    expect(find.text('Atur cara Pundi bekerja'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-1')));
    await tester.pumpAndSettle();
    expect(find.text('Semua jejak uang'), findsOneWidget);
  });
}
