import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/widgets/sessoes_sem_uso_aviso.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends TreinoRepository {
  _Repo(this.total, {this.falhar = false}) : super(ApiClient());

  int total;
  final bool falhar;
  var arquivamentos = 0;

  @override
  Future<int> contarSessoesSemUso() async => total;

  @override
  Future<int> arquivarSessoesSemUso() async {
    arquivamentos++;
    if (falhar) throw Exception('falhou');
    final arquivadas = total;
    total = 0;
    return arquivadas;
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<_Repo> _abrir(WidgetTester tester, int total, {bool falhar = false}) async {
  final repo = _Repo(total, falhar: falhar);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [treinoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: const Scaffold(body: SessoesSemUsoAviso()),
      ),
    ),
  );
  await _settle(tester);
  return repo;
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('sem sobras o aviso não aparece', (tester) async {
    await _abrir(tester, 0);
    expect(find.textContaining('sem aluno'), findsNothing);
    expect(find.text('Limpar'), findsNothing);
  });

  testWidgets('mostra a contagem no singular e no plural', (tester) async {
    await _abrir(tester, 1);
    expect(find.text('1 sessão vazia sem aluno'), findsOneWidget);

    await _abrir(tester, 3);
    expect(find.text('3 sessões vazias sem aluno'), findsOneWidget);
  });

  testWidgets('cancelar a confirmação não arquiva nada', (tester) async {
    final repo = await _abrir(tester, 3);
    await tester.tap(find.text('3 sessões vazias sem aluno'));
    await _settle(tester);

    expect(find.text('Limpar sessões sem uso?'), findsOneWidget);
    expect(find.textContaining('Nada é apagado de verdade'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await _settle(tester);

    expect(repo.arquivamentos, 0);
    expect(find.text('3 sessões vazias sem aluno'), findsOneWidget);
  });

  testWidgets('confirmar arquiva, avisa e o aviso some', (tester) async {
    final repo = await _abrir(tester, 3);
    await tester.tap(find.text('3 sessões vazias sem aluno'));
    await _settle(tester);
    await tester.tap(find.text('Limpar').last);
    await _settle(tester);

    expect(repo.arquivamentos, 1);
    expect(find.text('3 sessões arquivadas'), findsOneWidget);
    expect(find.text('3 sessões vazias sem aluno'), findsNothing);
  });

  testWidgets('se falhar, avisa o erro e mantém o aviso', (tester) async {
    final repo = await _abrir(tester, 2, falhar: true);
    await tester.tap(find.text('2 sessões vazias sem aluno'));
    await _settle(tester);
    await tester.tap(find.text('Limpar').last);
    await _settle(tester);

    expect(repo.arquivamentos, 1);
    expect(find.text('2 sessões arquivadas'), findsNothing);
    expect(find.text('2 sessões vazias sem aluno'), findsOneWidget);
  });
}
