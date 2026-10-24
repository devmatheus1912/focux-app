import '../utils/ficha_vigencia.dart';

enum RotinaItemTipo { treino, descanso }

class RotinaItem {
  const RotinaItem({
    required this.id,
    required this.tipo,
    this.treinoId,
    this.nome,
    this.diaSemana,
    this.exerciciosCount,
  });

  final int id;
  final RotinaItemTipo tipo;
  final int? treinoId;
  final String? nome;
  final int? diaSemana;
  final int? exerciciosCount;

  bool get descanso => tipo == RotinaItemTipo.descanso;

  String rotulo(String palavraDescanso) =>
      descanso ? palavraDescanso : (nome?.trim().isNotEmpty == true ? nome!.trim() : '');

  factory RotinaItem.fromJson(Map<String, dynamic> json) {
    final tipoRaw = (json['tipo'] as String? ?? '').toUpperCase();
    return RotinaItem(
      id: (json['id'] as num).toInt(),
      tipo: tipoRaw == 'DESCANSO' ? RotinaItemTipo.descanso : RotinaItemTipo.treino,
      treinoId: (json['treinoId'] as num?)?.toInt(),
      nome: json['nome'] as String?,
      diaSemana: (json['diaSemana'] as num?)?.toInt(),
      exerciciosCount: (json['exerciciosCount'] as num?)?.toInt(),
    );
  }
}

/// Fila que a Home devolve e que a tela do personal edita.
class RotinaFila {
  const RotinaFila({
    this.itens = const [],
    this.diasAviso = const {},
    this.sessaoAbertaTreinoId,
    this.ultimoTreinoId,
    this.concluiuHoje = false,
    this.sessoesAdiadas = const [],
    this.vigencia = VigenciaFicha.semPrazo,
    this.atualizadaEm,
  });

  static const vazia = RotinaFila();

  final List<RotinaItem> itens;
  final Set<int> diasAviso;
  final int? sessaoAbertaTreinoId;
  final int? ultimoTreinoId;
  final bool concluiuHoje;

  /// Sessões que saíram da ficha mas esperam o aluno terminar o treino aberto.
  final List<String> sessoesAdiadas;

  /// Quanto tempo a ficha vale (sem prazo por padrão).
  final VigenciaFicha vigencia;

  /// Quando o personal trocou a ficha pela última vez (nulo se nunca).
  final DateTime? atualizadaEm;

  bool get temTreino => itens.any((item) => !item.descanso);

  String linha(String palavraDescanso) => itens
      .map((item) => item.rotulo(palavraDescanso))
      .where((nome) => nome.isNotEmpty)
      .join(', ');

  factory RotinaFila.fromJson(Object? raw) {
    if (raw is! Map) return RotinaFila.vazia;
    final json = Map<String, dynamic>.from(raw);
    final itens = (json['itens'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => RotinaItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final dias = (json['diasAviso'] as List? ?? const [])
        .map((dia) => dia is num ? dia.toInt() : int.tryParse('$dia'))
        .whereType<int>()
        .where((dia) => dia >= 1 && dia <= 7)
        .toSet();
    return RotinaFila(
      itens: itens,
      diasAviso: dias,
      sessaoAbertaTreinoId: (json['sessaoAbertaTreinoId'] as num?)?.toInt(),
      ultimoTreinoId: (json['ultimoTreinoId'] as num?)?.toInt(),
      concluiuHoje: json['concluiuHoje'] == true,
      sessoesAdiadas: (json['sessoesAdiadas'] as List? ?? const [])
          .map((nome) => '$nome')
          .toList(growable: false),
      vigencia: VigenciaFicha.fromJson(json['vigencia']),
      atualizadaEm: DateTime.tryParse('${json['atualizadaEm'] ?? ''}'),
    );
  }
}
