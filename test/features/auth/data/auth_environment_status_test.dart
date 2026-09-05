import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/data/auth_repository.dart';

void main() {
  test('AuthEnvironmentStatus parses operational issues and actions', () {
    final status = AuthEnvironmentStatus.fromJson({
      'status': 'ACTION_REQUIRED',
      'productionReady': false,
      'passwordResetReady': false,
      'googleSignInReady': false,
      'googleSignInEnabled': false,
      'googleClientIdsConfigured': false,
      'missing': ['SMTP_HOST'],
      'issues': [
        {
          'area': 'password_reset',
          'severity': 'BLOCKER',
          'title': 'Host SMTP ausente',
          'detail': 'Sem SMTP_HOST o email nao sai.',
          'action': 'Configurar SMTP_HOST.',
        }
      ],
      'nextActions': ['Configurar SMTP_HOST.'],
    });

    // Campos mortos (status/productionReady/missing/severity) são ignorados no parse.
    expect(status.passwordResetReady, isFalse);
    expect(status.googleSignInReady, isFalse);
    expect(status.firstIssueFor('password_reset')?.title, 'Host SMTP ausente');
    expect(status.nextActions.single, 'Configurar SMTP_HOST.');
  });
}
