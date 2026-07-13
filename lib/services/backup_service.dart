import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';

class BackupService {
  const BackupService(this._database);

  final DatabaseHelper _database;

  Future<File> createBackupFile() async {
    final backup = await _database.createBackup();
    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(directory.path, 'pundi_backup_$stamp.json'));
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
      flush: true,
    );
  }

  Future<void> shareBackup() async {
    final file = await createBackupFile();
    await SharePlus.instance.share(
      ShareParams(
        text: 'Cadangan lokal Pundi',
        files: [XFile(file.path, mimeType: 'application/json')],
      ),
    );
  }

  Future<void> restoreFromFile(String path) async {
    final text = await File(path).readAsString();
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Berkas bukan cadangan Pundi yang valid.');
    }
    await _database.restoreBackup(decoded);
  }
}
