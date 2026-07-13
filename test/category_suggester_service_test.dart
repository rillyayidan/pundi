import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/services/category_suggester_service.dart';

void main() {
  final suggester = CategorySuggesterService();

  test('maps common Indonesian merchants to a category', () {
    expect(suggester.suggest('Indomaret Kemang'), 'Belanja');
    expect(suggester.suggest('PT Pertamina'), 'Transportasi');
    expect(suggester.suggest('Apotek Kimia Farma'), 'Kesehatan');
  });

  test('uses raw OCR text when merchant is absent', () {
    expect(
      suggester.suggest(null, rawText: 'Terima kasih menggunakan GOFOOD'),
      'Makanan',
    );
  });

  test('falls back to Lainnya', () {
    expect(suggester.suggest('Usaha Tidak Dikenal'), 'Lainnya');
  });
}
