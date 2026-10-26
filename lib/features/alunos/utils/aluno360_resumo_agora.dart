import '../../../l10n/app_localizations.dart';
import '../data/aluno_repository.dart';
import 'aluno360_operacao_logic.dart';

enum AgoraVerbo { chamar, cobrar, abrir, renovar, registrar }

String agoraVerboTexto(S s, AgoraVerbo verbo) => switch (verbo) {
  AgoraVerbo.chamar => s.alunoResumoVerboChamar,
  AgoraVerbo.cobrar => s.alunoResumoVerboCobrar,
  AgoraVerbo.abrir => s.alunoResumoVerboAbrir,
  AgoraVerbo.renovar => s.alunoResumoVerboRenovar,
  AgoraVerbo.registrar => s.alunoResumoVerboRegistrar,
};

/// A linha "Agora" da aba Resumo: o que fazer, por quê e o verbo do botão.
class ResumoAgora {
  const ResumoAgora({
    required this.titulo,
    required this.motivo,
    required this.verbo,
    required this.destino,
  });

  final String titulo;
  final String motivo;
  final AgoraVerbo verbo;
  final OperacaoStickyDestination destino;
}

/// O motivo curto de falar com o aluno ("9 dias sem treinar"), só com dados
/// do aluno. [riscoMotivo] (texto do servidor) entra só se parecer uma frase.
/// Nulo quando não há nada concreto a dizer.
String? motivoDeContato(S s, Aluno aluno, {String? riscoMotivo}) {
  final dias = aluno.diasSemTreino;
  if (dias != null && dias > 0) return s.alunoResumoMotivoDiasSemTreino(dias);
  final frase = _fraseDoServidor(riscoMotivo);
  if (frase != null) return frase;
  if (semHistoricoDeTreino(aluno)) return s.alunoResumoMotivoSemTreinos;
  return null;
}

/// Nunca treinou: sem dias parado e aderência nula ou zero.
bool semHistoricoDeTreino(Aluno aluno) =>
    (aluno.diasSemTreino == null || aluno.diasSemTreino == 0) &&
    (aluno.aderenciaPercent == null || aluno.aderenciaPercent == 0);

/// Texto do servidor só vale se for uma frase (não um código como SEM_TREINO_5D).
String? _fraseDoServidor(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty || !t.contains(' ')) return null;
  if (t == t.toUpperCase()) return null;
  return t;
}

/// Ordem: mensalidade, contato, cadastro, tarefa, treino. O motivo é sempre
/// o da ação mostrada: com contato prioritário, o do contato; senão, o
/// `motivo` da próxima ação do servidor. Nunca a frase de outra sugestão.
/// Sem nada urgente devolve nulo.
ResumoAgora? resumoAgora(
  S s, {
  required OperacaoStickyAction sticky,
  required ProximaAcaoResumo? proxima,
  required Aluno aluno,
  required bool contactPriority,
  String? riscoMotivo,
}) {
  final motivoServidor = _fraseDoServidor(proxima?.motivo);
  switch (sticky.destination) {
    case OperacaoStickyDestination.financeiro:
      return ResumoAgora(
        titulo: sticky.label,
        motivo: s.alunoResumoMotivoFinanceiro,
        verbo: AgoraVerbo.cobrar,
        destino: sticky.destination,
      );
    case OperacaoStickyDestination.chat:
      final motivo = contactPriority
          ? motivoDeContato(s, aluno, riscoMotivo: riscoMotivo)
          : null;
      final texto = motivo ?? motivoServidor;
      if (texto == null) return null;
      return ResumoAgora(
        titulo: sticky.label,
        motivo: texto,
        verbo: AgoraVerbo.chamar,
        destino: sticky.destination,
      );
    case OperacaoStickyDestination.commandCenter:
      if (sticky.label == 'Ver tarefa') {
        return ResumoAgora(
          titulo: sticky.label,
          motivo: motivoServidor ?? s.alunoResumoMotivoTarefa,
          verbo: AgoraVerbo.abrir,
          destino: sticky.destination,
        );
      }
      return _comSugestao(s, sticky, proxima, motivoServidor, AgoraVerbo.abrir);
    case OperacaoStickyDestination.commitment:
      return _comSugestao(s, sticky, proxima, motivoServidor, AgoraVerbo.registrar);
    case OperacaoStickyDestination.editAluno:
    case OperacaoStickyDestination.evolucao:
    case OperacaoStickyDestination.treino:
      return _comSugestao(s, sticky, proxima, motivoServidor, AgoraVerbo.abrir);
  }
}

/// Só há "Agora" quando o servidor sugeriu algo: o motivo é o dele, ou a
/// própria ação quando não veio motivo. Sem sugestão, nada urgente.
ResumoAgora? _comSugestao(
  S s,
  OperacaoStickyAction sticky,
  ProximaAcaoResumo? proxima,
  String? motivoServidor,
  AgoraVerbo verbo,
) {
  final acao = proxima?.acao.trim() ?? '';
  if (acao.isEmpty) return null;
  final motivo = motivoServidor ??
      (sticky.destination == OperacaoStickyDestination.editAluno
          ? s.alunoResumoMotivoCadastro
          : acao);
  return ResumoAgora(
    titulo: sticky.label,
    motivo: motivo,
    verbo: verbo,
    destino: sticky.destination,
  );
}
