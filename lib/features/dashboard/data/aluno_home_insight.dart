/// Insight único da Home do aluno, decidido pelo BFF (`GET /api/dashboard/aluno/home`).
enum AlunoInsightTipo {
  novo,
  recuperacao,
  pr,
  retorno,
  metaAtingida,
  forcaSubindo,
  volumeSubindo,
  consistente,
  ritmoCaiu,
  dadosInsuficientes,
}

enum AlunoInsightConfianca { high, medium, low }

const _tiposWire = <String, AlunoInsightTipo>{
  'NOVO': AlunoInsightTipo.novo,
  'RECUPERACAO': AlunoInsightTipo.recuperacao,
  'PR': AlunoInsightTipo.pr,
  'RETORNO': AlunoInsightTipo.retorno,
  'META_ATINGIDA': AlunoInsightTipo.metaAtingida,
  'FORCA_SUBINDO': AlunoInsightTipo.forcaSubindo,
  'VOLUME_SUBINDO': AlunoInsightTipo.volumeSubindo,
  'CONSISTENTE': AlunoInsightTipo.consistente,
  'RITMO_CAIU': AlunoInsightTipo.ritmoCaiu,
  'DADOS_INSUFICIENTES': AlunoInsightTipo.dadosInsuficientes,
};

const _confiancaWire = <String, AlunoInsightConfianca>{
  'HIGH': AlunoInsightConfianca.high,
  'MEDIUM': AlunoInsightConfianca.medium,
  'LOW': AlunoInsightConfianca.low,
};

class AlunoInsightAcao {
  const AlunoInsightAcao({required this.rota, required this.cta});

  final String rota;
  final String cta;
}

class AlunoHomeInsight {
  const AlunoHomeInsight({
    required this.tipo,
    required this.confianca,
    required this.chave,
    required this.titulo,
    required this.mensagem,
    this.params = const {},
    this.evidencia,
    this.acao,
  });

  final AlunoInsightTipo tipo;
  final AlunoInsightConfianca confianca;

  /// Chave ARB do texto; vazia quando o servidor não mandou.
  final String chave;
  final Map<String, String> params;

  /// Texto pt do servidor — fallback quando a chave não existe no app.
  final String titulo;
  final String mensagem;
  final String? evidencia;
  final AlunoInsightAcao? acao;

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
    final evidencia = raw['evidencia'];
    return AlunoHomeInsight(
      tipo: tipo,
      confianca: confianca,
      chave: chave is String ? chave : '',
      params: _parseParams(raw['params']),
      titulo: titulo,
      mensagem: mensagem,
      evidencia: evidencia is String ? evidencia : null,
      acao: _parseAcao(raw['acao']),
    );
  }

  static Map<String, String> _parseParams(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        if (e.value != null) '${e.key}': '${e.value}',
    };
  }

  static AlunoInsightAcao? _parseAcao(Object? raw) {
    if (raw is! Map) return null;
    final rota = raw['rota'];
    final cta = raw['cta'];
    if (rota is! String ||
        cta is! String ||
        !rota.startsWith('/') ||
        rota.startsWith('//')) {
      return null;
    }
    return AlunoInsightAcao(rota: rota, cta: cta);
  }
}
