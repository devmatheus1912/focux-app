/// As quatro etapas da ficha do aluno, na ordem em que aparecem.
enum AnamneseEtapa { saudeGeral, historico, habitos, objetivos }

const anamneseQualidadeSonoOpcoes = ['Boa', 'Regular', 'Ruim'];
const anamneseEstresseOpcoes = ['Baixo', 'Médio', 'Alto'];
const anamneseTabagismoOpcoes = ['Não fumo', 'Parei', 'Fumo'];
const anamneseAlcoolOpcoes = ['Não bebo', 'Às vezes', 'Toda semana'];
const anamneseObjetivoOpcoes = [
  'Hipertrofia',
  'Emagrecimento',
  'Condicionamento',
  'Saúde',
];

/// Perguntas do PAR-Q+ ainda sem resposta, na ordem da ficha.
List<String> anamneseParqPendentes(Map<String, bool?> respostas) => [
  for (final e in respostas.entries)
    if (e.value == null) e.key,
];

/// O que falta para avançar. Só a primeira e a última etapa têm obrigatório.
bool anamneseEtapaCompleta(
  AnamneseEtapa etapa, {
  required Map<String, bool?> parq,
  required String objetivo,
  required int? dias,
}) => switch (etapa) {
  AnamneseEtapa.saudeGeral => anamneseParqPendentes(parq).isEmpty,
  AnamneseEtapa.objetivos => objetivo.trim().isNotEmpty && dias != null,
  _ => true,
};

/// Chip do valor salvo. Texto antigo livre não casa com nenhum: é "Outro", e
/// continua no campo sem se perder. [comDetalhe] casa pelo início ("Fumo · 5").
String? anamneseChipDoValor(
  String valor,
  List<String> opcoes, {
  String? comDetalhe,
}) {
  final t = valor.trim();
  if (t.isEmpty) return null;
  for (final opcao in opcoes) {
    if (opcao.toLowerCase() == t.toLowerCase()) return opcao;
  }
  if (comDetalhe != null &&
      t.toLowerCase().startsWith(comDetalhe.toLowerCase())) {
    return comDetalhe;
  }
  return null;
}
