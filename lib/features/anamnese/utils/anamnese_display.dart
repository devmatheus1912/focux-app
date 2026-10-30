import '../data/anamnese_repository.dart';
import '../../../core/utils/pt_br_display.dart';

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

/// Espelha `@Size` de `AnamneseRequest` no backend.
abstract final class AnamneseFieldLimits {
  static const objetivo = 4000;
  static const nivelAtividade = 50;
  static const lesoes = 4000;
  static const medicamentos = 4000;
  static const observacoes = 4000;
  static const historicoMedico = 4000;
  static const cirurgias = 4000;
  static const doresCronicas = 4000;
  static const objetivoDetalhado = 4000;
  static const preferenciasTreino = 4000;
  static const restricoesAlimentares = 4000;
  static const parqOutraRazaoDetalhe = 2000;
  static const sintomasCv = 4000;
  static const alergias = 2000;
  static const gestacaoPosParto = 1000;
  static const qualidadeSono = 30;
  static const nivelEstresse = 20;
  static const tabagismo = 40;
  static const alcool = 40;
  static const historicoAtividade = 4000;
  static const motivoInterrupcoes = 4000;
  static const motivacaoAtual = 2000;
  static const algoMais = 4000;
}

String anamneseClipField(String value, int max) {
  final t = value.trim();
  if (t.length <= max) return t;
  return t.substring(0, max);
}

String anamneseSecaoTitle(String secao) => switch (secao) {
  anamneseSecaoSaude => 'Saúde',
  anamneseSecaoHabitos => 'Hábitos',
  anamneseSecaoTreino => 'Treino e objetivos',
  _ => 'PAR-Q+',
};

String anamneseSonoHorasLabel(num? horas) {
  if (horas == null) return '—';
  final value = horas.toDouble();
  if (value <= 1) return '1 hora';
  if (value == value.roundToDouble()) return '${value.round()} horas';
  return '${formatBrDecimal(value)} horas';
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

/// O que o personal precisa ver antes de liberar o treino.
List<String> anamnesePontosDeAtencao(Anamnese a) => [
  if (a.parqPositivo == true) 'Respondeu sim em alguma pergunta do PAR-Q+',
  ...a.alertas,
  if (a.tabagismo == 'Fumo') 'Fuma',
];

String anamneseDecisaoTitulo(Anamnese a) {
  if (a.isRevisada) return 'Revisada';
  if (a.isPrecisaAtestado) return 'Aguardando atestado';
  if (a.isPreenchida) {
    final n = anamnesePontosDeAtencao(a).length;
    if (n == 0) return 'Revisar · sem pontos de atenção';
    return n == 1 ? 'Revisar · 1 ponto de atenção' : 'Revisar · $n pontos de atenção';
  }
  return anamneseStatusLabel(a.status);
}

String anamneseDecisaoApoio(Anamnese a) {
  if (a.isRevisada) {
    final data = DateTime.tryParse(a.revisadaEm ?? '');
    if (data == null) return anamneseStatusSubtitle(a.status);
    String dd(int n) => n.toString().padLeft(2, '0');
    return 'Revisada em ${dd(data.day)}/${dd(data.month)}/${data.year}';
  }
  return anamneseStatusSubtitle(a.status);
}

String anamneseTreinoLinha(Anamnese a) => [
  if ((a.objetivo ?? '').trim().isNotEmpty) a.objetivo!.trim(),
  if (a.disponibilidadeSemanal != null)
    anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!),
].join(' · ');

/// Só o que o aluno respondeu: campo vazio não vira linha com traço.
List<(String, String)> anamneseRespostas(Anamnese a, String secao) {
  final linhas = switch (secao) {
    anamneseSecaoSaude => [
      ('Histórico médico', a.historicoMedico),
      ('Cirurgias', a.cirurgias),
      ('Dores crônicas', a.doresCronicas),
      ('Lesões / limitações', a.lesoes),
      ('Medicamentos', a.medicamentos),
      ('Alergias', a.alergias),
      ('Gestação / pós-parto', a.gestacaoPosParto),
      (
        'Histórico familiar CV',
        a.historicoFamiliarCv == null
            ? null
            : anamneseBoolLabel(a.historicoFamiliarCv),
      ),
      ('Sintomas CV', a.sintomasCv),
    ],
    anamneseSecaoHabitos => [
      ('Sono', a.sonoHoras == null ? null : anamneseSonoHorasLabel(a.sonoHoras)),
      ('Qualidade do sono', a.qualidadeSono),
      ('Nível de estresse', a.nivelEstresse),
      ('Tabagismo', a.tabagismo),
      ('Álcool', a.alcool),
      ('Observações', a.observacoes),
    ],
    anamneseSecaoTreino => [
      ('Objetivo', a.objetivo),
      ('Objetivo detalhado', a.objetivoDetalhado),
      (
        'Disponibilidade',
        a.disponibilidadeSemanal == null
            ? null
            : anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!),
      ),
      ('Preferências de treino', a.preferenciasTreino),
      ('Restrições alimentares', a.restricoesAlimentares),
      ('Histórico de atividade', a.historicoAtividade),
      ('Motivo de interrupções', a.motivoInterrupcoes),
      ('Motivação atual', a.motivacaoAtual),
      ('Algo mais', a.algoMais),
    ],
    _ => [
      for (final q in anamneseParqPerguntas)
        if (anamneseParqValue(a, q.key) != null)
          (q.label, anamneseBoolLabel(anamneseParqValue(a, q.key))),
      ('Detalhe (outra razão)', a.parqOutraRazaoDetalhe),
    ],
  };
  return [
    for (final (rotulo, valor) in linhas)
      if ((valor ?? '').trim().isNotEmpty) (rotulo, valor!.trim()),
  ];
}

/// Campos do personal, fora das respostas do aluno.
List<(String, String)> anamneseNotasDoPersonal(Anamnese a) => [
  if ((a.notasProfissional ?? '').trim().isNotEmpty)
    ('Notas', a.notasProfissional!.trim()),
  if ((a.atestadoObs ?? '').trim().isNotEmpty)
    ('Atestado', a.atestadoObs!.trim()),
];
