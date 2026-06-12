/// Resumo da API após confirmar importação na migração mágica.
class MigracaoImportacaoResumo {
  const MigracaoImportacaoResumo({
    required this.importados,
    required this.duplicados,
    required this.erros,
    this.mensagem = '',
    this.detalhes = const [],
  });

  final int importados;
  final int duplicados;
  final int erros;
  final String mensagem;
  final List<MigracaoImportacaoDetalhe> detalhes;

  factory MigracaoImportacaoResumo.fromJson(Map<String, dynamic> json) {
    final detalhesRaw = json['detalhes'];
    final detalhes =
        detalhesRaw is List
            ? detalhesRaw
                .whereType<Map>()
                .map(
                  (item) => MigracaoImportacaoDetalhe.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
            : const <MigracaoImportacaoDetalhe>[];

    int asInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;

    return MigracaoImportacaoResumo(
      importados: asInt(json['importados']),
      duplicados: asInt(json['duplicados']),
      erros: asInt(json['erros']),
      mensagem: (json['mensagem'] ?? '').toString(),
      detalhes: detalhes,
    );
  }
}

class MigracaoImportacaoDetalhe {
  const MigracaoImportacaoDetalhe({
    required this.nome,
    required this.status,
    this.motivo = '',
  });

  final String nome;
  final String status;
  final String motivo;

  factory MigracaoImportacaoDetalhe.fromJson(Map<String, dynamic> json) {
    return MigracaoImportacaoDetalhe(
      nome: (json['nome'] ?? 'Aluno').toString(),
      status: (json['status'] ?? '').toString(),
      motivo: (json['motivo'] ?? '').toString(),
    );
  }
}
