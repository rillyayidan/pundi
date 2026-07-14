import 'package:flutter_test/flutter_test.dart';
import 'package:pundi/services/security_service.dart';

void main() {
  test('authentication is remembered for the same device boot', () {
    expect(
      SecurityService.requiresAuthentication(
        lockEnabled: true,
        authenticatedSession: 'boot-42',
        currentSession: 'boot-42',
      ),
      isFalse,
    );
    expect(
      SecurityService.requiresAuthentication(
        lockEnabled: true,
        authenticatedSession: 'boot-42',
        currentSession: 'boot-43',
      ),
      isTrue,
    );
  });

  test('disabled lock never requests authentication', () {
    expect(
      SecurityService.requiresAuthentication(
        lockEnabled: false,
        authenticatedSession: null,
        currentSession: null,
      ),
      isFalse,
    );
  });
}
