import '../data/exercicio_repository.dart';

bool videoFocuxIntocado(Exercicio exercicio) =>
    exercicio.isFocuxLibrary && !exercicio.isPersonalUpload;
