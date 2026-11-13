import '../../../core/utils/fx_utils.dart';
import '../data/desafio_repository.dart';

/// Desafio conta coisa real (spec 11/11): treino concluído ou hábito marcado
/// vale 1. `metaPontos`/`pontos` do backend são essa contagem.
const desafioTipos = <({String value, String label})>[
  (value: 'TREINOS', label: 'Treinos concluídos'),
  (value: 'HABITOS', label: 'Hábitos marcados'),
];

const desafioDuracoes = <int>[7, 14, 30];

bool desafioEhTreinos(String tipo) => tipo.trim().toUpperCase() == 'TREINOS';

/// "O que conta": "Treinos concluídos" ou "Hábitos marcados".
String desafioTipoLabel(String tipo) =>
    desafioEhTreinos(tipo) ? 'Treinos concluídos' : 'Hábitos marcados';

/// "12 treinos", "1 hábito marcado".
/// Itens do "⋯" do detalhe, na ordem: editar e encerrar só no ativo;
/// excluir só enquanto ninguém contou.
List<String> desafioMenuAcoes({
  required bool ativo,
  required bool podeExcluir,
}) => [if (ativo) 'editar', if (ativo) 'encerrar', if (podeExcluir) 'excluir'];

String desafioUnidade(String tipo, int n) {
  if (desafioEhTreinos(tipo)) return n == 1 ? '1 treino' : '$n treinos';
  return n == 1 ? '1 hábito marcado' : '$n hábitos marcados';
}

/// A regra numa frase, mostrada antes do primeiro treino.
String desafioRegraFrase(String tipo) =>
    desafioEhTreinos(tipo)
        ? 'Cada treino concluído conta 1.'
        : 'Cada hábito marcado conta 1.';

String desafioDuracaoLabel(int dias) => dias == 1 ? '1 dia' : '$dias dias';

