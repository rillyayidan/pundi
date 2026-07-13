import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

String formatRupiah(num value) => _rupiah.format(value);

String digitsOnlyRupiah(num value) =>
    NumberFormat.decimalPattern('id_ID').format(value);

double? parseRupiahInput(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.isEmpty ? null : double.tryParse(digits);
}
