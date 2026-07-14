import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pundi/app.dart';
import 'package:pundi/database/database_helper.dart';
import 'package:pundi/providers/app_features_provider.dart';

void main() {
  testWidgets('Pundi renders the protected startup experience', (tester) async {
    final features = AppFeaturesProvider(DatabaseHelper.instance)
      ..initialized = true
      ..onboardingSeen = true
      ..lockEnabled = true
      ..locked = true;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: features, child: const PundiApp()),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Verifikasi perangkat'), findsOneWidget);
    expect(find.text('Verifikasi dan buka'), findsOneWidget);
  });
}
