import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/bff_snapshot_cache.dart';
import '../../../core/auth/sessao_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/command_center_data.dart';
import '../data/dashboard_repository.dart';
import '../utils/aluno_dashboard_home_client_cache.dart';
import '../utils/dashboard_home_client_cache.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

/// Home BFF do personal (personal + command center + financeiro). TTL 90 s +
/// SWR em [dashboardHomeClientCache]. Não limpar o cache no dispose: invalidar
/// pós-login descartava o prefetch. Limpeza só no logout/troca de tenant.
final dashboardHomeProvider = FutureProvider<DashboardHomeBundle>(
  (ref) {
    ref.watch(sessaoProvider);
    return lerSnapshotBff(
      ref,
      dashboardHomeClientCache,
      () => ref.read(dashboardRepositoryProvider).getHome(),
    );
  },
);

/// Home BFF do aluno (`GET /api/dashboard/aluno/home`), TTL 60 s + SWR.
final alunoDashboardHomeProvider = FutureProvider<AlunoDashboardHomeBundle>(
  (ref) {
    ref.watch(sessaoProvider);
    return lerSnapshotBff(
      ref,
      alunoDashboardHomeClientCache,
      () => ref.read(dashboardRepositoryProvider).getAlunoHome(),
    );
  },
);

/// Aquece a Home do personal antes de navegar (Hoje pinta de uma ida só).
Future<void> prefetchPersonalDashboardHome(WidgetRef ref) async {
  try {
    await ref.read(dashboardHomeProvider.future);
  } catch (_) {
    // Melhor esforço: a Home busca de novo se falhar.
  }
}

/// Aquece a Home do aluno antes de navegar.
Future<void> prefetchAlunoDashboardHome(WidgetRef ref) async {
  try {
    await ref.read(alunoDashboardHomeProvider.future);
  } catch (_) {
    // Melhor esforço.
  }
}

/// Write do aluno que muda a Home: sem limpar o cache client, o provider
/// serviria o bundle antigo por até [alunoDashboardHomeClientCache.ttl].
void invalidateAlunoDashboardHome(WidgetRef ref) {
  alunoDashboardHomeClientCache.clear();
  ref.invalidate(alunoDashboardHomeProvider);
}

/// Personal: write que muda a Home (ex.: ler notificações → sino).
///
/// Único jeito de atualizar a Home: `invalidate` sozinho lê o cache do cliente
/// e devolve o dado velho por até 90 s.
void invalidatePersonalDashboardHome(WidgetRef ref) {
  dashboardHomeClientCache.clear();
  ref.invalidate(dashboardHomeProvider);
}

void invalidatePersonalDashboardHomeRef(Ref ref) {
  dashboardHomeClientCache.clear();
  ref.invalidate(dashboardHomeProvider);
}

/// Puxar para atualizar: busca o bundle novo sem apagar o atual (mantém o
/// ETag). Sem rede, lança antes de mexer no cache e a Home segue como estava.
Future<void> refreshAlunoDashboardHome(WidgetRef ref) async {
  final geracao = alunoDashboardHomeClientCache.geracao;
  final fresh = await ref.read(dashboardRepositoryProvider).getAlunoHome();
  if (fresh != null) {
    alunoDashboardHomeClientCache.put(fresh, geracao: geracao);
  } else {
    alunoDashboardHomeClientCache.revalidar();
  }
  ref.invalidate(alunoDashboardHomeProvider);
  await ref.read(alunoDashboardHomeProvider.future);
}

final commandCenterProvider = FutureProvider<CommandCenterData>((ref) async {
  ref.watch(sessaoProvider);
  return (await ref.watch(dashboardHomeProvider.future)).commandCenter;
});

/// Fatia do BFF aluno — badge de notificações sem rebuild do hub inteiro.
final alunoHomeNotificacoesSelectProvider = Provider<int>((ref) {
  return ref.watch(
    alunoDashboardHomeProvider.select(
      (async) => async.value?.notificacoesNaoLidas ?? 0,
    ),
  );
});

final alunoHomeChatUnreadSelectProvider = Provider<int>((ref) {
  return ref.watch(
    alunoDashboardHomeProvider.select(
      (async) => async.value?.chat.naoLidasDoPersonal ?? 0,
    ),
  );
});
