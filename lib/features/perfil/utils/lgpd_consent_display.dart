import '../data/lgpd_consent_repository.dart';

String lgpdConsentTipoLabel(String tipo) => switch (tipo.toUpperCase()) {
  'TERMOS' => 'Termos de uso',
  'PRIVACIDADE' => 'Política de privacidade',
  'SAUDE' => 'Dados de saúde',
  'IA_TERCEIROS' => 'Copiloto de IA',
  'IA_COPILOTO' => 'Meus treinos no assistente de IA',
  'SAUDE_IA' => 'Saúde no assistente de IA',
  _ => tipo,
};

/// Aceites de IA: permitir e revogar a qualquer momento (registro novo).
bool lgpdConsentEhIa(String tipo) =>
    const ['IA_TERCEIROS', 'IA_COPILOTO', 'SAUDE_IA'].contains(tipo.toUpperCase());

enum LgpdConsentEstado { aceito, versaoAntiga, pendente }

LgpdConsentEstado lgpdConsentEstado(LgpdConsent? consent, String versaoAtual) {
  if (consent == null) return LgpdConsentEstado.pendente;
  return consent.versao == versaoAtual
      ? LgpdConsentEstado.aceito
      : LgpdConsentEstado.versaoAntiga;
}

String lgpdConsentResumo(int aceitos, int total) {
  final faltam = total - aceitos;
  if (faltam <= 0) return 'Tudo aceito';
  return faltam == 1 ? 'Falta aceitar 1 documento' : 'Faltam $faltam documentos';
}

String lgpdConsentAceitoLabel(LgpdConsent consent) {
  final data = DateTime.tryParse(consent.aceitoEm.trim());
  if (data == null) return 'Aceito';
  String dd(int n) => n.toString().padLeft(2, '0');
  return 'Aceito em ${dd(data.day)}/${dd(data.month)}/${data.year}';
}

const lgpdConsentTiposPersonal = ['TERMOS', 'PRIVACIDADE', 'IA_TERCEIROS'];

/// Aluno também aceita tratamento de dados de saúde (anamnese/hábitos) e
/// decide o que o assistente de IA do personal pode usar.
const lgpdConsentTiposAluno = [
  'TERMOS',
  'PRIVACIDADE',
  'SAUDE',
  'IA_COPILOTO',
  'SAUDE_IA',
];
