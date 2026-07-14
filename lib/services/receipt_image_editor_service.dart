import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';

class ReceiptImageEditorService {
  Future<String?> crop(BuildContext context, String sourcePath) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 94,
      maxWidth: 2400,
      maxHeight: 4000,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Potong & putar struk',
          toolbarColor: pundiViolet,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: fintechAccent,
          lockAspectRatio: false,
          aspectRatioPresets: const [CropAspectRatioPreset.original],
        ),
        IOSUiSettings(
          title: 'Potong & putar struk',
          doneButtonTitle: 'Selesai',
          cancelButtonTitle: 'Batal',
          aspectRatioPresets: const [CropAspectRatioPreset.original],
        ),
        WebUiSettings(context: context),
      ],
    );
    return cropped?.path;
  }

  Future<String> rotateClockwise(String sourcePath) async {
    final decoded = image.decodeImage(await File(sourcePath).readAsBytes());
    if (decoded == null) throw const FormatException('Gambar tidak valid.');
    final rotated = image.copyRotate(image.bakeOrientation(decoded), angle: 90);
    return _writeTemporary(rotated, 'rotated');
  }

  Future<String> enhance(String sourcePath) async {
    final bytes = await File(sourcePath).readAsBytes();
    final enhanced = enhanceBytes(bytes);
    final directory = await getTemporaryDirectory();
    final target = File(
      path.join(
        directory.path,
        'pundi_receipt_enhanced_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    await target.writeAsBytes(enhanced, flush: true);
    return target.path;
  }

  Uint8List enhanceBytes(Uint8List bytes) {
    final decoded = image.decodeImage(bytes);
    if (decoded == null) throw const FormatException('Gambar tidak valid.');
    final oriented = image.bakeOrientation(decoded);
    final enhanced = image.adjustColor(
      oriented,
      saturation: 0,
      contrast: 1.35,
      brightness: 1.06,
    );
    return Uint8List.fromList(image.encodeJpg(enhanced, quality: 94));
  }

  Future<String> _writeTemporary(image.Image value, String suffix) async {
    final directory = await getTemporaryDirectory();
    final target = File(
      path.join(
        directory.path,
        'pundi_receipt_${suffix}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ),
    );
    await target.writeAsBytes(image.encodeJpg(value, quality: 94), flush: true);
    return target.path;
  }
}
