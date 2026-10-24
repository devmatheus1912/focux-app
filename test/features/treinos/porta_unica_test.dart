import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/create_treino_screen.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

String _resumo(RotinaFila fila) => resumoDaSemana(
  fila,
  nomesDosDias: _dias,
  palavraDescanso: 'Descanso',
);

String _fonte(String caminho) => File(caminho).readAsStringSync();

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('resumo da semana no perfil 360', () {
    test('mostra o que treina e o descanso, um dia depois do outro', () {
      final resumo = _resumo(
        const RotinaFila(
          itens: [
            RotinaItem(
              id: 1,
              tipo: RotinaItemTipo.treino,
              nome: 'Peito',
              diaSemana: 1,
            ),
            RotinaItem(
              id: 2,
              tipo: RotinaItemTipo.treino,
              nome: 'Costas',
              diaSemana: 2,
            ),
            RotinaItem(id: 3, tipo: RotinaItemTipo.descanso),
            RotinaItem(
              id: 4,
              tipo: RotinaItemTipo.treino,
              nome: 'Pernas',
              diaSemana: 4,
            ),
          ],
          diasAviso: {3, 5, 6, 7},
        ),
      );
      expect(
        resumo,
        'Seg Peito · Ter Costas · Qua descanso · Qui Pernas · '
        'Sex descanso · Sáb descanso · Dom descanso',
      );
    });

    test('dois treinos no mesmo dia aparecem juntos', () {
      final resumo = _resumo(
        const RotinaFila(
          itens: [
            RotinaItem(
              id: 1,
              tipo: RotinaItemTipo.treino,
              nome: 'Ombro',
              diaSemana: 5,
            ),
            RotinaItem(
              id: 2,
              tipo: RotinaItemTipo.treino,
              nome: 'Posterior',
              diaSemana: 5,
            ),
          ],
        ),
      );
      expect(resumo, contains('Sex Ombro + Posterior'));
    });

    test('ficha vazia não tem resumo', () {
      expect(_resumo(RotinaFila.vazia), isEmpty);
    });
  });

  group('uma porta só', () {
    test('a linha do perfil 360 se chama Ficha de treino', () {
      expect(_fonte('lib/l10n/app_pt.arb'), contains('"rotinaLinha": "Ficha de treino"'));
      expect(
        _fonte('lib/features/alunos/widgets/aluno360_detail_operacao_tab.dart'),
        contains('AlunoRotinaLinha('),
      );
    });

    test('o topo da lista de treinos do aluno não tem mais a linha Rotina', () {
      final lista = _fonte(
        'lib/features/treinos/screens/treinos_list_screen_state.part.dart',
      );
      expect(lista, isNot(contains('AlunoRotinaLinha')));
    });

    test('a lista do personal se chama Modelos de treino', () {
      expect(_fonte('lib/l10n/app_pt.arb'), contains('"treinosModelosTitulo": "Modelos de treino"'));
      final lista = _fonte(
        'lib/features/treinos/screens/treinos_list_screen_state.part.dart',
      );
      expect(lista, contains('treinosModelosTitulo'));
      expect(lista, isNot(contains("'Biblioteca'")));
    });
  });

  group('novo treino pede só o nome', () {
    Future<void> abrir(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            treinoRepositoryProvider.overrideWithValue(
              TreinoRepository(ApiClient()),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: EagleTokens.brandAccent,
              ),
              useMaterial3: true,
            ),
            locale: const Locale('pt'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            home: const CreateTreinoScreen(),
          ),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
    }

    testWidgets('objetivo, nível e descrição ficam atrás de Mais detalhes', (
      tester,
    ) async {
      await abrir(tester);

      expect(find.text('Nome do treino'), findsOneWidget);
      expect(find.text('Objetivo (opcional)'), findsNothing);
      expect(find.text('Nível'), findsNothing);
      expect(find.text('Descrição (opcional)'), findsNothing);

      await tester.tap(find.text('Mais detalhes'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      expect(find.text('Objetivo (opcional)'), findsOneWidget);
      expect(find.text('Nível'), findsOneWidget);
      expect(find.text('Descrição (opcional)'), findsOneWidget);
      expect(find.text('Mais detalhes'), findsNothing);
    });
  });
}
