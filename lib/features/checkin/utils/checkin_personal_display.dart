import '../models/checkin_personal_home.dart';

const checkinComoCalculamos =
    'Hoje conta só treinos concluídos hoje, igual ao pulso da Home. Semana são os 6 dias anteriores. Pendentes são alunos ativos com treino e sem check-in concluído hoje. O catálogo pagina o recorte de 7 dias.';

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
  });

  final int alunoId;
  final String alunoNome;
  final String? fotoUrl;
  final List<String> treinos;
  final DateTime? ultimoEm;
  final int parciais;
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
      ),
  ];
}

String checkinDoAlunoLinha(CheckinDoAluno grupo) {
  final nomes = grupo.treinos.toSet().toList();
  final linha =
      grupo.treinos.length == 1
          ? nomes.first
          : '${grupo.treinos.length} treinos · ${nomes.join(', ')}';
  return switch (grupo.parciais) {
    0 => linha,
    1 when grupo.treinos.length == 1 => '$linha · parcial',
    final n => '$linha · $n parciais',
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
    if (dia == null) return 'Sem data';
    if (hoje.difference(dia).inDays == 1) return 'Ontem';
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

String checkinResumoDoDia(CheckinPersonalHomeBundle home) {
  final treinos = home.checkinsHoje;
  final alunos = checkinPorAluno(home.hoje).length;
  final faltam = home.pendentes.length;
  return [
    if (treinos == 0)
      'Nenhum treino hoje'
    else
      '$treinos ${treinos == 1 ? 'treino' : 'treinos'}',
    if (alunos > 0) '$alunos ${alunos == 1 ? 'aluno' : 'alunos'}',
    if (faltam > 0) '$faltam ${faltam == 1 ? 'falta' : 'faltam'}',
  ].join(' · ');
}
