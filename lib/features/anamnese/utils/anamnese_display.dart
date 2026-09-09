import '../data/anamnese_repository.dart';

const anamneseNiveis = [
  'SEDENTARIO',
  'LEVE',
  'MODERADO',
  'INTENSO',
  'MUITO_INTENSO',
];

String anamneseNivelLabel(String? code) {
  switch (code) {
    case 'SEDENTARIO':
      return 'Sedentário';
    case 'LEVE':
      return 'Leve';
    case 'MODERADO':
      return 'Moderado';
    case 'INTENSO':
      return 'Intenso';
    case 'MUITO_INTENSO':
      return 'Muito intenso';
    default:
      return 'Selecionar';
  }
}

String? anamneseNivelOuNulo(String? code) {
  if (code == null) return null;
  return anamneseNiveis.contains(code) ? code : null;
}

String anamneseDisponibilidadeLabel(int dias) {
  if (dias <= 1) return '1 dia por semana';
  return '$dias dias por semana';
}

int anamneseDisponibilidadeClamp(int? dias) {
  final n = dias ?? 3;
  if (n < 1) return 1;
  if (n > 7) return 7;
  return n;
}

String anamneseStatusLabel(String? status) {
  switch (status) {
    case AnamneseStatus.naoIniciada:
      return 'Não iniciada';
    case AnamneseStatus.solicitada:
      return 'Solicitada';
    case AnamneseStatus.preenchida:
      return 'Preenchida';
    case AnamneseStatus.revisada:
      return 'Revisada';
    case AnamneseStatus.precisaAtestado:
      return 'Precisa atestado';
    default:
      return 'Não iniciada';
  }
}

String anamneseStatusSubtitle(String? status) {
  switch (status) {
    case AnamneseStatus.solicitada:
      return 'Aguardando o aluno preencher a ficha.';
    case AnamneseStatus.preenchida:
      return 'Aluno enviou. Revise e registre a decisão.';
    case AnamneseStatus.revisada:
      return 'Ficha revisada. Peça atualização se algo mudar.';
    case AnamneseStatus.precisaAtestado:
      return 'Libere o treino só com atestado médico.';
    case AnamneseStatus.naoIniciada:
    default:
      return 'Solicite a anamnese para o aluno preencher.';
  }
}

String anamneseBoolLabel(bool? value) {
  if (value == null) return '—';
  return value ? 'Sim' : 'Não';
}

String anamneseTextOrDash(String? value) {
  final t = value?.trim() ?? '';
  return t.isEmpty ? '—' : t;
}

const anamneseSecaoParq = 'parq';
const anamneseSecaoSaude = 'saude';
const anamneseSecaoHabitos = 'habitos';
const anamneseSecaoTreino = 'treino';

const anamneseDetalheSecoes = [
  (value: anamneseSecaoParq, label: 'PAR-Q+'),
  (value: anamneseSecaoSaude, label: 'Saúde'),
  (value: anamneseSecaoHabitos, label: 'Hábitos'),
  (value: anamneseSecaoTreino, label: 'Treino'),
];

String anamneseParqMetricValue(Anamnese a) {
  if (a.parqPositivo == true) return 'Atenção';
  if (a.parqCompleto == true) return 'Ok';
  return '—';
}

String anamneseParqMetricHint(Anamnese a) {
  if (a.parqPositivo == true) return 'Resposta positiva no questionário';
  if (a.parqCompleto == true) return 'Questionário completo';
  return 'Ainda sem PAR-Q+';
}

String anamneseAlertasMetricValue(Anamnese a) => '${a.alertas.length}';

String anamneseAlertasMetricHint(Anamnese a) {
  if (a.alertas.isEmpty) return 'Nenhum alerta na ficha';
  return 'Pontos de atenção';
}

String anamneseDispMetricValue(Anamnese a) {
  if (a.disponibilidadeSemanal == null) return '—';
  return anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!);
}

String anamneseSonoHorasLabel(int? horas) {
  if (horas == null) return '—';
  if (horas <= 1) return '1 hora';
  return '$horas horas';
}

/// Perguntas PAR-Q+ na ordem da ficha (chave → enunciado curto).
const anamneseParqPerguntas = <({String key, String label})>[
  (
    key: 'parqCondicaoCardiaca',
    label: 'Alguma condição cardíaca diagnosticada?',
  ),
  (
    key: 'parqDorPeitoAtividade',
    label: 'Dor no peito durante atividade física?',
  ),
  (
    key: 'parqDorPeitoRepouso',
    label: 'Dor no peito em repouso no último mês?',
  ),
  (
    key: 'parqTonturaDesmaio',
    label: 'Tontura ou perda de consciência?',
  ),
  (
    key: 'parqProblemaOsseoArticular',
    label: 'Problema ósseo ou articular que limite exercício?',
  ),
  (
    key: 'parqMedicacaoPressaoCoracao',
    label: 'Medicamento para pressão ou coração?',
  ),
  (
    key: 'parqOutraRazao',
    label: 'Outra razão para não fazer atividade física?',
  ),
];

bool? anamneseParqValue(Anamnese a, String key) {
  switch (key) {
    case 'parqCondicaoCardiaca':
      return a.parqCondicaoCardiaca;
    case 'parqDorPeitoAtividade':
      return a.parqDorPeitoAtividade;
    case 'parqDorPeitoRepouso':
      return a.parqDorPeitoRepouso;
    case 'parqTonturaDesmaio':
      return a.parqTonturaDesmaio;
    case 'parqProblemaOsseoArticular':
      return a.parqProblemaOsseoArticular;
    case 'parqMedicacaoPressaoCoracao':
      return a.parqMedicacaoPressaoCoracao;
    case 'parqOutraRazao':
      return a.parqOutraRazao;
    default:
      return null;
  }
}

String anamneseAlunoCtaTitle(Anamnese a) {
  if (a.isPrecisaAtestado) {
    return 'Seu personal pediu atestado';
  }
  if (a.isSolicitada) {
    return 'Anamnese solicitada';
  }
  return 'Anamnese';
}

String anamneseAlunoCtaBody(Anamnese a) {
  if (a.isPrecisaAtestado) {
    return a.atestadoObs?.trim().isNotEmpty == true
        ? a.atestadoObs!.trim()
        : 'Atualize a ficha e anexe/envie o atestado conforme orientado.';
  }
  if (a.isSolicitada) {
    return 'Preencha a ficha de saúde e objetivos para o personal revisar.';
  }
  if (a.isPreenchida) {
    return 'Enviada para revisão do personal.';
  }
  if (a.isRevisada) {
    return 'Revisada pelo personal. Você pode atualizar se algo mudou.';
  }
  return 'Quando o personal solicitar, preencha aqui.';
}
