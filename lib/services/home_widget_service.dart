import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class HomeWidgetService {
  static const _provider = 'com.rilly.pundi.PundiWidgetProvider';

  Future<void> syncBalance(double balance) async {
    try {
      await HomeWidget.saveWidgetData<String>('balance', formatRupiah(balance));
      await HomeWidget.saveWidgetData<String>(
        'updated_at',
        DateTime.now().toIso8601String(),
      );
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } on PlatformException catch (error) {
      debugPrint('Home widget tidak dapat diperbarui: $error');
    }
  }

  Future<void> requestPin() =>
      HomeWidget.requestPinWidget(qualifiedAndroidName: _provider);

  static TransactionType? typeFromUri(Uri? uri) {
    if (uri == null || uri.scheme != 'pundi' || uri.host != 'quick-add') {
      return null;
    }
    return uri.queryParameters['type'] == 'income'
        ? TransactionType.income
        : TransactionType.expense;
  }
}
