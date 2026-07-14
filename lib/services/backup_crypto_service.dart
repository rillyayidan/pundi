import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class BackupCryptoService {
  BackupCryptoService({this.iterations = 120000});

  static const String format = 'pundi-encrypted-backup';
  final int iterations;
  final AesGcm _cipher = AesGcm.with256bits();

  bool isEncrypted(Object? value) => value is Map && value['format'] == format;

  Future<Map<String, Object?>> encrypt(
    String clearText,
    String password,
  ) async {
    if (password.length < 8) {
      throw const FormatException('Password cadangan minimal 8 karakter.');
    }
    final salt = _randomBytes(16);
    final key = await _deriveKey(password, salt, iterations);
    final box = await _cipher.encrypt(utf8.encode(clearText), secretKey: key);
    return {
      'format': format,
      'version': 1,
      'algorithm': 'AES-256-GCM',
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'mac': base64Encode(box.mac.bytes),
      'ciphertext': base64Encode(box.cipherText),
    };
  }

  Future<String> decrypt(Map<String, Object?> envelope, String password) async {
    if (!isEncrypted(envelope)) {
      throw const FormatException('Format cadangan terenkripsi tidak dikenal.');
    }
    try {
      final rounds = envelope['iterations'] as int;
      if (rounds < 10000 || rounds > 2000000) {
        throw const FormatException('Parameter keamanan cadangan tidak valid.');
      }
      final salt = base64Decode(envelope['salt']! as String);
      final key = await _deriveKey(password, salt, rounds);
      final box = SecretBox(
        base64Decode(envelope['ciphertext']! as String),
        nonce: base64Decode(envelope['nonce']! as String),
        mac: Mac(base64Decode(envelope['mac']! as String)),
      );
      final clearBytes = await _cipher.decrypt(box, secretKey: key);
      return utf8.decode(clearBytes);
    } on SecretBoxAuthenticationError {
      throw const FormatException('Password salah atau cadangan telah rusak.');
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Cadangan terenkripsi tidak valid.');
    }
  }

  Future<SecretKey> _deriveKey(String password, List<int> salt, int rounds) =>
      Pbkdf2.hmacSha256(
        iterations: rounds,
        bits: 256,
      ).deriveKeyFromPassword(password: password, nonce: salt);

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
