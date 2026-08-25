import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/security/focux_security.dart';

void main() {
  test('android hardening artifacts exist', () {
    for (final path in FocuxSecurity.androidHardeningSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Artefato ausente: $path');
    }
  });

  test('AndroidManifest keeps MobSF baseline invariants', () {
    final manifest = File(FocuxSecurity.androidHardeningSources.first)
        .readAsStringSync();
    for (final invariant in FocuxSecurity.androidManifestInvariants) {
      expect(
        manifest,
        contains(invariant),
        reason: 'Manifest regrediu: falta $invariant',
      );
    }
    expect(
      manifest,
      isNot(contains('android:host="focux.app"')),
      reason: 'App Links não devem usar domínio legado focux.app',
    );
  });

  test('network_security_config blocks cleartext', () {
    final config =
        File('android/app/src/main/res/xml/network_security_config.xml')
            .readAsStringSync();
    for (final invariant in FocuxSecurity.networkSecurityInvariants) {
      expect(
        config,
        contains(invariant),
        reason: 'network_security_config regrediu: falta $invariant',
      );
    }
  });

  group('monorepo hardening (skip if checkout isolado)', () {
    for (final path in FocuxSecurity.monorepoHardeningSources) {
      test(path, () {
        final file = File(path);
        if (!file.existsSync()) {
          return;
        }

        final content = file.readAsStringSync();

        if (path.endsWith('vercel.json')) {
          for (final invariant in FocuxSecurity.vercelHeaderInvariants) {
            expect(
              content,
              contains(invariant),
              reason: 'vercel.json regrediu: falta $invariant',
            );
          }
          expect(
            content,
            isNot(contains('"value": "*"')),
            reason: 'ACAO não deve ser wildcard',
          );
        }

        if (path.endsWith('assetlinks.json')) {
          for (final invariant in FocuxSecurity.assetLinksInvariants) {
            expect(
              content,
              contains(invariant),
              reason: 'assetlinks.json regrediu: falta $invariant',
            );
          }
        }

        if (path.endsWith('PERFIL_DESIGN_REFERENCE.md')) {
          expect(content, contains('FocuxSecurity'));
          expect(content, contains('Hardening mobile & web'));
        }
      });
    }
  });
}
