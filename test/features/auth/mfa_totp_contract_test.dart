import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/post_login_redirect.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  group('MFA TOTP Personal — contrato API', () {
    test('capabilities, status, setup e AuthLoginResult no repositório', () {
      final repo = readScreenSourceBundle(
        'lib/features/auth/data/auth_repository.dart',
      );
      expect(repo, contains('personalMfaTotpAvailable'));
      expect(repo, contains("json['personalMfaTotpAvailable']"));
      expect(repo, contains("json['enabled']"));
      expect(repo, contains("json['recoveryCodesRemaining']"));
      expect(repo, contains("json['secret']"));
      expect(repo, contains("json['otpauthUri']"));
      expect(repo, contains("json['recoveryCodes']"));
      expect(repo, contains("'/api/auth/mfa/verify'"));
      expect(repo, contains("'/api/auth/mfa/status'"));
      expect(repo, contains("'/api/auth/mfa/setup'"));
      expect(repo, contains("'/api/auth/mfa/confirm'"));
      expect(repo, contains("'/api/auth/mfa/disable'"));
      expect(repo, contains('mfaRequired'));
      expect(repo, contains('mfaToken'));
      expect(repo, contains('AuthLoginResult.mfaRequired'));
      expect(
        repo,
        contains('// token/refreshToken vêm null — não persiste sessão.'),
      );
    });

    test('login/register abrem /login/mfa; mfaToken só em memória', () {
      final login = readScreenSourceBundle(
        'lib/features/auth/screens/login_screen_actions.part.dart',
      );
      expect(login, contains('_maybeOpenMfa'));
      expect(login, contains("context.go('/login/mfa')"));
      expect(login, contains('mfaChallengeProvider'));
      expect(login, isNot(contains('SecureStorage.save')));

      final register = readScreenSourceBundle(
        'lib/features/auth/screens/register_screen_actions.part.dart',
      );
      expect(register, contains('_maybeOpenMfa'));
      expect(register, contains("context.go('/login/mfa')"));

      final provider = readScreenSourceBundle(
        'lib/features/auth/providers/auth_provider.dart',
      );
      expect(
        provider,
        contains(
          '/// MFA token do challenge de login — só em memória (nunca SecureStorage).',
        ),
      );
      expect(provider, contains('mfaChallengeProvider'));
    });

    test('telas verify/setup e rotas', () {
      final verify = readScreenSourceBundle(
        'lib/features/auth/screens/mfa_verify_screen.dart',
      );
      expect(verify, contains('Usar código de recuperação'));
      expect(verify, contains('verifyMfa'));
      expect(verify, contains("context.go('/login')"));

      final setup = readScreenSourceBundle(
        'lib/features/auth/screens/mfa_setup_screen.dart',
      );
      expect(setup, contains('otpauthUri'));
      expect(
        setup,
        contains('Guardei os códigos de recuperação em local seguro'),
      );
      expect(setup, contains('mfaDisable'));
      expect(setup, contains('QrImageView'));

      final authRoutes = readScreenSourceBundle(
        'lib/core/router/app_router_auth_routes.dart',
      );
      expect(authRoutes, contains("path: '/login/mfa'"));

      final chrome = readScreenSourceBundle(
        'lib/core/router/app_router_chrome_routes.dart',
      );
      expect(chrome, contains("path: '/perfil/mfa'"));

      final redirect = readScreenSourceBundle(
        'lib/core/router/app_router_redirect.dart',
      );
      expect(redirect, contains("path == '/login/mfa'"));
      expect(redirect, contains("'/perfil/mfa'"));
    });

    test('perfil: tile MFA gated por capability', () {
      final perfil = readScreenSourceBundle(
        'lib/features/perfil/screens/perfil_screen.dart',
      );
      expect(perfil, contains('personalMfaTotpAvailable'));
      expect(perfil, contains('_mfaAvailable'));
      expect(perfil, contains('showMfa: _mfaAvailable'));

      final section = readScreenSourceBundle(
        'lib/features/perfil/widgets/perfil_conta_seguranca_section.dart',
      );
      expect(section, contains('showMfa'));
      expect(section, contains('Autenticação em duas etapas'));
    });

    test('safePostLoginPath: /login/mfa público; /perfil/mfa personal', () {
      expect(isPublicAuthPath('/login/mfa'), isTrue);
      expect(isPersonalPath('/perfil/mfa'), isTrue);
      expect(safePostLoginPath('/login/mfa', isAluno: false), isNull);
      expect(safePostLoginPath('/perfil/mfa', isAluno: false), '/perfil/mfa');
    });
  });
}
