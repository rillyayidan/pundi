import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/transaction_model.dart';
import 'package:pundi/services/home_widget_service.dart';

void main() {
  test('parses quick-add transaction type from widget URI', () {
    expect(
      HomeWidgetService.typeFromUri(Uri.parse('pundi://quick-add?type=income')),
      TransactionType.income,
    );
    expect(
      HomeWidgetService.typeFromUri(
        Uri.parse('pundi://quick-add?type=expense'),
      ),
      TransactionType.expense,
    );
    expect(
      HomeWidgetService.typeFromUri(Uri.parse('https://example.com')),
      isNull,
    );
  });
}
