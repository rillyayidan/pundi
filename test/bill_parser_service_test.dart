import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/models/parsed_bill_model.dart';
import 'package:pundi/services/bill_parser_service.dart';

void main() {
  final parser = BillParserService();

  test('extracts merchant, explicit total, and Indonesian numeric date', () {
    const receipt = '''
      INDOMARET KEMANG
      Jl. Kemang Raya 12
      Tanggal 13/07/2026 14:22
      Subtotal Rp 72.500
      TOTAL BAYAR Rp 75.000
      Tunai Rp 100.000
      Kembali Rp 25.000
    ''';

    final result = parser.parse(receipt);

    expect(result.merchant, 'Indomaret Kemang');
    expect(result.amount, 75000);
    expect(result.date, DateTime(2026, 7, 13));
    expect(result.amountConfidence, ConfidenceLevel.high);
    expect(result.dateConfidence, ConfidenceLevel.high);
  });

  test('supports Indonesian month names', () {
    const receipt = '''
      KOPI NUSANTARA
      7 Juli 2026
      Grand Total 48.500
    ''';

    final result = parser.parse(receipt);

    expect(result.date, DateTime(2026, 7, 7));
    expect(result.dateConfidence, ConfidenceLevel.high);
    expect(result.amount, 48500);
  });

  test('falls back to largest number with low confidence', () {
    const receipt = '''
      TOKO MAJU
      Roti 12.000
      Susu 18.500
      30.500
    ''';

    final result = parser.parse(receipt);

    expect(result.amount, 30500);
    expect(result.amountConfidence, ConfidenceLevel.low);
  });

  test('returns an empty result for unusable OCR text', () {
    final result = parser.parse('*** --- ***');

    expect(result.hasUsefulData, isFalse);
  });

  test('extracts purchasable line items without treating total as an item', () {
    final result = parser.parse('''
TOKO CONTOH
Roti Tawar 18.000
Susu UHT 22.500
TOTAL 40.500
''');

    expect(result.lineItems, hasLength(2));
    expect(result.lineItems.first.label, 'Roti Tawar');
    expect(result.lineItems.first.amount, 18000);
  });
}
