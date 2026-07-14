import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:pundi/services/receipt_image_editor_service.dart';

void main() {
  test('enhancement returns a readable grayscale jpeg', () {
    final source = image.Image(width: 8, height: 6);
    image.fill(source, color: image.ColorRgb8(220, 180, 130));
    final bytes = Uint8List.fromList(image.encodePng(source));

    final result = ReceiptImageEditorService().enhanceBytes(bytes);
    final decoded = image.decodeJpg(result);

    expect(decoded, isNotNull);
    expect(decoded!.width, 8);
    expect(decoded.height, 6);
    final pixel = decoded.getPixel(0, 0);
    expect((pixel.r - pixel.g).abs(), lessThanOrEqualTo(2));
    expect((pixel.g - pixel.b).abs(), lessThanOrEqualTo(2));
  });
}
