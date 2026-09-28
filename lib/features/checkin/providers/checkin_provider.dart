import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/checkin_repository.dart';
import '../models/checkin_personal_home.dart';
import '../models/treino_previa.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(ref.read(apiClientProvider)),
);

/// Prescrição da ficha antes de iniciar (não abre sessão).
final treinoPreviaProvider = FutureProvider.autoDispose
    .family<TreinoPrevia, int>(
      (ref, treinoId) => ref.read(checkinRepositoryProvider).previa(treinoId),
    );

/// Relógio da execução (duração e descanso).
final checkinRelogioProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Emite quando o aparelho volta a ter alguma rede (reenvio da fila de séries).
final checkinConexaoVoltouProvider = Provider<Stream<void>>(
  (ref) => Connectivity().onConnectivityChanged
      .where((r) => r.any((c) => c != ConnectivityResult.none))
      .map((_) {}),
);

final checkinPersonalHomeProvider = FutureProvider<CheckinPersonalHomeBundle>((
  ref,
) async {
  return ref.read(checkinRepositoryProvider).personalHome();
});
