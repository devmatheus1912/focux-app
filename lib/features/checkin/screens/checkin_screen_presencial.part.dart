part of 'checkin_screen.dart';

/// Modo presencial (SPEC-modo-presencial): a mesma execução, conduzida pelo
/// personal no aparelho dele. Muda só o canal (rotas `/api/checkin/personal`),
/// o título, para onde volta e a pergunta de esforço por série.
extension _CheckinPresencial on _CheckinScreenState {
  bool get _presencial => widget.presencialAlunoId != null;

  /// No app do aluno, a sessão que o personal está conduzindo é só leitura.
  bool get _somenteLeitura => !_presencial && (_execucao?.presencial ?? false);

  /// "A · Empurrar · com Julio": nunca confundir de quem é a sessão.
  String _tituloDoTreino(String nome) {
    final aluno = widget.alunoNome?.trim().split(' ').first ?? '';
    return _presencial && aluno.isNotEmpty ? '$nome · com $aluno' : nome;
  }

  /// Ao sair ou concluir: o 360 do aluno no presencial, senão a aba Treinos.
  String get _voltarPara =>
      _presencial ? '/alunos/${widget.presencialAlunoId}' : '/checkin/treinos';

  /// O detalhe da sessão que o 360 usa, no presencial.
  String _detalheDaSessao(int execucaoId) => _presencial
      ? '/alunos/${widget.presencialAlunoId}/sessoes/$execucaoId'
      : historicoDetalhePath(execucaoId);
}
