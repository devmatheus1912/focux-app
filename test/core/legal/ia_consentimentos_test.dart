import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/legal/ia_consentimentos.dart';
import 'package:focux_app/features/perfil/data/lgpd_consent_repository.dart';

LgpdConsent _c(String tipo, String em) =>
    LgpdConsent(tipo: tipo, versao: '2026-11', aceitoEm: em);

void main() {
  test('vale o mais recente entre aceite e revogação', () {
    expect(iaAceiteVigente({}, 'IA_COPILOTO'), isFalse);
    expect(
      iaAceiteVigente({'IA_COPILOTO': _c('IA_COPILOTO', '2026-11-09T10:00')}, 'IA_COPILOTO'),
      isTrue,
    );
    expect(
      iaAceiteVigente({
        'IA_COPILOTO': _c('IA_COPILOTO', '2026-11-09T10:00'),
        'IA_COPILOTO_REVOGADO': _c('IA_COPILOTO_REVOGADO', '2026-11-09T11:00'),
      }, 'IA_COPILOTO'),
      isFalse,
    );
    expect(
      iaAceiteVigente({
        'IA_COPILOTO': _c('IA_COPILOTO', '2026-11-09T12:00'),
        'IA_COPILOTO_REVOGADO': _c('IA_COPILOTO_REVOGADO', '2026-11-09T11:00'),
      }, 'IA_COPILOTO'),
      isTrue,
    );
  });

  test('recusar também conta como resposta: não pergunta de novo', () {
    expect(
      iaJaRespondeu({
        'SAUDE_IA_REVOGADO': _c('SAUDE_IA_REVOGADO', '2026-11-09T11:00'),
      }, 'SAUDE_IA'),
      isTrue,
    );
    expect(iaJaRespondeu({}, 'SAUDE_IA'), isFalse);
  });

  test('o texto do personal nomeia os provedores e diz que vai sem nome', () {
    expect(IaConsentimentos.textoPersonal, contains('Google Gemini ou Groq'));
    expect(IaConsentimentos.textoPersonal, contains('sem o nome'));
    expect(IaConsentimentos.textoSaude, contains('sem os valores'));
  });
}
