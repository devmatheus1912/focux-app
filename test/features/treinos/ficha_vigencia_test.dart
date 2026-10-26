import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_ficha_card.dart';
import 'package:focux_app/features/treinos/utils/ficha_vigencia.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final _hoje = DateTime(2026, 10, 24, 15, 30);

DateTime _daqui(int dias) => DateTime(2026, 10, 24).add(Duration(days: dias));

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('estado da vigência (espelha o backend)', () {
    test('sem fim não tem prazo', () {
      expect(estadoDaVigencia(null, hoje: _hoje), EstadoVigencia.semPrazo);
      expect(VigenciaFicha.semPrazo.temPrazo, isFalse);
      expect(VigenciaFicha.semPrazo.diasRestantes(_hoje), isNull);
    });

    test('estados pela distância do fim, com a fronteira de 7 dias', () {
      expect(estadoDaVigencia(_daqui(-1), hoje: _hoje), EstadoVigencia.vencida);
      expect(estadoDaVigencia(_daqui(0), hoje: _hoje), EstadoVigencia.venceHoje);
      expect(estadoDaVigencia(_daqui(1), hoje: _hoje), EstadoVigencia.venceEmBreve);
      expect(estadoDaVigencia(_daqui(7), hoje: _hoje), EstadoVigencia.venceEmBreve);
      expect(estadoDaVigencia(_daqui(8), hoje: _hoje), EstadoVigencia.emDia);
    });

    test('a hora do dia não muda a conta', () {
      final fimNoMeioDoDia = DateTime(2026, 10, 24, 23, 59);
      expect(diasAteOFim(fimNoMeioDoDia, DateTime(2026, 10, 24, 0, 1)), 0);
      expect(estadoDaVigencia(fimNoMeioDoDia, hoje: _hoje), EstadoVigencia.venceHoje);
    });

    test('dias restantes ficam negativos quando venceu', () {
      expect(VigenciaFicha(fim: _daqui(3)).diasRestantes(_hoje), 3);
      expect(VigenciaFicha(fim: _daqui(-5)).diasRestantes(_hoje), -5);
    });

    test('datas em texto', () {
      expect(dataCurta(DateTime(2026, 11, 3)), '03/11');
      expect(dataIso(DateTime(2026, 11, 3)), '2026-11-03');
    });
  });

  group('JSON da rotina', () {
    test('lê vigência e atualizadaEm', () {
      final fila = RotinaFila.fromJson({
        'itens': [],
        'vigencia': {'tipo': 'DATA', 'inicio': '2026-09-01', 'fim': '2026-11-30', 'estado': 'EM_DIA'},
        'atualizadaEm': '2026-10-20T10:15:00',
      });
      expect(fila.vigencia.fim, DateTime(2026, 11, 30));
      expect(fila.vigencia.inicio, DateTime(2026, 9, 1));
      expect(fila.atualizadaEm, DateTime(2026, 10, 20, 10, 15));
    });

    test('backend antigo, sem os campos, vira sem prazo e sem atualização', () {
      final fila = RotinaFila.fromJson({'itens': []});
      expect(fila.vigencia.temPrazo, isFalse);
      expect(fila.atualizadaEm, isNull);
    });

    test('vigência sem fim (nulo) é sem prazo', () {
      final fila = RotinaFila.fromJson({
        'itens': [],
        'vigencia': {'tipo': 'DATA', 'inicio': null, 'fim': null, 'estado': 'SEM_PRAZO'},
      });
      expect(fila.vigencia.temPrazo, isFalse);
    });
  });

  group('selo no cartão Ficha de treino do perfil 360', () {
    Future<void> abrir(WidgetTester tester, RotinaFila fila) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Aluno360FichaCard(alunoId: 3, alunoNome: 'Ana'),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [alunoRotinaProvider(3).overrideWith((ref) async => fila)],
          child: MaterialApp.router(
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
              useMaterial3: true,
            ),
            locale: const Locale('pt'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      );
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    RotinaFila comFim(DateTime? fim) => RotinaFila(
      itens: const [
        RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1),
      ],
      vigencia: VigenciaFicha(fim: fim),
    );

    testWidgets('perto de vencer: mostra o selo', (tester) async {
      await abrir(tester, comFim(DateTime.now().add(const Duration(days: 3))));
      expect(find.text('Vence em 3 dias'), findsOneWidget);
    });

    testWidgets('vencida: mostra há quantos dias', (tester) async {
      await abrir(tester, comFim(DateTime.now().subtract(const Duration(days: 4))));
      expect(find.text('Vencida há 4 dias'), findsOneWidget);
    });

    testWidgets('em dia e sem prazo: não chama atenção', (tester) async {
      await abrir(tester, comFim(DateTime.now().add(const Duration(days: 30))));
      expect(find.textContaining('Vence'), findsNothing);
      expect(find.textContaining('Vencida'), findsNothing);

      await abrir(tester, comFim(null));
      expect(find.textContaining('Vence'), findsNothing);
      expect(find.text('Sem prazo'), findsNothing);
    });
  });
}
