import 'rotina_fila.dart';

/// Por que a ficha foi guardada. Valor desconhecido cai em [historico].
enum MotivoTroca {
  recomecada,
  modelo,
  duplicada,
  copiadaDeOutro,
  historico;

  static MotivoTroca parse(String? raw) => switch ((raw ?? '').toUpperCase()) {
    'RECOMECADA' => recomecada,
    'MODELO' => modelo,
    'DUPLICADA' => duplicada,
    'COPIADA_DE_OUTRO' => copiadaDeOutro,
    _ => historico,
  };
}

/// Um dia da ficha guardada. [disponivel] é falso quando o treino foi excluído.
class FichaHistoricoItem {
  const FichaHistoricoItem({
    required this.descanso,
    this.treinoId,
    this.nome = '',
    this.diaSemana,
    this.exerciciosCount = 0,
    this.disponivel = false,
  });

  final bool descanso;
  final int? treinoId;
  final String nome;
  final int? diaSemana;
  final int exerciciosCount;
  final bool disponivel;

  factory FichaHistoricoItem.fromJson(Map<String, dynamic> json) {
    final tipo = (json['tipo'] as String? ?? '').toUpperCase();
    return FichaHistoricoItem(
      descanso: tipo == 'DESCANSO',
      treinoId: (json['treinoId'] as num?)?.toInt(),
      nome: json['nome'] as String? ?? '',
      diaSemana: (json['diaSemana'] as num?)?.toInt(),
      exerciciosCount: (json['exerciciosCount'] as num?)?.toInt() ?? 0,
      disponivel: json['disponivel'] as bool? ?? false,
    );
  }
}

/// Uma ficha que o aluno já teve.
class FichaHistorico {
  const FichaHistorico({
    required this.id,
    required this.motivo,
    required this.encerradaEm,
    this.nomeModelo,
    this.vigenciaInicio,
    this.vigenciaFim,
    this.sessoes = 0,
    this.exercicios = 0,
    this.itens = const [],
  });

  final int id;
  final MotivoTroca motivo;
  final String? nomeModelo;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFim;
  final DateTime encerradaEm;
  final int sessoes;
  final int exercicios;
  final List<FichaHistoricoItem> itens;

  List<FichaHistoricoItem> get sessoesDaSemana =>
      itens.where((item) => !item.descanso).toList(growable: false);

  /// Ainda há sessão que dá para copiar.
  bool get temSessaoDisponivel => sessoesDaSemana.any((item) => item.disponivel);

  factory FichaHistorico.fromJson(Map<String, dynamic> json) {
    DateTime? data(String chave) {
      final raw = json[chave] as String?;
      return raw == null ? null : DateTime.tryParse(raw);
    }

    return FichaHistorico(
      id: (json['id'] as num).toInt(),
      motivo: MotivoTroca.parse(json['motivo'] as String?),
      nomeModelo: json['nomeModelo'] as String?,
      vigenciaInicio: data('vigenciaInicio'),
      vigenciaFim: data('vigenciaFim'),
      encerradaEm: data('encerradaEm') ?? DateTime.fromMillisecondsSinceEpoch(0),
      sessoes: (json['sessoes'] as num?)?.toInt() ?? 0,
      exercicios: (json['exercicios'] as num?)?.toInt() ?? 0,
      itens: (json['itens'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => FichaHistoricoItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

/// Resposta de "usar como base": a ficha nova e o que ficou de fora.
class UsoDaFichaAnterior {
  const UsoDaFichaAnterior({required this.rotina, this.semSessao = const []});

  final RotinaFila rotina;
  final List<String> semSessao;

  factory UsoDaFichaAnterior.fromJson(Map<String, dynamic> json) {
    return UsoDaFichaAnterior(
      rotina: RotinaFila.fromJson(json['rotina']),
      semSessao: (json['semSessao'] as List? ?? const []).whereType<String>().toList(),
    );
  }
}
