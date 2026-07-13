import 'dart:io';

import 'package:csv/csv.dart';

import '../models/transaction_model.dart';

class ImportService {
  Future<List<TransactionModel>> parseCsv(String path) async {
    final text = await File(path).readAsString();
    final rows = Csv().decode(text.replaceFirst('\ufeff', ''));
    if (rows.length < 2) {
      throw const FormatException('CSV tidak memiliki data transaksi.');
    }
    final headers = rows.first
        .map((value) => value.toString().trim().toLowerCase())
        .toList();
    int column(String name) => headers.indexOf(name.toLowerCase());
    final typeIndex = column('tipe');
    final amountIndex = column('jumlah');
    final categoryIndex = column('kategori');
    final dateIndex = column('tanggal');
    final noteIndex = column('catatan');
    final merchantIndex = column('merchant');
    if ([typeIndex, amountIndex, categoryIndex, dateIndex].contains(-1)) {
      throw const FormatException(
        'Header wajib: Tipe, Jumlah, Kategori, dan Tanggal.',
      );
    }

    final result = <TransactionModel>[];
    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      String valueAt(int columnIndex) =>
          columnIndex < 0 || columnIndex >= row.length
          ? ''
          : row[columnIndex].toString().trim();
      if (row.every((value) => value.toString().trim().isEmpty)) continue;
      final amount = double.tryParse(
        valueAt(amountIndex).replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      final date = DateTime.tryParse(valueAt(dateIndex));
      final category = valueAt(categoryIndex);
      if (amount == null || amount <= 0 || date == null || category.isEmpty) {
        throw FormatException('Baris ${index + 1} tidak valid.');
      }
      final typeText = valueAt(typeIndex).toLowerCase();
      result.add(
        TransactionModel(
          type: typeText.contains('masuk') || typeText.contains('income')
              ? TransactionType.income
              : TransactionType.expense,
          amount: amount,
          category: category,
          date: date,
          note: valueAt(noteIndex),
          merchant: valueAt(merchantIndex).isEmpty
              ? null
              : valueAt(merchantIndex),
        ),
      );
    }
    if (result.isEmpty) {
      throw const FormatException('Tidak ada transaksi yang dapat diimpor.');
    }
    return result;
  }
}
