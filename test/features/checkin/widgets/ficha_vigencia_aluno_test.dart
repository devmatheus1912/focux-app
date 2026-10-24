import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/checkin/widgets/ficha_vigencia_aluno.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/utils/ficha_vigencia.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

final _hoje = DateTime(2026, 10, 24, 12);

RotinaFila _ficha({int? fimEmDias, DateTime? atualizadaEm, bool comTreino = true}) => RotinaFila(
  itens: [
    if (comTreino)
      const RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1),
  ],
  vigencia: VigenciaFicha(
    fim: fimEmDias == null ? null : DateTime(2026, 10, 24).add(Duration(days: fimEmDias)),
  ),
  atualizadaEm: atualizadaEm,
);

Future<void> _abrir(WidgetTester tester, RotinaFila rotina) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
        useMaterial3: true,
      ),
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(body: FichaVigenciaAluno(rotina: rotina, hoje: _hoje)),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('quando há algo a dizer', () {
    test('sem prazo e sem troca recente, nada', () {
      expect(temAvisoDaFicha(_ficha(), _hoje), isFalse);
    });

    test('com prazo, ou trocada há pouco, sim', () {
      expect(temAvisoDaFicha(_ficha(fimEmDias: 30), _hoje), isTrue);
      expect(temAvisoDaFicha(_ficha(atualizadaEm: _hoje.subtract(const Duration(hours: 5))), _hoje), isTrue);
    });

    test('ficha sem treino nunca avisa', () {
      expect(temAvisoDaFicha(_ficha(fimEmDias: 3, comTreino: false), _hoje), isFalse);
    });
  });

  group('selo "Ficha atualizada"', () {
    test('vale por 3 dias e some sozinho', () {
      expect(fichaAtualizadaRecentemente(_hoje.subtract(const Duration(days: 2, hours: 23)), _hoje), isTrue);
      expect(fichaAtualizadaRecentemente(_hoje.subtract(const Duration(days: 3)), _hoje), isFalse);
      expect(fichaAtualizadaRecentemente(null, _hoje), isFalse);
    });

    test('data no futuro (relógio diferente) não conta', () {
      expect(fichaAtualizadaRecentemente(_hoje.add(const Duration(hours: 1)), _hoje), isFalse);
    });
  });

  group('chips do aluno', () {
    testWidgets('em dia: "Ficha até 30/11"', (tester) async {
      await _abrir(tester, _ficha(fimEmDias: 37));
      expect(find.text('Ficha até 30/11'), findsOneWidget);
    });

    testWidgets('perto de vencer: aviso com os dias', (tester) async {
      await _abrir(tester, _ficha(fimEmDias: 7));
      expect(find.text('Sua ficha vence em 7 dias'), findsOneWidget);
      await _abrir(tester, _ficha(fimEmDias: 1));
      expect(find.text('Sua ficha vence amanhã'), findsOneWidget);
    });

    testWidgets('vence hoje', (tester) async {
      await _abrir(tester, _ficha(fimEmDias: 0));
      expect(find.text('Sua ficha vence hoje'), findsOneWidget);
    });

    testWidgets('vencida: aviso suave, sem alarme', (tester) async {
      await _abrir(tester, _ficha(fimEmDias: -3));
      expect(find.text('Sua ficha venceu. Fale com seu personal.'), findsOneWidget);
    });

    testWidgets('trocada há pouco: mostra o selo junto do prazo', (tester) async {
      await _abrir(tester, _ficha(fimEmDias: 30, atualizadaEm: _hoje.subtract(const Duration(days: 1))));
      expect(find.text('Ficha atualizada'), findsOneWidget);
      expect(find.textContaining('Ficha até'), findsOneWidget);
    });

    testWidgets('sem nada a dizer, não ocupa lugar', (tester) async {
      await _abrir(tester, _ficha());
      expect(find.byType(Chip), findsNothing);
      expect(tester.getSize(find.byType(FichaVigenciaAluno)).height, 0);
    });
  });

  test('a Home e a aba Treinos do aluno usam os chips', () {
    expect(
      File('lib/features/dashboard/screens/aluno_dashboard_screen.dart').readAsStringSync(),
      contains('FichaVigenciaAluno'),
    );
    expect(
      File('lib/features/checkin/widgets/sua_semana_rows.dart').readAsStringSync(),
      contains('FichaVigenciaAluno'),
    );
  });
}