String desafioCountLabel(int count) {
  if (count <= 0) return 'Nenhum desafio';
  if (count == 1) return '1 desafio';
  return '$count desafios';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int desafioDiasRestantes(DateTime? fim, {DateTime? now}) {
  if (fim == null) return 0;
  return _dateOnly(fim).difference(_dateOnly(now ?? DateTime.now())).inDays;
}

/// "faltam 18 dias", "último dia", "encerrado".
String desafioFaltam(DateTime? fim, {DateTime? now}) {
  if (fim == null) return 'sem prazo';
  final dias = desafioDiasRestantes(fim, now: now);
  if (dias < 0) return 'encerrado';
  if (dias == 0) return 'último dia';
  if (dias == 1) return 'falta 1 dia';
  return 'faltam $dias dias';
}

String _capitalizar(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Linha da lista: "Treinos concluídos · meta 12 · faltam 18 dias".
String desafioLinhaLista(Desafio d, {DateTime? now}) => [
  desafioTipoLabel(d.tipo),
  'meta ${desafioUnidade(d.tipo, d.metaPontos)}',
  desafioFaltam(d.fim, now: now),
].join(' · ');

/// Linha do aluno na lista: "Você: 1 de 5 treinos · 1º lugar", e o líder
/// quando não é ele ("Julio lidera com 3"). Backend antigo (sem a contagem
/// dele): só o líder.
String? desafioLinhaAluno(Desafio d) {
  final n = d.minhaContagem;
  final lider = desafioLiderLabel(d);
  if (n == null) return lider;
  final pos = d.minhaPosicao;
  return [
    'Você: $n de ${desafioUnidade(d.tipo, d.metaPontos)}',
    if (pos != null) '$posº lugar',
    if (pos != 1 && lider != null) lider,
  ].join(' · ');
}

/// Cabeçalho do detalhe: "Treinos concluídos · meta 12 · até 11/12".
String desafioRegraDetalhe(Desafio d) => [
  desafioTipoLabel(d.tipo),
  'meta ${d.metaPontos}',
  if (d.fim != null) 'até ${fxDateShort(d.fim!)}',
].join(' · ');

String desafioFaltamTitulo(DateTime? fim, {DateTime? now}) =>
    _capitalizar(desafioFaltam(fim, now: now));

/// Na lista: "Julio lidera com 7". Sem contagem, nada.
String? desafioLiderLabel(Desafio d) {
  final nome = d.liderNome?.trim();
  final n = d.liderContagem;
  if (nome == null || nome.isEmpty || n == null || n <= 0) return null;
  return '${nome.split(' ').first} lidera com $n';
}

/// "7 de 12".
String desafioProgresso(int n, int meta) => '$n de $meta';

double desafioFracao(int n, int meta) =>
    meta <= 0 ? 0 : (n / meta).clamp(0, 1).toDouble();

int? desafioMeuIndex(Iterable<int> alunoIds, int? meId) {
  if (meId == null || meId <= 0) return null;
  var i = 0;
  for (final id in alunoIds) {
    if (id == meId) return i;
    i++;
  }
  return null;
}

/// Linha do aluno: "Você tem 7 de 12 treinos · 2º lugar".
String desafioMeuResumo({
  required String tipo,
  required int? index,
  required int contagem,
  required int meta,
}) {
  if (index == null || contagem <= 0) {
    return desafioEhTreinos(tipo)
        ? 'Você ainda não tem treino concluído neste desafio.'
        : 'Você ainda não marcou hábito neste desafio.';
  }
  final unidade = desafioEhTreinos(tipo) ? 'treinos' : 'hábitos';
  final base = 'Você tem $contagem de $meta $unidade · ${index + 1}º lugar';
  return contagem >= meta ? '$base · meta batida' : base;
}

String desafioLeaderboardName(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Aluno';
  return value;
}

/// Sugestão de meta pelo prazo: 3 treinos por semana, ou 5 marcações por
/// semana por hábito ativo.
int desafioMetaSugerida({
  required String tipo,
  required int dias,
  int habitosAtivos = 1,
}) {
  final semanas = dias / 7;
  final porSemana =
      desafioEhTreinos(tipo) ? 3 : 5 * (habitosAtivos < 1 ? 1 : habitosAtivos);
  final meta = (semanas * porSemana).round();
  return meta < 1 ? 1 : meta;
}

String desafioNomeSugerido(int dias) => 'Desafio de $dias dias';

/// "Entram todos os seus 8 alunos ativos."
String desafioQuemEntra(int? ativos) {
  if (ativos == null) return 'Entram todos os seus alunos ativos.';
  if (ativos == 1) return 'Entra o seu aluno ativo.';
  return 'Entram todos os seus $ativos alunos ativos.';
}

/// Filtros e busca só ajudam com mais de 6 desafios.
bool desafioMostraFiltros({required int total, required bool filtrando}) =>
    total > 6 || filtrando;

enum DesafioTipoFiltro { todos, habitos, treinos }

String? desafioFiltroTipo(DesafioTipoFiltro filtro) => switch (filtro) {
  DesafioTipoFiltro.todos => null,
  DesafioTipoFiltro.habitos => 'HABITOS',
  DesafioTipoFiltro.treinos => 'TREINOS',
};

String desafioFiltroLabel(DesafioTipoFiltro filtro) => switch (filtro) {
  DesafioTipoFiltro.todos => 'Todos',
  DesafioTipoFiltro.habitos => 'Hábitos',
  DesafioTipoFiltro.treinos => 'Treinos',
};

String desafioDetailPath(int id) => '/desafios/$id';

String desafioAlunoDetailPath(int id) => '/aluno/desafios/$id';

String desafioStickyAlunoLabel(String tipo) =>
    desafioEhTreinos(tipo) ? 'Ir aos treinos' : 'Ir aos hábitos';

String desafioStickyAlunoPath(String tipo) =>
    desafioEhTreinos(tipo) ? '/checkin/treinos' : '/aluno/habitos';
