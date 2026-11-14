import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_gates.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

import '../../support/riverpod_seeds.dart';

class _FakeAuth extends AuthNotifier {
  @override
  UserRole? get currentRole => UserRole.aluno;

  @override
  AuthStatus build() => AuthStatus.authenticated;
}

/// Conta quantas vezes a tela foi construída (a tela real carrega no initState).
class _Tela extends StatefulWidget {
  const _Tela(this.construcoes);

  final List<int> construcoes;

  @override
  State<_Tela> createState() => _TelaState();
}

class _TelaState extends State<_Tela> {
  @override
  void initState() {
    super.initState();
    widget.construcoes.add(1);
  }

  @override
  Widget build(BuildContext context) => const Text('tela dos hábitos');
}

Future<List<int>> _abrir(WidgetTester tester, SubscriptionPlan plano) async {
  final construcoes = <int>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seededPlanoFeatures(PlanoFeatures.fromJson({'plano': plano.name})),
        authProvider.overrideWith(_FakeAuth.new),
      ],
      child: MaterialApp(home: AppRouterGates.habitos(_Tela(construcoes))),
    ),
  );
  await tester.pump();
  return construcoes;
}

void main() {
  setUp(dashboardHomeClientCache.clear);
  tearDown(dashboardHomeClientCache.clear);

  testWidgets('bloqueado: a tela do aluno nem nasce (sem chamada à API)', (
    tester,
  ) async {
    final construcoes = await _abrir(tester, SubscriptionPlan.FREE);
    expect(construcoes, isEmpty);
    expect(find.text('tela dos hábitos'), findsNothing);
    expect(find.text('Hábitos não está disponível'), findsOneWidget);
    // A tela de aviso anima a entrada: deixa os timers terminarem.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('liberado: a tela nasce uma vez', (tester) async {
    final construcoes = await _abrir(tester, SubscriptionPlan.PRO);
    expect(construcoes, hasLength(1));
    expect(find.text('tela dos hábitos'), findsOneWidget);
  });

  test('gate de recurso pago fica na rota, nunca dentro da tela do aluno', () {
    final telas = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
          final p = f.path.replaceAll(r'\', '/');
          return p.contains('/screens/') &&
              p.contains('aluno') &&
              p.endsWith('.dart');
        });
    for (final f in telas) {
      expect(
        f.readAsStringSync(),
        isNot(contains('FeatureGate(')),
        reason: f.path,
      );
    }
    final rotas = File(
      'lib/core/router/app_router_aluno_routes.dart',
    ).readAsStringSync();
    for (final tela in [
      'AppRouterGates.habitos(const HabitosAlunoScreen())',
      'AppRouterGates.desafios(const DesafiosAlunoScreen())',
      'AppRouterGates.habitos(\n              HabitoDetailScreen(',
      'AppRouterGates.desafios(\n              DesafioDetailScreen(',
    ]) {
      expect(rotas, contains(tela));
    }
    expect(rotas, contains("capability: 'feedbackVideo'"));
    expect(rotas, contains("capability: 'recorrencia'"));
  });

  test('telas pagas do aluno tratam o erro de plano pela regra única', () {
    for (final p in [
      'lib/features/habitos/screens/habitos_aluno_screen.dart',
      'lib/features/desafios/screens/desafios_aluno_screen.dart',
      'lib/features/feedback/screens/aluno_feedback_video_screen.dart',
      'lib/features/recorrencia/screens/recorrencia_aluno_screen.dart',
    ]) {
      final src = File(p).readAsStringSync();
      expect(src, contains('alunoBarradoPeloPlano(_erroCarga)'), reason: p);
      expect(src, isNot(contains('_semRecurso')), reason: p);
    }
  });
}
