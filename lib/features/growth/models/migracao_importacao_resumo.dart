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

  List<MigracaoImportacaoDetalhe> get importadosComAcesso =>
      detalhes
          .where(
            (d) =>
                d.status == 'IMPORTADO' &&
                (d.senhaProvisoria?.isNotEmpty ?? false),
          )
          .toList(growable: false);

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
    this.alunoId,
    this.email,
    this.telefone,
    this.senhaProvisoria,
  });

  final String nome;
  final String status;
  final String motivo;
  final int? alunoId;
  final String? email;
  final String? telefone;
  final String? senhaProvisoria;

  factory MigracaoImportacaoDetalhe.fromJson(Map<String, dynamic> json) {
    int? asId(dynamic value) {
      if (value is int) return value;
      return int.tryParse('$value');
    }

    return MigracaoImportacaoDetalhe(
      nome: (json['nome'] ?? 'Aluno').toString(),
      status: (json['status'] ?? '').toString(),
      motivo: (json['motivo'] ?? '').toString(),
      alunoId: asId(json['alunoId']),
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
      senhaProvisoria: json['senhaProvisoria']?.toString(),
    );
  }
}
