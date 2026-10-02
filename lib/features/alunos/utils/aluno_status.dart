import 'package:flutter/material.dart';

import '../data/aluno_repository.dart';

/// Status do cadastro no backend. INATIVO = pausado (mantém acesso);
/// BLOQUEADO = pausado e sem acesso ao app.
abstract final class AlunoStatus {
  static const ativo = 'ATIVO';
  static const inativo = 'INATIVO';
  static const bloqueado = 'BLOQUEADO';
}

String alunoStatusNormalizado(String status) => status.trim().toUpperCase();

/// Só ATIVO recebe alertas de risco, cobranças automáticas e lembretes.
bool alunoStatusAtivo(Aluno aluno) =>
    alunoStatusNormalizado(aluno.status) == AlunoStatus.ativo;

String alunoPrimeiroNome(String nome) {
  final trimmed = nome.trim();
  if (trimmed.isEmpty) return 'o aluno';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// Explicação curta do status — tooltip do badge e legenda do picker.
String? alunoStatusExplicacao(String status) => switch (alunoStatusNormalizado(
  status,
)) {
  AlunoStatus.inativo => 'Pausado: sem alertas e cobranças automáticas',
  AlunoStatus.bloqueado => 'Pausado e sem acesso ao app',
  _ => null,
};

/// Ações de status da ficha 360, na ordem do menu.
List<String> alunoStatusAcoesDisponiveis(String statusAtual) =>
    switch (alunoStatusNormalizado(statusAtual)) {
      AlunoStatus.inativo => const [AlunoStatus.ativo, AlunoStatus.bloqueado],
      AlunoStatus.bloqueado => const [AlunoStatus.ativo, AlunoStatus.inativo],
      _ => const [AlunoStatus.inativo, AlunoStatus.bloqueado],
    };

IconData alunoStatusIcon(String status) => switch (alunoStatusNormalizado(
  status,
)) {
  AlunoStatus.inativo => Icons.pause_circle_outline_rounded,
  AlunoStatus.bloqueado => Icons.block_rounded,
  _ => Icons.check_circle_outline_rounded,
};

String alunoStatusAcaoLabel(String novoStatus) =>
    switch (alunoStatusNormalizado(novoStatus)) {
      AlunoStatus.inativo => 'Pausar aluno',
      AlunoStatus.bloqueado => 'Bloquear acesso',
      _ => 'Reativar',
    };

String alunoStatusConfirmTitle(String novoStatus, String nome) {
  final first = alunoPrimeiroNome(nome);
  return switch (alunoStatusNormalizado(novoStatus)) {
    AlunoStatus.inativo => 'Pausar $first?',
    AlunoStatus.bloqueado => 'Bloquear acesso de $first?',
    _ => 'Reativar $first?',
  };
}

String alunoStatusConfirmMessage(String novoStatus, {int count = 1}) {
  final plural = count > 1;
  return switch (alunoStatusNormalizado(novoStatus)) {
    AlunoStatus.inativo =>
      'Sem alertas, cobranças automáticas e lembretes. '
          '${plural ? 'Os alunos continuam' : 'O aluno continua'} vendo o histórico.',
    AlunoStatus.bloqueado =>
      '${plural ? 'Os alunos perdem' : 'O aluno perde'} o acesso ao app na hora. '
          'Sem alertas e cobranças automáticas.',
    _ =>
      'Alertas, cobranças automáticas e lembretes voltam a valer. '
          'O acesso ao app é liberado.',
  };
}

String alunoStatusConfirmLabel(String novoStatus) =>
    switch (alunoStatusNormalizado(novoStatus)) {
      AlunoStatus.inativo => 'Pausar',
      AlunoStatus.bloqueado => 'Bloquear',
      _ => 'Reativar',
    };

/// Snackbar da ficha. Sem gênero no cadastro, a frase fica neutra.
String alunoStatusAlteradoMessage(
  String novoStatus, {
  required String nome,
  String? genero,
}) {
  final first = alunoPrimeiroNome(nome);
  final g = genero?.trim().toUpperCase();
  final sufixo =
      g == 'FEMININO'
          ? 'a'
          : g == 'MASCULINO'
          ? 'o'
          : null;
  return switch (alunoStatusNormalizado(novoStatus)) {
    AlunoStatus.inativo =>
      sufixo == null ? 'Pausa aplicada a $first' : '$first pausad$sufixo',
    AlunoStatus.bloqueado => 'Acesso de $first bloqueado',
    _ =>
      sufixo == null
          ? 'Cadastro de $first reativado'
          : '$first reativad$sufixo',
  };
}

String alunosStatusAlteradosMessage(String novoStatus, int count) {
  final verbo = switch (alunoStatusNormalizado(novoStatus)) {
    AlunoStatus.inativo => count == 1 ? 'pausado' : 'pausados',
    AlunoStatus.bloqueado => count == 1 ? 'bloqueado' : 'bloqueados',
    _ => count == 1 ? 'reativado' : 'reativados',
  };
  return count == 1 ? '1 aluno $verbo' : '$count alunos $verbo';
}

String alunosStatusConfirmTitle(String novoStatus, int count) {
  final alvo = count == 1 ? '1 aluno' : '$count alunos';
  return switch (alunoStatusNormalizado(novoStatus)) {
    AlunoStatus.inativo => 'Pausar $alvo?',
    AlunoStatus.bloqueado => 'Bloquear acesso de $alvo?',
    _ => 'Reativar $alvo?',
  };
}

/// Status comum da seleção; `null` se misturado ou vazio.
String? alunosStatusComum(Iterable<Aluno> alunos) {
  String? comum;
  for (final aluno in alunos) {
    final status = alunoStatusNormalizado(aluno.status);
    if (comum == null) {
      comum = status;
    } else if (comum != status) {
      return null;
    }
  }
  return comum;
}
