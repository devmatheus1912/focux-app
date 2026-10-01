import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/data/lgpd_consent_repository.dart';
import 'package:focux_app/features/perfil/utils/lgpd_consent_display.dart';

void main() {
  const atual = '2026-09';

  LgpdConsent c(String versao, {String em = '2026-09-10T14:30:00'}) =>
      LgpdConsent(tipo: 'TERMOS', versao: versao, aceitoEm: em);

  test('estado do aceite compara com a versão atual', () {
    expect(lgpdConsentEstado(null, atual), LgpdConsentEstado.pendente);
    expect(lgpdConsentEstado(c('2026-08'), atual), LgpdConsentEstado.versaoAntiga);
    expect(lgpdConsentEstado(c(atual), atual), LgpdConsentEstado.aceito);
  });

  test('resumo e rótulo de aceite', () {
    expect(lgpdConsentResumo(2, 3), '2 de 3 aceitos');
    expect(lgpdConsentResumo(1, 1), '1 de 1 aceito');
    expect(lgpdConsentAceitoLabel(c(atual)), 'Aceito em 10/09/2026 · v2026-09');
    expect(lgpdConsentAceitoLabel(c(atual, em: '')), 'Aceito · v2026-09');
  });

  test('tipos por perfil', () {
    expect(lgpdConsentTiposPersonal, ['TERMOS', 'PRIVACIDADE']);
    expect(lgpdConsentTiposAluno, ['TERMOS', 'PRIVACIDADE', 'SAUDE']);
  });
}
