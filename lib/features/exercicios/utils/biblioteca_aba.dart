import '../data/exercicio_repository.dart';

enum BibliotecaAba { focux, meus }

bool videoFocuxIntocado(Exercicio exercicio) =>
    exercicio.isFocuxLibrary && !exercicio.isPersonalUpload;
