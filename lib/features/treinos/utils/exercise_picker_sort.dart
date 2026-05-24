import '../../exercicios/data/exercicio_repository.dart';

int compareExerciciosForPicker(
  Exercicio a,
  Exercicio b, {
  required Set<int> alreadyInTreinoIds,
}) {
  final aIn = alreadyInTreinoIds.contains(a.id);
  final bIn = alreadyInTreinoIds.contains(b.id);
  if (aIn != bIn) return aIn ? 1 : -1;

  if (a.favoritado != b.favoritado) return a.favoritado ? -1 : 1;
  if (a.curado != b.curado) return a.curado ? -1 : 1;

  final aVideo = a.hasPlayableMedia ? 1 : 0;
  final bVideo = b.hasPlayableMedia ? 1 : 0;
  if (aVideo != bVideo) return bVideo.compareTo(aVideo);

  return a.nomeDisplay.compareTo(b.nomeDisplay);
}

List<Exercicio> sortExerciciosForPicker(
  Iterable<Exercicio> items, {
  required Set<int> alreadyInTreinoIds,
}) {
  final list = items.toList()
    ..sort(
      (a, b) => compareExerciciosForPicker(
        a,
        b,
        alreadyInTreinoIds: alreadyInTreinoIds,
      ),
    );
  return list;
}
