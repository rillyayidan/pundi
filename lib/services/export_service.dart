import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction_model.dart';

class ExportService {
  Future<File> createCsv(List<TransactionModel> transactions) async {
    final rows = <List<Object?>>[
      ['ID', 'Tipe', 'Jumlah', 'Kategori', 'Tanggal', 'Catatan', 'Merchant'],
      ...transactions.map(
        (transaction) => [
          transaction.id,
          transaction.type == TransactionType.income
              ? 'Pemasukan'
              : 'Pengeluaran',
          transaction.amount,
          transaction.category,
          DateFormat('yyyy-MM-dd').format(transaction.date),
          transaction.note,
          transaction.merchant ?? '',
        ],
      ),
    ];
    final csvText = Csv().encode(rows);
    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(directory.path, 'pundi_transaksi_$stamp.csv'));
    return file.writeAsString('\ufeff$csvText', flush: true);
  }

  Future<void> shareCsv(List<TransactionModel> transactions) async {
    final file = await createCsv(transactions);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Ekspor transaksi Pundi',
        files: [XFile(file.path, mimeType: 'text/csv')],
      ),
    );
  }
}
