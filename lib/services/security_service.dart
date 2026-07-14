import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  SecurityService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;
  static const _platform = MethodChannel('pundi/security');

  Future<String?> bootSessionId() async {
    try {
      return await _platform.invokeMethod<String>('getBootSessionId');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  static bool requiresAuthentication({
    required bool lockEnabled,
    required String? authenticatedSession,
    required String? currentSession,
  }) {
    if (!lockEnabled) return false;
    if (currentSession == null) return true;
    return authenticatedSession != currentSession;
  }

  Future<bool> isSupported() async {
    try {
      return await _authentication.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _authentication.authenticate(
        localizedReason: 'Verifikasi sekali untuk sesi perangkat ini',
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException {
      return false;
    }
  }
}
