import '../../exercicios/data/enums.dart';
import '../../exercicios/data/template_splits.dart';

/// Uma divisão da ficha: as letras (sessões) que o personal monta.
/// Com menos letras que dias de treino, os dias que sobram seguem a sequência.
class Divisao {
  const Divisao({
    required this.id,
    required this.rotulo,
    required this.sessoes,
    this.splitId,
  });

  final String id;

  /// O que aparece no chip: "ABC", "AB · Superior/Inferior".
  final String rotulo;

  /// Nome de cada sessão, na ordem: "A · Peito e tríceps", "Treino B"…
  final List<String> sessoes;

  /// Modelo de exercícios (`templateSplits`) usado para sugerir por letra.
  final String? splitId;

  int get letras => sessoes.length;
}

const _letras = 'ABCDEFG';

/// "Treino A", "Treino B"… para divisões sem foco.
List<String> _genericas(int n) => [for (var i = 0; i < n; i++) 'Treino ${_letras[i]}'];

/// Nome das sessões a partir do modelo de exercícios.
/// Um dia só usa o nome do modelo; dia "A" vira "Treino A"; "Superior" vira "A · Superior".
List<String> _doSplit(String splitId) {
  final split = templateSplits.firstWhere((t) => t.id == splitId);
  if (split.dias.length == 1) return [split.nome];
  return [
    for (final (i, dia) in split.dias.indexed)
      switch (dia.nome.trim()) {
        final n when n == _letras[i] => 'Treino $n',
        final n when n.startsWith('${_letras[i]} · ') || n.endsWith(' ${_letras[i]}') => n,
        final n => '${_letras[i]} · $n',
      },
  ];
}

Divisao _generica(int n, {String? rotulo}) => Divisao(
  id: 'letras-$n',
  rotulo: rotulo ?? _letras.substring(0, n),
  sessoes: _genericas(n),
);

Divisao _split(String splitId, String rotulo) =>
    Divisao(id: splitId, rotulo: rotulo, sessoes: _doSplit(splitId), splitId: splitId);

Divisao get _fullBody => _split('fullbody-iniciante', 'Full body');
Divisao get _fullBodyAb => _split('fullbody-ab', 'AB · Full body');
Divisao get _superiorInferior => _split('upper-lower', 'AB · Superior/Inferior');
Divisao get _abc => _split('bro-split', 'ABC');
Divisao get _ppl => _split('ppl', 'ABC · Empurrar/Puxar/Pernas');

/// Sugeridas por número de dias. A primeira é a recomendada.
List<Divisao> divisoesSugeridas(int dias) => switch (dias) {
  2 => [_fullBodyAb, _fullBody],
  3 => [_abc, _generica(3, rotulo: 'ABC · Full body'), _fullBodyAb],
  4 => [_superiorInferior, _generica(4), _abc],
  5 => [_abc, _generica(4), _generica(5)],
  6 => [_ppl, _generica(4), _generica(6)],
  7 => [_abc, _generica(4)],
  _ => const [],
};

/// Divisões de foco e em casa, recolhidas abaixo das sugeridas.
List<Divisao> outrasDivisoes(int dias) => [
  for (final t in templateSplits)
    if (t.grupo == TemplateSplitGroup.foco || t.id == 'casa-sem-equipo')
      if (t.dias.length <= dias) _split(t.id, t.nome),
];

/// Uma letra por dia: o comportamento de antes da divisão.
Divisao umaPorDia(int dias) => _generica(dias.clamp(0, 7));

/// O dia do modelo de exercícios que corresponde a uma sessão pelo nome
/// ("B · Costas e bíceps" → ABC, dia B). Nome genérico ("Treino B") não casa:
/// várias divisões usam as mesmas letras.
(TemplateSplit, int)? sugestaoDaSessao(String nome) {
  final alvo = nome.trim();
  if (alvo.isEmpty || RegExp(r'^Treino [A-G]$').hasMatch(alvo)) return null;
  for (final split in templateSplits) {
    final i = _doSplit(split.id).indexOf(alvo);
    if (i >= 0) return (split, split.dias.length == 1 ? 0 : i);
  }
  return null;
}

