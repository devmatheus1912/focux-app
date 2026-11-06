import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/aluno360_client_cache.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../evolucao/utils/evolucao_home_client_cache.dart';
import '../data/checkin_repository.dart';
import '../utils/checkin_series_fila.dart';
import '../models/checkin_personal_home.dart';
import '../models/treino_previa.dart';

/// Uma sessão de treino mudou o estado do aluno (concluiu, confirmou sem séries
/// ou a fila offline sincronizou). Único lugar que lista o que fica velho depois
/// de um check-in: Evolução, 360 e a Home do aluno.
void checkinSessaoMudou(WidgetRef ref) {
  EvolucaoHomeClientCache.clear();
  Aluno360ClientCache.clear();
  invalidateAlunoDashboardHome(ref);
}

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

/// Token ainda no aparelho. O `SessionInvalidator` apaga o token antes do
/// 401 final chegar à tela.
final checkinSessaoAtivaProvider = Provider<CheckinSessaoAtiva>(
  (ref) => () async => await SecureStorage.getToken() != null,
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
