import '../models/checkin_personal_home.dart';
import '../../../l10n/pt.dart';

final checkinComoCalculamos =
    ptS.checkinHojeContaSoTreinosConcluidos;

class CheckinFocusAction {
  const CheckinFocusAction({required this.label, this.alunoId});

  final String label;
  final int? alunoId;
}

String checkinPrimeiroNome(String nome) {
  final trimmed = nome.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Uma linha por aluno: quem fez três treinos não ocupa três linhas.
class CheckinDoAluno {
  const CheckinDoAluno({
    required this.alunoId,
    required this.alunoNome,
    required this.fotoUrl,
    required this.treinos,
    required this.ultimoEm,
    this.parciais = 0,
    this.itens = const [],
  });

  final int alunoId;
  final String alunoNome;
  final String? fotoUrl;
  final List<String> treinos;
  final DateTime? ultimoEm;
  final int parciais;

  /// As sessões do grupo, para abrir o treino (uma ou a escolha).
  final List<CheckinPersonalItem> itens;
}

List<CheckinDoAluno> checkinPorAluno(List<CheckinPersonalItem> itens) {
  final grupos = <int, List<CheckinPersonalItem>>{};
  for (final item in itens) {
    grupos.putIfAbsent(item.alunoId, () => []).add(item);
  }
  return [
    for (final lista in grupos.values)
      CheckinDoAluno(
        alunoId: lista.first.alunoId,
        alunoNome: lista.first.alunoNome,
        fotoUrl: lista.first.fotoUrl,
        treinos: [for (final i in lista) i.treinoNome],
        ultimoEm: lista.first.iniciadoEm,
        parciais: lista.where((i) => i.parcial).length,
        itens: List.unmodifiable(lista),
      ),
  ];
}

String checkinDoAlunoLinha(CheckinDoAluno grupo) {
  final nomes = grupo.treinos.toSet().toList();
  final linha =
      grupo.treinos.length == 1
          ? nomes.first
          : ptS.checkinTreinos(grupo.treinos.length, nomes.join(', '));
  // "1 parcial" no singular, com um ou com vários treinos (SPEC 12/11).
  return switch (grupo.parciais) {
    0 => linha,
    1 when grupo.treinos.length == 1 => ptS.checkinParcial(linha),
    1 => '$linha · 1 parcial',
    final n => ptS.checkinParciais(linha, n),
  };
}

/// Dias da semana, do mais recente, cada um com uma linha por aluno.
List<(String, List<CheckinDoAluno>)> checkinPorDia(
  List<CheckinPersonalItem> itens, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final hoje = DateTime(ref.year, ref.month, ref.day);
  final porDia = <DateTime?, List<CheckinPersonalItem>>{};
  for (final item in itens) {
    final dt = item.iniciadoEm?.toLocal();
    final dia = dt == null ? null : DateTime(dt.year, dt.month, dt.day);
    porDia.putIfAbsent(dia, () => []).add(item);
  }
  String rotulo(DateTime? dia) {
    if (dia == null) return ptS.engajamentoSemData;
    if (hoje.difference(dia).inDays == 1) return ptS.treinosDiaOntem;
    final d = dia.day.toString().padLeft(2, '0');
    final m = dia.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  final dias = porDia.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return b.compareTo(a);
    });
  return [for (final dia in dias) (rotulo(dia), checkinPorAluno(porDia[dia]!))];
}

/// Hora à direita dentro do grupo do dia ("18:48"); em Hoje, menos de 1 hora
/// vira "há 5 min". O cabeçalho do dia já diz quando.
String checkinHoraLinha(DateTime quando, {DateTime? now}) {
  final ref = now ?? DateTime.now();
  final local = quando.toLocal();
  final diff = ref.difference(local);
  final mesmoDia =
      local.year == ref.year && local.month == ref.month && local.day == ref.day;
  if (mesmoDia && !diff.isNegative && diff.inMinutes < 60) {
    return diff.inMinutes <= 0 ? 'agora' : 'há ${diff.inMinutes} min';
  }
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Título de Hoje: "Hoje · 3 treinos".
String checkinHojeTitulo(int treinos) =>
    treinos <= 0 ? 'Hoje' : 'Hoje · $treinos ${treinos == 1 ? 'treino' : 'treinos'}';

/// Só os dias anteriores a hoje (a folha de "Últimos 6 dias").
List<CheckinPersonalItem> checkinSemHoje(
  List<CheckinPersonalItem> itens, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  return [
    for (final i in itens)
      if (i.iniciadoEm == null ||
          !(i.iniciadoEm!.toLocal().year == ref.year &&
              i.iniciadoEm!.toLocal().month == ref.month &&
              i.iniciadoEm!.toLocal().day == ref.day))
        i,
  ];
}

/// "5 treinos nos últimos 6 dias".
String checkinSemanaContagem(int n) =>
    '$n ${n == 1 ? 'treino' : 'treinos'} nos últimos 6 dias';

String checkinResumoDoDia(CheckinPersonalHomeBundle home) {
  final treinos = home.checkinsHoje;
  final alunos = checkinPorAluno(home.hoje).length;
  final faltam = home.pendentes.length;
  return [
    if (treinos == 0)
      ptS.checkinNenhumTreinoHoje
    else
      '$treinos ${treinos == 1 ? 'treino' : 'treinos'}',
    if (alunos > 0) '$alunos ${alunos == 1 ? 'aluno' : 'alunos'}',
    if (faltam > 0) '$faltam ${faltam == 1 ? 'falta' : 'faltam'}',
  ].join(' · ');
}
