import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/services/backup_crypto_service.dart';

void main() {
  final crypto = BackupCryptoService(iterations: 10000);

  test('encrypted backup round-trips with the correct password', () async {
    const clearText = '{"transactions":[{"amount":12500}]}';
    final encrypted = await crypto.encrypt(clearText, 'rahasia-pundi');

    expect(encrypted['format'], BackupCryptoService.format);
    expect(encrypted['ciphertext'], isNot(contains('12500')));
    expect(await crypto.decrypt(encrypted, 'rahasia-pundi'), clearText);
  });

  test('wrong password cannot decrypt the backup', () async {
    final encrypted = await crypto.encrypt('{}', 'password-benar');

    expect(
      () => crypto.decrypt(encrypted, 'password-salah'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Password salah'),
        ),
      ),
    );
  });
}
