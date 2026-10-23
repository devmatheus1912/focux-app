import '../data/exercicio_repository.dart';

enum BibliotecaAba { focux, meus }

bool exercicioNaAba(Exercicio exercicio, BibliotecaAba aba) {
  final focux = exercicio.isFocuxLibrary && !exercicio.isPersonalUpload;
  return aba == BibliotecaAba.focux ? focux : !focux;
}

bool videoFocuxIntocado(Exercicio exercicio) =>
    exercicio.isFocuxLibrary && !exercicio.isPersonalUpload;
