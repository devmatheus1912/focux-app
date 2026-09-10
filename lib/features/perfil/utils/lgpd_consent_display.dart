import '../../../core/legal/focux_legal.dart';
import '../data/lgpd_consent_repository.dart';

String lgpdConsentTipoLabel(String tipo) => switch (tipo.toUpperCase()) {
  'TERMOS' => 'Termos de uso',
  'PRIVACIDADE' => 'Política de privacidade',
  'SAUDE' => 'Dados de saúde',
  _ => tipo,
};

String lgpdConsentStatusLine(LgpdConsent? consent) {
  if (consent == null) {
    return 'Nenhum registro ainda · docs ${FocuxLegal.consentDocumentVersion}';
  }
  final tipo = lgpdConsentTipoLabel(consent.tipo);
  final quando = consent.aceitoEm.trim();
  if (quando.isEmpty) {
    return '$tipo · v${consent.versao}';
  }
  return '$tipo · v${consent.versao} · $quando';
}

const lgpdConsentTiposPersonal = ['TERMOS', 'PRIVACIDADE'];

/// Aluno também aceita tratamento de dados de saúde (anamnese/hábitos).
const lgpdConsentTiposAluno = ['TERMOS', 'PRIVACIDADE', 'SAUDE'];
