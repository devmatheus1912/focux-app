import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_ferramentas_mini_sparkline.dart';
import 'package:focux_app/features/avaliacao/data/avaliacao_repository.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Override _ferramentasPlanoOverride() {
  final notifier = PlanoFeaturesNotifier(
    PlanosRepository(ApiClient()),
  );
  notifier.seedFromHome(PlanoFeatures.optimisticEnterprise);
  return planoFeaturesProvider.overrideWith((ref) => notifier);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });
  final aluno = Aluno(
    id: 42,
    nome: 'Beatriz Costa',
    email: 'beatriz@test.com',
    status: 'ATIVO',
    dataNascimento: '1998-04-12',
    altura: 1.65,
    aderenciaPercent: 0,
  );

  List<Map<String, dynamic>> aderenciaSemanaEndingToday() {
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) {
      final day = anchor.subtract(Duration(days: 6 - i));
      final iso =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return {'data': iso, 'checkins': i.isEven ? 1 : 0};
    });
  }

  Widget harness(Widget child) {
    return ProviderScope(
      overrides: [
        _ferramentasPlanoOverride(),
        alunoMedidasResumoProvider(42).overrideWith((ref) async => null),
        alunoAderenciaSemanalProvider(42).overrideWith(
          (ref) async => aderenciaSemanaEndingToday(),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 1200),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ferramentas tab exposes section headers and registrar actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Aluno360DetailFerramentasTab(
          aluno: aluno,
          alunoId: 42,
          isDark: false,
          primary: const Color(0xFF2563EB),
          perfilCompletion: 90,
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medidas'), findsOneWidget);
    expect(find.text('Idade'), findsOneWidget);
    expect(find.text('Altura'), findsOneWidget);
    expect(find.text('Pendente'), findsNWidgets(3));
    expect(find.text('Treino & evolução'), findsOneWidget);
    expect(find.text('Perfil & gestão'), findsOneWidget);
    expect(find.text('Gordura'), findsNothing);
    expect(find.text('Gordura corporal'), findsOneWidget);
    expect(find.text('Massa magra'), findsOneWidget);
    expect(find.text('IA Progresso'), findsOneWidget);
    expect(find.text('Aderência'), findsOneWidget);
    expect(find.byType(Aluno360FerramentasMiniSparkline), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('ferramentas tab shows complete measurements inset', (
    tester,
  ) async {
    final alunoCompleto = Aluno(
      id: 99,
      nome: 'Carla',
      email: 'carla@test.com',
      status: 'ATIVO',
      dataNascimento: '1990-02-10',
      altura: 1.70,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          _ferramentasPlanoOverride(),
          alunoMedidasResumoProvider(99).overrideWith(
            (ref) async => SnapshotAvaliacao(
              percGordura: 18.4,
              massaMuscular: 52.1,
            ),
          ),
          alunoAderenciaSemanalProvider(99).overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 1200)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Aluno360DetailFerramentasTab(
              aluno: alunoCompleto,
              alunoId: 99,
              isDark: false,
              primary: const Color(0xFF2563EB),
              perfilCompletion: 100,
              animateEntrance: false,
              onEntrancePlayed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medidas em dia'), findsOneWidget);
    expect(find.text('Gordura 18.4% · Massa magra 52.1 kg'), findsOneWidget);
    expect(find.text('Idade'), findsNothing);
  });
}
