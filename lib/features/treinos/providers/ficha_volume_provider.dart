import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ficha_volume.dart';
import 'ficha_modelos_provider.dart';
import 'treinos_provider.dart';

/// Volume semanal da ficha atual de um aluno.
final fichaVolumeProvider = FutureProvider.autoDispose.family<FichaVolume, int>(
  (ref, alunoId) => ref.watch(treinoRepositoryProvider).volumeDaFicha(alunoId),
);

/// Volume semanal de um modelo de ficha.
final modeloVolumeProvider = FutureProvider.autoDispose.family<FichaVolume, int>(
  (ref, modeloId) =>
      ref.watch(fichaModeloRepositoryProvider).volumeDoModelo(modeloId),
);
