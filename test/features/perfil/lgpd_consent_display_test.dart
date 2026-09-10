import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/legal/focux_legal.dart';
import 'package:focux_app/features/perfil/data/lgpd_consent_repository.dart';
import 'package:focux_app/features/perfil/utils/lgpd_consent_display.dart';

void main() {
  test('lgpd consent status line cobre vazio e preenchido', () {
    expect(
      lgpdConsentStatusLine(null),
      contains(FocuxLegal.consentDocumentVersion),
    );
    expect(
      lgpdConsentStatusLine(
        const LgpdConsent(
          tipo: 'PRIVACIDADE',
          versao: '2026-09',
          aceitoEm: '2026-09-10T12:00:00',
        ),
      ),
      'Política de privacidade · v2026-09 · 2026-09-10T12:00:00',
    );
  });

  test('tipos personal são termos + privacidade', () {
    expect(lgpdConsentTiposPersonal, ['TERMOS', 'PRIVACIDADE']);
  });

  test('tipos aluno incluem saúde', () {
    expect(lgpdConsentTiposAluno, ['TERMOS', 'PRIVACIDADE', 'SAUDE']);
  });
}
