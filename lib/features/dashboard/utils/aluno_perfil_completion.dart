import '../../../l10n/app_localizations.dart';
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

/// O que ainda falta no cadastro, na ordem da tela: "contato, objetivo e
/// dados corporais". Vazio quando nada falta; no máximo três itens.
String queFaltaNoPerfil(S s, Aluno aluno) {
  bool vazio(String? v) => v == null || v.trim().isEmpty;
  final itens = [
    if (vazio(aluno.whatsapp)) s.alunoPerfilFaltaContato,
    if (vazio(aluno.objetivo)) s.alunoPerfilFaltaObjetivo,
    if (aluno.peso == null || aluno.altura == null) s.alunoPerfilFaltaCorpo,
    if (vazio(aluno.dataNascimento)) s.alunoPerfilFaltaNascimento,
  ].take(3).toList();
  if (itens.isEmpty) return '';
  if (itens.length == 1) return itens.first;
  return '${itens.sublist(0, itens.length - 1).join(', ')} ${s.alunoPerfilFaltaE} ${itens.last}';
}
