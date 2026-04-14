import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/checkin_repository.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>(
  (ref) => CheckinRepository(ref.read(apiClientProvider)),
);

final meusTreinosProvider = FutureProvider<List<ExecucaoTreino>>((ref) async {
  return ref.read(checkinRepositoryProvider).meusTreinos();
});

final historicoCheckinProvider = FutureProvider<List<ExecucaoTreino>>((ref) async {
  return ref.read(checkinRepositoryProvider).historico();
});
