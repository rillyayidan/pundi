import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_helper.dart';
import 'backup_crypto_service.dart';

class BackupService {
  const BackupService(this._database);

  final DatabaseHelper _database;
  static final BackupCryptoService _crypto = BackupCryptoService();

  Future<File> createBackupFile(String password) async {
    final backup = await _database.createBackup();
    final encrypted = await _crypto.encrypt(jsonEncode(backup), password);
    final directory = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File(p.join(directory.path, 'pundi_backup_$stamp.pundi'));
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(encrypted),
      flush: true,
    );
  }

  Future<void> shareBackup(
    String password, {
    Future<void> Function()? onCreated,
  }) async {
    final file = await createBackupFile(password);
    await SharePlus.instance.share(
      ShareParams(
        text: 'Cadangan terenkripsi Pundi',
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
      ),
    );
    await onCreated?.call();
  }

  Future<bool> isEncryptedFile(String path) async {
    final text = await File(path).readAsString();
    final decoded = jsonDecode(text);
    return _crypto.isEncrypted(decoded);
  }

  Future<void> restoreFromFile(String path, {String? password}) async {
    final text = await File(path).readAsString();
    Object? decoded = jsonDecode(text);
    if (_crypto.isEncrypted(decoded)) {
      if (password == null || password.isEmpty) {
        throw const FormatException('Password cadangan diperlukan.');
      }
      final clearText = await _crypto.decrypt(
        Map<String, Object?>.from(decoded as Map),
        password,
      );
      decoded = jsonDecode(clearText);
    }
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Berkas bukan cadangan Pundi yang valid.');
    }
    await _database.restoreBackup(decoded);
  }
}
