import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';
import 'package:focux_app/features/evolucao/widgets/escolher_exercicio_campo.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_recordes_aba.dart';
import 'package:focux_app/features/evolucao/widgets/registrar_carga_folha.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

RecordePessoal _r(int id, String data, double kg, {int? reps = 10}) => RecordePessoal(
  id: id,
  exercicioId: 7,
  exercicioNome: 'Abdominal bicicleta',
  data: data,
  cargaKg: kg,
  repeticoes: reps,
);

Widget _tela(Widget filho) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: filho),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('no mesmo dia só a maior carga entra no gráfico', () {
    final fora = registrosForaDoGrafico([
      _r(2, '2026-11-11', 20),
      _r(1, '2026-11-11', 10),
      _r(3, '2026-11-04', 15),
    ]);
    expect(fora, {1});
  });

  test('contexto: última e recorde do exercício, sem o registro em edição', () {
    final recordes = [_r(1, '2026-11-04', 20), _r(2, '2026-11-11', 12, reps: 8)];
    final ctx = contextoDaCarga(recordes, 'abdominal BICICLETA ');
    expect(ctx.ultima?.id, 2);
    expect(ctx.recorde, 20);
    expect(contextoDaCarga(recordes, 'Abdominal bicicleta', ignorarId: 1).recorde, 12);
    expect(contextoDaCarga(recordes, 'Supino').ultima, isNull);
  });

  test('prévia do recorde: só passando o recorde anterior', () {
    expect(ganhoDeRecorde(25, 20), 5);
    expect(ganhoDeRecorde(20, 20), isNull);
    expect(ganhoDeRecorde(25, null), isNull);
    expect(cargaValida(0.4), isFalse);
    expect(cargaValida(0.5), isTrue);
    expect(cargaValida(1000.5), isFalse);
  });

  testWidgets('registros: mês, data como título, etiquetas e "Registrar carga"', (tester) async {
    tester.view.physicalSize = const Size(390, 900) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final progresso = progressoDosRecordes([
      _r(2, '2026-11-11', 20),
      _r(1, '2026-11-11', 10),
    ]).single;
    ExercicioEscolhido? registrar;
    await tester.pumpWidget(
      _tela(
        Builder(
          builder:
              (context) => TextButton(
                onPressed:
                    () => abrirRegistrosDoExercicio(
                      context,
                      progresso,
                      onEditar: (_) {},
                      onExcluir: (_) {},
                      onRegistrar: (e) => registrar = e,
                    ),
                child: const Text('abrir'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Novembro de 2026'), findsOneWidget);
    expect(find.text('Melhor: 20,0 kg · 2 registros'), findsOneWidget);
    expect(find.text('11/11'), findsNWidgets(2));
    expect(find.text('20,0 kg × 10 reps'), findsOneWidget);
    expect(find.text('Recorde'), findsOneWidget);
    expect(find.text('Não entra no gráfico'), findsOneWidget);

    await tester.tap(find.text('Registrar carga'));
    await tester.pumpAndSettle();
    expect(registrar?.nome, 'Abdominal bicicleta');
    expect(registrar?.id, 7);
  });

  testWidgets('registros do aluno: sem toque e sem rodapé', (tester) async {
    final progresso = progressoDosRecordes([_r(1, '2026-11-11', 20)]).single;
    await tester.pumpWidget(
      _tela(
        Builder(
          builder:
              (context) => TextButton(
                onPressed: () => abrirRegistrosDoExercicio(context, progresso),
                child: const Text('abrir'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar carga'), findsNothing);
  });

  testWidgets('registrar carga: parte da última, mostra o contexto e a prévia do recorde', (tester) async {
    tester.view.physicalSize = const Size(390, 1000) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    CargaRegistrada? salvo;
    await tester.pumpWidget(
      _tela(
        Builder(
          builder:
              (context) => TextButton(
                onPressed: () async {
                  salvo = await abrirRegistrarCarga(
                    context,
                    recordes: [_r(1, '2026-11-04', 20), _r(2, '2026-11-11', 20)],
                    exercicioInicial: (id: 7, nome: 'Abdominal bicicleta'),
                  );
                },
                child: const Text('abrir'),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Registrar carga'), findsOneWidget);
    expect(find.text('Última: 20,0 kg × 10 · Recorde: 20,0 kg'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.textContaining('Novo recorde'), findsNothing);

    await tester.tap(find.byTooltip('Aumentar kg'));
    await tester.pumpAndSettle();
    expect(find.text('21'), findsOneWidget);
    expect(find.textContaining('Novo recorde: +1,0'), findsOneWidget);

    await tester.tap(find.text('Ontem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(salvo?.carga, 21);
    expect(salvo?.repeticoes, 10);
    final hoje = DateUtils.dateOnly(DateTime.now());
    expect(salvo?.data, hoje.subtract(const Duration(days: 1)));
  });
}
