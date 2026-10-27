import '../data/exercicio_repository.dart';

/// O vídeo da biblioteca Focux é fixo: o personal vê, mas não troca nem
/// remove. Quem quer o próprio vídeo cria o seu exercício. O servidor aplica a
/// mesma regra (`BibliotecaClassificacao.focuxComVideoOficial`).
bool videoEditavel(Exercicio e) => !e.isFocuxLibrary || e.isPersonalUpload;

/// "(meu)": nome da cópia que o personal cria a partir de um exercício Focux.
String nomeDaCopia(String original) {
  final base = original.trim();
  return base.endsWith('(meu)') ? base : '$base (meu)';
}
