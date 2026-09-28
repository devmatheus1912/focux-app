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

final checkinPersonalHomeProvider = FutureProvider<CheckinPersonalHomeBundle>((
  ref,
) async {
  return ref.read(checkinRepositoryProvider).personalHome();
});
