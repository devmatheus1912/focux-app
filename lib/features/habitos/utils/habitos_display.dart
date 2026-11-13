import '../data/habito_repository.dart';

/// "5 vezes por semana", "1 vez por semana".
String habitoVezesPorSemana(int n) =>
    n == 1 ? '1 vez por semana' : '$n vezes por semana';

String habitoAlcanceLabel(int? alunoId, {String? alunoNome}) {
  if (alunoId == null) return habitoAlunoTodosLabel;
  final nome = alunoNome?.trim();
  return nome == null || nome.isEmpty ? 'Um aluno' : nome;
}

/// A regra numa frase: "5x por semana · Todos os alunos".
String habitoRegra({required int metaSemanal, int? alunoId}) =>
    '${metaSemanal}x por semana · ${habitoAlcanceLabel(alunoId)}';

String habitoComplianceLabel(String? alunoNome) {
  final nome = alunoNome?.trim();
  if (nome == null || nome.isEmpty) return 'Aluno';
  return nome;
}

/// "3 de 7 esta semana".
String habitoSemanaLinha(int feitos, int meta) =>
    '$feitos de $meta esta semana';

double habitoFracao(int feitos, int meta) =>
    meta <= 0 ? 0 : (feitos / meta).clamp(0, 1).toDouble();

/// "Esta semana" da lista: quem está mais longe da meta vem primeiro; quem
/// já bateu fica num grupo fechado. Aluno sem hábito não aparece.
({List<ComplianceItem> pendentes, List<ComplianceItem> bateram})
habitoOrdenarSemana(List<ComplianceItem> items) {
  final comMeta = items.where((c) => c.metaSemana > 0).toList();
  final bateram =
      comMeta.where((c) => c.checksSemana >= c.metaSemana).toList()
        ..sort((a, b) => a.alunoNome.compareTo(b.alunoNome));
  final pendentes =
      comMeta.where((c) => c.checksSemana < c.metaSemana).toList()
        ..sort((a, b) {
          final fa = habitoFracao(a.checksSemana, a.metaSemana);
          final fb = habitoFracao(b.checksSemana, b.metaSemana);
          final c = fa.compareTo(fb);
          return c != 0 ? c : a.alunoNome.compareTo(b.alunoNome);
        });
  return (pendentes: pendentes, bateram: bateram);
}

/// Subtítulo da lista: o que pede ação.
String habitoSubtituloLista({
  required int habitos,
  required int abaixoDaMeta,
  required bool temSemana,
}) {
  if (habitos == 0) return 'Nenhum hábito';
  if (!temSemana) return habitoCountLabel(habitos);
  if (abaixoDaMeta == 0) return 'Todos em dia esta semana';
  if (abaixoDaMeta == 1) return '1 aluno abaixo da meta esta semana';
  return '$abaixoDaMeta alunos abaixo da meta esta semana';
}

String habitoCountLabel(int count) {
  if (count <= 0) return 'Nenhum hábito';
  if (count == 1) return '1 hábito';
  return '$count hábitos';
}

const habitoVazioTexto =
    'Hábitos são o que o aluno faz fora do treino, como dormir bem e beber água. Ele marca no app, e você vê quem está cumprindo.';

const habitoComoCalculamos =
    'A meta da semana é quantas vezes o aluno marca o hábito. Ele marca no app dele; você vê quem está em dia.';

/// Busca de aluno só com mais de 6 na lista.
bool habitoMostraBusca({required int total, required String query}) =>
    total > 6 || query.trim().isNotEmpty;

const habitoAlunoTodosId = 0;
const habitoAlunoTodosLabel = 'Todos os alunos';

/// Na folha de editar: o público não muda depois de criado.
String habitoParaQuemTravado(int? alunoId) =>
    alunoId == null
        ? 'Para todos os alunos. Isso não muda depois de criado.'
        : 'Para um aluno. Isso não muda depois de criado.';

/// Itens do "⋯" do detalhe: Editar e Desativar no ativo; Reativar no desativado.
List<String> habitoMenuAcoes({required bool ativo}) =>
    ativo ? const ['editar', 'desativar'] : const ['reativar'];

String habitoDetailPath(int id) => '/habitos/$id';

String habitoAlunoDetailPath(int id) => '/aluno/habitos/$id';

/// Lista do aluno: "Meta · 3 de 5 esta semana".
/// "1 dia seguido" / "5 dias seguidos"; sem sequência, nada.
String? habitoSequenciaLabel(int dias) {
  if (dias <= 0) return null;
  return dias == 1 ? '1 dia seguido' : '$dias dias seguidos';
}

/// Linha do hábito do aluno: só o progresso e a sequência (a descrição
/// fica no detalhe): "1 de 7 esta semana · 1 dia seguido".
String habitoAlunoSubtitle({
  required int feitosNaSemana,
  required int metaSemanal,
  required int streak,
}) => [
  habitoSemanaLinha(feitosNaSemana, metaSemanal),
  if (habitoSequenciaLabel(streak) case final seq?) seq,
].join(' · ');

/// Linha de hábito desativado: "Desativado · 7x por semana · Todos os alunos".
String habitoDesativadoLinha({required int metaSemanal, int? alunoId}) =>
    'Desativado · ${habitoRegra(metaSemanal: metaSemanal, alunoId: alunoId)}';

String habitoSequenciaLinha(int streak) {
  if (streak <= 0) return '';
  if (streak == 1) return '1 dia seguido';
  return '$streak dias seguidos';
}

String habitoStickyAluno(bool feitoHoje) =>
    feitoHoje ? 'Desmarcar hoje' : 'Marcar hoje';

String habitoLembreteLine(String? hora) {
  final value = hora?.trim();
  if (value == null || value.isEmpty) return '';
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
  if (feitos.isEmpty) return 'Nenhuma marcação ainda';
  final recent = feitos
      .take(7)
      .map((c) => habitoCheckDiaLabel(c.data))
      .join(', ');
  return 'Últimas marcações: $recent';
}

List<HabitoCheckDia>? habitoPatchCheckHoje(
  List<HabitoCheckDia>? checks,
  bool feito, {
  DateTime? now,
}) {
  if (checks == null) return null;
  final today = now ?? DateTime.now();
  final key = DateTime(today.year, today.month, today.day);
  final rest =
      checks.where((c) {
        final day = DateTime(c.data.year, c.data.month, c.data.day);
        return day != key;
      }).toList();
  return [HabitoCheckDia(data: key, feito: feito), ...rest];
}
