import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/planos/data/plano_features_bff_cache.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

const _premium = PlanoFeatures(
  plano: SubscriptionPlan.PRO,
  financeiro: true,
  agenda: true,
  relatorios: true,
  whiteLabel: false,
  iaCopiloto: true,
  migracaoFoto: true,
);

const _free = PlanoFeatures(
  plano: SubscriptionPlan.FREE,
  financeiro: false,
  agenda: true,
  relatorios: false,
  whiteLabel: false,
  iaCopiloto: false,
  migracaoFoto: false,
);

DashboardHomeBundle _homeBundle(PlanoFeatures? planoFeatures) {
  return DashboardHomeBundle(
    personal: DashboardData(
      totalAlunos: 1,
      alunosAtivos: 1,
      planoAtual: planoFeatures?.plano.name ?? 'FREE',
      limiteAlunos: 3,
    ),
    commandCenter: CommandCenterData(
      agendaHoje: const [],
      alunosEmRisco: const [],
      alunosScore: const [],
      cobrancasPendentes: const [],
      autonomiaGargalos: const [],
      modoOperacao: const [],
      filaAcoes: const [],
    ),
    financeiro: FinanceiroDashboard(
      receitaMes: 0,
      receitaAcumulada: 0,
      ticketMedio: 0,
      totalInadimplentes: 0,
      previsaoReceita: 0,
      vencimentosProximos: const [],
      topAlunos: const [],
      evolucaoMensal: const [],
    ),
    planoFeatures: planoFeatures,
  );
}

class _RecordingPlanosRepository extends PlanosRepository {
  _RecordingPlanosRepository() : super(ApiClient());

  int cacheLoads = 0;
  int freshCalls = 0;
  PlanoFeatures? cached;
  PlanoFeatures freshResult = _free;
  Completer<PlanoFeatures?>? cacheDelay;
  Completer<PlanoFeatures>? freshDelay;

  @override
  Future<PlanoFeatures?> loadCachedPlanoFeatures() {
    cacheLoads++;
    if (cacheDelay != null) return cacheDelay!.future;
    return Future<PlanoFeatures?>.value(cached);
  }

  @override
  Future<PlanoFeatures> getPlanoFeaturesFresh({bool forAluno = false}) async {
    freshCalls++;
    if (freshDelay != null) return freshDelay!.future;
    return freshResult;
  }
}

PlanoFeaturesNotifier _notifierFor(PlanosRepository repo) {
  final container = ProviderContainer.test(
    overrides: [planosRepositoryProvider.overrideWithValue(repo)],
  );
  return container.read(planoFeaturesProvider.notifier);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
  });
  tearDown(() {
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
  });

  test(
    'bootstrap skips GET /planos/me when Home cache has fresh planoFeatures',
    () async {
      DashboardHomeClientCache.put(_homeBundle(_premium));
      final repo = _RecordingPlanosRepository();
      final notifier = _notifierFor(repo);

      await notifier.bootstrapped;

      expect(repo.freshCalls, 0);
      expect(repo.cacheLoads, 0);
      expect(notifier.state.value?.plano, SubscriptionPlan.PRO);
      expect(notifier.state.value?.financeiro, isTrue);
    },
  );

  test(
    'bootstrap still hits /planos/me when Home bundle has no planoFeatures',
    () async {
      DashboardHomeClientCache.put(_homeBundle(null));
      final repo = _RecordingPlanosRepository()..freshResult = _premium;
      final notifier = _notifierFor(repo);

      await notifier.bootstrapped;

      expect(repo.freshCalls, 1);
      expect(notifier.state.value?.plano, SubscriptionPlan.PRO);
    },
  );

  test('stale Home cache (past 90s TTL) does not skip /planos/me', () async {
    DashboardHomeClientCache.put(
      _homeBundle(_premium),
      now: DateTime.now().subtract(const Duration(seconds: 91)),
    );
    final repo = _RecordingPlanosRepository()..freshResult = _free;
    final notifier = _notifierFor(repo);

    await notifier.bootstrapped;

    expect(repo.freshCalls, 1);
    expect(notifier.state.value?.plano, SubscriptionPlan.FREE);
  });

  test(
    'local PlanosRepository cache does not sidecar GET /planos/me',
    () async {
      final repo = _RecordingPlanosRepository()
        ..cached = _premium.copyWithOperationalState(
          fromCache: true,
          cacheSavedAt: DateTime.now(),
        );
      final notifier = _notifierFor(repo);

      await notifier.bootstrapped;

      expect(notifier.state.value?.plano, SubscriptionPlan.PRO);
      expect(repo.freshCalls, 0);
    },
  );

  test('BFF cache seeds without GET /planos/me', () async {
    PlanoFeaturesBffCache.put(_premium);
    final repo = _RecordingPlanosRepository();
    final notifier = _notifierFor(repo);

    await notifier.bootstrapped;

    expect(repo.freshCalls, 0);
    expect(repo.cacheLoads, 0);
    expect(notifier.state.value?.plano, SubscriptionPlan.PRO);
  });

  test(
    'seedFromHome during in-flight bootstrap is not overwritten by /planos/me',
    () async {
      final repo = _RecordingPlanosRepository()
        ..freshDelay = Completer<PlanoFeatures>();
      final notifier = _notifierFor(repo);

      final done = notifier.bootstrapped;
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repo.freshCalls, 1);
      notifier.seedFromHome(_premium);

      repo.freshDelay!.complete(_free);
      await done;

      expect(notifier.state.value?.plano, SubscriptionPlan.PRO);
      expect(notifier.state.value?.financeiro, isTrue);
    },
  );

  test(
    'seedFromHome during cache load skips bootstrap /planos/me entirely',
    () async {
      final repo = _RecordingPlanosRepository()
        ..cacheDelay = Completer<PlanoFeatures?>();
      final notifier = _notifierFor(repo);

      final done = notifier.bootstrapped;
      await Future<void>.delayed(Duration.zero);
      expect(repo.cacheLoads, 1);
      notifier.seedFromHome(_premium);
      repo.cacheDelay!.complete(null);
      await done;

      expect(repo.freshCalls, 0);
      expect(notifier.state.value?.plano, SubscriptionPlan.PRO);
    },
  );
}
