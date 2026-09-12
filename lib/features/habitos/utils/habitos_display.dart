import '../data/habito_repository.dart';

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

/// Prioriza quem está em risco; senão o primeiro da lista.
ComplianceItem? habitoFocusCompliance(List<ComplianceItem> items) {
  if (items.isEmpty) return null;
  ComplianceItem? worst;
  for (final item in items) {
    if (worst == null || item.compliancePct < worst.compliancePct) {
      worst = item;
    }
  }
  return worst;
}

const habitoComoCalculamos =
    'Compliance é checks da semana sobre a meta. Vale para todos os alunos ativos.';

String habitoAlunoSubtitle({
  String? descricao,
  required int feitosNaSemana,
  required int metaSemanal,
}) {
  final desc = descricao?.trim();
  final meta = '$feitosNaSemana/$metaSemanal na semana';
  if (desc != null && desc.isNotEmpty) return '$desc · $meta';
  return meta;
}

bool habitoMatchesQuery({
  required String titulo,
  String? descricao,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final hay = '${titulo.toLowerCase()} ${(descricao ?? '').toLowerCase()}';
  return hay.contains(q);
}

String habitoCountLabel(int count) {
  if (count <= 0) return 'Nenhum hábito';
  if (count == 1) return '1 hábito';
  return '$count hábitos';
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
}) {
  return [
    if (!ativo) 'Desativado',
    'Meta ${habitoMetaValue(metaSemanal)}',
    habitoAlcanceLabel(alunoId),
  ].join(' · ');
}

String habitoStickyPersonal() => 'Desativar hábito';

String habitoStickyAluno(bool feitoHoje) =>
    feitoHoje ? 'Desmarcar hoje' : 'Marcar hoje';

String habitoResumoLine({
  required int streak,
  required int feitos,
  required int meta,
}) {
  return 'Sequência $streak · $feitos de $meta na semana.';
}

String habitoSobreEmpty() => 'Sem descrição neste hábito.';

String habitoDesativadoChip() => 'Desativado';

String habitoLembreteLine(String? hora) {
  final value = hora?.trim();
  if (value == null || value.isEmpty) return 'Sem horário de lembrete';
  return 'Lembrete às $value';
}

String habitoCheckDiaLabel(DateTime data) {
  final day = data.day.toString().padLeft(2, '0');
  final month = data.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String habitoChecksLine(List<HabitoCheckDia>? checks) {
  if (checks == null) return '';
  final feitos = checks.where((c) => c.feito).toList();
  if (feitos.isEmpty) return 'Nenhum check ainda';
  final recent = feitos.take(7).map((c) => habitoCheckDiaLabel(c.data)).join(', ');
  return 'Feitos: $recent';
}

List<HabitoCheckDia>? habitoPatchCheckHoje(
  List<HabitoCheckDia>? checks,
  bool feito, {
  DateTime? now,
}) {
  if (checks == null) return null;
  final today = now ?? DateTime.now();
  final key = DateTime(today.year, today.month, today.day);
  final rest = checks.where((c) {
    final day = DateTime(c.data.year, c.data.month, c.data.day);
    return day != key;
  }).toList();
  return [HabitoCheckDia(data: key, feito: feito), ...rest];
}
