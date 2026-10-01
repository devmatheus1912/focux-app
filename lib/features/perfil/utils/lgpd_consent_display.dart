import '../data/lgpd_consent_repository.dart';

String lgpdConsentTipoLabel(String tipo) => switch (tipo.toUpperCase()) {
  'TERMOS' => 'Termos de uso',
  'PRIVACIDADE' => 'Política de privacidade',
  'SAUDE' => 'Dados de saúde',
  _ => tipo,
};

enum LgpdConsentEstado { aceito, versaoAntiga, pendente }

LgpdConsentEstado lgpdConsentEstado(LgpdConsent? consent, String versaoAtual) {
  if (consent == null) return LgpdConsentEstado.pendente;
  return consent.versao == versaoAtual
      ? LgpdConsentEstado.aceito
      : LgpdConsentEstado.versaoAntiga;
}

String lgpdConsentResumo(int aceitos, int total) =>
    '$aceitos de $total ${total == 1 ? 'aceito' : 'aceitos'}';

String lgpdConsentAceitoLabel(LgpdConsent consent) {
  final data = DateTime.tryParse(consent.aceitoEm.trim());
  if (data == null) return 'Aceito · v${consent.versao}';
  String dd(int n) => n.toString().padLeft(2, '0');
  return 'Aceito em ${dd(data.day)}/${dd(data.month)}/${data.year} '
      '· v${consent.versao}';
}

const lgpdConsentTiposPersonal = ['TERMOS', 'PRIVACIDADE'];

/// Aluno também aceita tratamento de dados de saúde (anamnese/hábitos).
const lgpdConsentTiposAluno = ['TERMOS', 'PRIVACIDADE', 'SAUDE'];
