import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/security/focux_security.dart';

void main() {
  test('FocuxSecurity catalog lists core security sources', () {
    expect(FocuxSecurity.version, isNotEmpty);
    expect(FocuxSecurity.coreSources, isNotEmpty);
    expect(FocuxSecurity.hubSecurityPatterns, isNotEmpty);
  });

  test('security sources and TLS pinning exist', () {
    for (final path in FocuxSecurity.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }

    final api = File('lib/core/api/api_client.dart').readAsStringSync();
    expect(api, contains('SecureStorage.getToken'));
    expect(api, contains('TlsCertificatePinning.apply'));

    final storage = File('lib/core/storage/secure_storage.dart').readAsStringSync();
    expect(storage, contains('FlutterSecureStorage'));
  });

  test('device guard blocks jailbreak for payments', () {
    final guard =
        File('lib/features/assinatura/services/subscription_device_guard.dart')
            .readAsStringSync();
    expect(guard, contains('FlutterJailbreakDetection'));
  });

  test('CI security workflows are registered', () {
    for (final path in [
      '.github/workflows/security.yml',
      '.github/workflows/semgrep.yml',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: 'Workflow ausente: $path');
    }
  });
}
