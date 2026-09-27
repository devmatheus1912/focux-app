/// Insight único da Home do aluno, decidido pelo BFF (`GET /api/dashboard/aluno/home`).
/// Só sinais que nenhum outro bloco da Home mostra.
enum AlunoInsightTipo { volumeSubindo, ritmoCaiu }

enum AlunoInsightConfianca { high, medium, low }

const _tiposWire = <String, AlunoInsightTipo>{
  'VOLUME_SUBINDO': AlunoInsightTipo.volumeSubindo,
  'RITMO_CAIU': AlunoInsightTipo.ritmoCaiu,
};

const _confiancaWire = <String, AlunoInsightConfianca>{
  'HIGH': AlunoInsightConfianca.high,
  'MEDIUM': AlunoInsightConfianca.medium,
  'LOW': AlunoInsightConfianca.low,
};

class AlunoHomeInsight {
  const AlunoHomeInsight({
    required this.tipo,
    required this.confianca,
    required this.chave,
    required this.titulo,
    required this.mensagem,
    this.params = const {},
  });

  final AlunoInsightTipo tipo;
  final AlunoInsightConfianca confianca;

  /// Chave ARB do texto; vazia quando o servidor não mandou.
  final String chave;
  final Map<String, String> params;

  /// Texto pt do servidor — fallback quando a chave não existe no app.
  final String titulo;
  final String mensagem;

  /// `null` quando o payload falta, tem tipo desconhecido ou vem malformado.
  static AlunoHomeInsight? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final tipo = _tiposWire[raw['tipo']];
    final confianca = _confiancaWire[raw['confianca']];
    final titulo = raw['titulo'];
    final mensagem = raw['mensagem'];
    if (tipo == null ||
        confianca == null ||
        titulo is! String ||
        mensagem is! String) {
      return null;
    }
    final chave = raw['chave'];
    return AlunoHomeInsight(
      tipo: tipo,
      confianca: confianca,
      chave: chave is String ? chave : '',
      params: _parseParams(raw['params']),
      titulo: titulo,
      mensagem: mensagem,
    );
  }

  static Map<String, String> _parseParams(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.value != null) '${e.key}': '${e.value}',
    };
  }
}
