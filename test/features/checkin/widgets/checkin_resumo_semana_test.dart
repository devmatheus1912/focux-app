import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_week_strip.dart';
import 'package:focux_app/features/checkin/utils/checkin_resumo.dart';
import 'package:focux_app/features/checkin/widgets/checkin_resumo_view.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/l10n/app_localizations.dart';

/// Fim de treino: volume honesto, "Anotar cargas" e "Sua semana".
void main() {
  RotinaItem item(int id, String nome, int dia) => RotinaItem(
    id: id,
    tipo: RotinaItemTipo.treino,
    treinoId: id,
    nome: nome,
    diaSemana: dia,
  );
  final rotina = RotinaFila(
    itens: [item(1, 'A · Empurrar', 1), item(2, 'B · Puxar', 2), item(3, 'C · Pernas', 3)],
  );

  test('próximo da fila volta ao começo depois do último', () {
    expect(checkinProximoDaFila(rotina, 1), 'B · Puxar');
    expect(checkinProximoDaFila(rotina, 3), 'A · Empurrar');
    expect(checkinProximoDaFila(rotina, 99), isNull);
  });

  test('semana marca hoje como feito', () {
    final quarta = DateTime(2026, 11, 4, 20);
    final semana = checkinResumoSemana(
      rotina: rotina,
      historico: const [],
      treinoId: 3,
      hoje: quarta,
      meta: 5,
    )!;
    expect(semana.dias[2].estado, FxWeekDayState.concluido);
    expect(semana.feitos, 1);
    expect(semana.proximo, 'A · Empurrar');
  });

  Future<CheckinResumoAcao?> abrir(
    WidgetTester tester,
    CheckinResumo resumo, {
    CheckinResumoSemana? semana,
  }) async {
    CheckinResumoAcao? acao;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Builder(
          builder:
              (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    acao = await showCheckinResumo(
                      context,
                      resumo: resumo,
                      semana: semana,
                    );
                  },
                  child: const Text('abrir'),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    return acao;
  }

  testWidgets('maioria sem carga: troca o volume por "Com carga"', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await abrir(
      tester,
      const CheckinResumo(
        treinoNome: 'C · Pernas',
        seriesFeitas: 12,
        seriesPlanejadas: 12,
        volumeKg: 160,
        seriesSemCarga: 11,
      ),
      semana: (
        dias: const [
          FxWeekDay(dia: 1, estado: FxWeekDayState.concluido),
          FxWeekDay(dia: 2, estado: FxWeekDayState.concluido),
          FxWeekDay(dia: 3, estado: FxWeekDayState.concluido, hoje: true),
          FxWeekDay(dia: 4, estado: FxWeekDayState.descanso),
          FxWeekDay(dia: 5, estado: FxWeekDayState.descanso),
          FxWeekDay(dia: 6, estado: FxWeekDayState.descanso),
          FxWeekDay(dia: 7, estado: FxWeekDayState.descanso),
        ],
        feitos: 3,
        meta: 5,
        proximo: 'A · Empurrar',
      ),
    );
    expect(find.text('160 kg'), findsNothing);
    expect(find.text('Com carga'), findsOneWidget);
    expect(find.text('1 de 12'), findsOneWidget);
    expect(find.text('Sua semana'), findsOneWidget);
    expect(find.text('3 de 5 treinos · Próximo: A · Empurrar'), findsOneWidget);
    expect(find.text('Anotar cargas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
