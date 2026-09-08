String habitoTemplateLabel({
  required String titulo,
  String? icone,
}) {
  final nome = titulo.trim();
  final glyph = icone?.trim();
  if (glyph != null && glyph.isNotEmpty) {
    return nome.isEmpty ? glyph : '$glyph $nome';
  }
  return nome.isEmpty ? 'Template' : nome;
}

String habitoTemplateValue(String? titulo, {String? icone}) {
  if (titulo == null || titulo.trim().isEmpty) return 'Personalizado';
  return habitoTemplateLabel(titulo: titulo, icone: icone);
}

String habitoAlcanceLabel(int? alunoId) =>
    alunoId == null ? habitoAlunoTodosLabel : 'Aluno específico';

String habitoSubtitle({
  String? descricao,
  required int metaSemanal,
  int? alunoId,
}) {
  final alcance = habitoAlcanceLabel(alunoId);
  final desc = descricao?.trim();
  if (desc != null && desc.isNotEmpty) return '$desc · $alcance';
  return 'Meta semanal: ${metaSemanal}x · $alcance';
}

String habitoMetaValue(int metaSemanal) => '${metaSemanal}x';

String habitoComplianceLabel(String? alunoNome) {
  final nome = alunoNome?.trim();
  if (nome == null || nome.isEmpty) return 'Aluno';
  return nome;
}

String habitoComplianceValue(int pct) => '$pct%';

String habitoComplianceSubtitle(int checksSemana) {
  if (checksSemana == 1) return '1 check na semana';
  return '$checksSemana checks na semana';
}

String habitoComplianceFxIcon(int pct) {
  if (pct >= 70) return 'circle-check';
  if (pct >= 40) return 'trend';
  return 'alert-triangle';
}

bool habitoComplianceDanger(int pct) => pct < 40;

const habitoComoCalculamos =
    'Compliance é checks da semana sobre a meta. Vale para todos os alunos ativos.';

String habitoCountLabel(int count) {
  if (count <= 0) return 'Nenhum hábito';
  if (count == 1) return '1 hábito';
  return '$count hábitos';
}

String habitoHubSubtitle(String? freshness) {
  const base = 'Coaching diário e aderência';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String habitoComplianceEmptyTitle(String query) =>
    query.trim().isEmpty ? 'Sem dados ainda' : 'Nenhum aluno encontrado';

String habitoComplianceEmptySubtitle(String query) => query.trim().isEmpty
    ? 'Cadastre hábitos e os alunos vão começar a marcar.'
    : 'Nada com esse nome na compliance da semana.';

const habitoAlunoTodosId = 0;
const habitoAlunoTodosLabel = 'Todos os alunos';

String habitoDetalheMessage({
  String? descricao,
  required int metaSemanal,
}) {
  final desc = descricao?.trim();
  final meta = 'Meta semanal: ${metaSemanal}x. Os alunos marcam no app deles.';
  if (desc == null || desc.isEmpty) return meta;
  return '$desc\n\n$meta';
}

String habitoDetailPath(int id) => '/habitos/$id';

String habitoAlunoDetailPath(int id) => '/aluno/habitos/$id';

const habitoDetalheSecaoResumo = 'resumo';
const habitoDetalheSecaoSobre = 'sobre';

const habitoDetalheSecoes = [
  (value: habitoDetalheSecaoResumo, label: 'Resumo'),
  (value: habitoDetalheSecaoSobre, label: 'Sobre'),
];

String habitoStreakValue(int streak) => '$streak';

String habitoStreakHint(int streak) {
  if (streak <= 0) return 'Sem sequência';
  if (streak == 1) return '1 dia seguido';
  return '$streak dias seguidos';
}

String habitoFeitosValue(int feitos, int meta) => '$feitos/$meta';

String habitoFeitosHint({required int feitos, required int meta}) {
  if (meta <= 0) return 'Sem meta semanal';
  if (feitos >= meta) return 'Meta da semana ok';
  return 'Feitos na semana';
}

String habitoDetailSubtitle({
  required int metaSemanal,
  int? alunoId,
  bool ativo = true,
  String? freshness,
}) {
  final parts = <String>[
    if (!ativo) 'Desativado',
    'Meta ${habitoMetaValue(metaSemanal)}',
    habitoAlcanceLabel(alunoId),
  ];
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

String habitoStickyPersonal() => 'Desativar hábito';

String habitoStickyAluno(bool feitoHoje) =>
    feitoHoje ? 'Desmarcar hoje' : 'Marcar hoje';

String habitoSobreEmpty() => 'Sem descrição neste hábito.';

String habitoDesativadoChip() => 'Desativado';
