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
                (d.linkAtivacao?.isNotEmpty ?? false),
          )
          .toList(growable: false);

  /// Alunos que tiveram e-mail de convite enviado automaticamente.
  List<MigracaoImportacaoDetalhe> get emailEnviadoAutomaticamente =>
      importadosComAcesso
          .where((d) => d.emailEnviado)
          .toList(growable: false);

  /// Tem e-mail real, mas o envio falhou: sai pelo WhatsApp ou pelo link.
  List<MigracaoImportacaoDetalhe> get emailNaoSaiu =>
      importadosComAcesso
          .where((d) => !d.emailEnviado && d.emailReal)
          .toList(growable: false);

  /// Sem e-mail real, com telefone: WhatsApp.
  List<MigracaoImportacaoDetalhe> get soTelefone =>
      importadosComAcesso
          .where(
            (d) =>
                !d.emailEnviado &&
                !d.emailReal &&
                (d.telefone?.isNotEmpty ?? false),
          )
          .toList(growable: false);

  /// Sem e-mail real e sem telefone: só copiar o link.
  List<MigracaoImportacaoDetalhe> get semContato =>
      importadosComAcesso
          .where(
            (d) =>
                !d.emailEnviado &&
                !d.emailReal &&
                (d.telefone?.isEmpty ?? true),
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
    this.linkAtivacao,
    this.emailEnviado = false,
    this.emailReal = false,
    this.emailFalha,
  });

  final String nome;
  final String status;
  final String motivo;
  final int? alunoId;
  final String? email;
  final String? telefone;
  final String? linkAtivacao;
  final bool emailEnviado;

  /// O aluno tem e-mail de verdade (não o provisório do import).
  final bool emailReal;

  /// Motivo estável da falha do envio (diagnóstico, nunca mostrado ao personal).
  final String? emailFalha;

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
      linkAtivacao: json['linkAtivacao']?.toString(),
      emailEnviado: json['emailEnviado'] == true,
      emailReal: json['emailReal'] == true,
      emailFalha: json['emailFalha']?.toString(),
    );
  }
}
