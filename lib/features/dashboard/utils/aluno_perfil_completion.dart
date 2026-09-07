import '../../alunos/data/aluno_repository.dart';

int alunoPerfilCompletionScore(Aluno aluno) {
  final values = [
    aluno.nome,
    aluno.email,
    aluno.objetivo ?? '',
    aluno.whatsapp ?? '',
    aluno.peso?.toString() ?? '',
    aluno.altura?.toString() ?? '',
    aluno.dataNascimento ?? '',
  ];
  final filled = values.where((value) => value.trim().isNotEmpty).length;
  return ((filled / values.length) * 100).round();
}
