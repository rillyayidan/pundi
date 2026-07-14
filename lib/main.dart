import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'database/database_helper.dart';
import 'providers/dashboard_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/app_features_provider.dart';
import 'providers/category_provider.dart';
import 'providers/wallet_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  final database = DatabaseHelper.instance;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider(database)..load()),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(database)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider(database)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(database)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => AppFeaturesProvider(database)..initialize(),
        ),
      ],
      child: const PundiApp(),
    ),
  );
}
