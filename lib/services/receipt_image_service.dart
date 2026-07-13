import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ReceiptImageService {
  Future<String?> persist(String? sourcePath) async {
    if (sourcePath == null || sourcePath.isEmpty) return null;
    final source = File(sourcePath);
    if (!await source.exists()) return null;
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(root.path, 'receipt_images'));
    if (!await directory.exists()) await directory.create(recursive: true);
    final extension = p.extension(source.path).isEmpty
        ? '.jpg'
        : p.extension(source.path);
    final target = p.join(
      directory.path,
      'receipt_${DateTime.now().microsecondsSinceEpoch}$extension',
    );
    return (await source.copy(target)).path;
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