/// Palavras do nome da sessão que viram grupos ("Peito e tríceps", "Costas e bíceps").
const _gruposPorPalavra = <String, List<GrupoMuscular>>{
  'peito': [GrupoMuscular.peito],
  'triceps': [GrupoMuscular.triceps],
  'biceps': [GrupoMuscular.biceps],
  'costas': [GrupoMuscular.costasLatissimo, GrupoMuscular.costasRetangulares],
  'ombro': [GrupoMuscular.ombroAnterior, GrupoMuscular.ombroLateral, GrupoMuscular.ombroPosterior],
  'ombros': [GrupoMuscular.ombroAnterior, GrupoMuscular.ombroLateral, GrupoMuscular.ombroPosterior],
  'pernas': [GrupoMuscular.quadriceps, GrupoMuscular.posteriorCoxa],
  'perna': [GrupoMuscular.quadriceps, GrupoMuscular.posteriorCoxa],
  'quadriceps': [GrupoMuscular.quadriceps],
  'posterior': [GrupoMuscular.posteriorCoxa],
  'gluteo': [GrupoMuscular.gluteo],
  'gluteos': [GrupoMuscular.gluteo],
  'panturrilha': [GrupoMuscular.panturrilha],
  'abdomen': [GrupoMuscular.abdomen],
  'abdominal': [GrupoMuscular.abdomen],
  'trapezio': [GrupoMuscular.trapezio],
  'antebraco': [GrupoMuscular.antebraco],
  'bracos': [GrupoMuscular.biceps, GrupoMuscular.triceps],
};

/// Padrão de movimento de um bloco do modelo → grupo principal.
const _grupoDoPadrao = <PadraoMovimento, GrupoMuscular>{
  PadraoMovimento.pushHorizontal: GrupoMuscular.peito,
  PadraoMovimento.pushVertical: GrupoMuscular.ombroAnterior,
  PadraoMovimento.pullVertical: GrupoMuscular.costasLatissimo,
  PadraoMovimento.pullHorizontal: GrupoMuscular.costasRetangulares,
  PadraoMovimento.squat: GrupoMuscular.quadriceps,
  PadraoMovimento.hinge: GrupoMuscular.posteriorCoxa,
  PadraoMovimento.lunge: GrupoMuscular.quadriceps,
};

String _semAcento(String s) => s
    .toLowerCase()
    .replaceAll(RegExp('[áàâã]'), 'a')
    .replaceAll(RegExp('[éê]'), 'e')
    .replaceAll('í', 'i')
    .replaceAll(RegExp('[óôõ]'), 'o')
    .replaceAll('ú', 'u')
    .replaceAll('ç', 'c');

/// Grupos musculares de uma sessão pelo nome: primeiro as palavras do foco
/// ("A · Peito e tríceps" → peito e tríceps); sem palavra conhecida, os blocos
/// do dia no modelo de exercícios ("Empurrar"). Nome genérico ("Treino A") → vazio.
Set<GrupoMuscular> gruposDaSessao(String nome) {
  final texto = nome.trim();
  final foco = texto.contains(' · ') ? texto.split(' · ').last : texto;
  final porPalavra = <GrupoMuscular>{
    for (final palavra in _semAcento(foco).split(RegExp(r'[^a-z]+')))
      ...?_gruposPorPalavra[palavra],
  };
  if (porPalavra.isNotEmpty) return porPalavra;
  final dia = sugestaoDaSessao(texto);
  if (dia == null) return const {};
  final (split, indice) = dia;
  return {
    for (final slot in split.dias[indice].slots)
      if (slot.grupo case final grupo?)
        grupo
      else if (_grupoDoPadrao[slot.padrao] case final grupo?)
        grupo,
  };
}
