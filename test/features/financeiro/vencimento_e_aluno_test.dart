import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/financeiro/utils/vencimento_atalhos.dart';
import 'package:focux_app/features/financeiro/widgets/dia_vencimento_grade.dart';
import 'package:focux_app/features/financeiro/widgets/financeiro_aluno_etapa.dart';
import 'package:focux_app/features/financeiro/widgets/vencimento_escolha.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
    useMaterial3: true,
  ),
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: child),
);

Aluno _aluno(int id, String nome) =>
    Aluno(id: id, nome: nome, email: '$id@t.com', status: 'ATIVO');

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('vencimentoAtalhos', () {
    final hoje = DateTime(2026, 10, 27);

    test('mês corrente: Hoje, Dia 5, Dia 10 e Fim do mês', () {
      final a = vencimentoAtalhos(
        mesReferencia: DateTime(2026, 10, 1),
        hoje: hoje,
      );
      expect(a.map((e) => e.rotulo), ['Hoje', 'Dia 5', 'Dia 10', 'Fim do mês']);
      expect(a.last.data, DateTime(2026, 10, 31));
    });

    test('outro mês não oferece "Hoje"', () {
      final a = vencimentoAtalhos(
        mesReferencia: DateTime(2026, 11, 1),
        hoje: hoje,
      );
      expect(a.map((e) => e.rotulo), ['Dia 5', 'Dia 10', 'Fim do mês']);
    });

    test('fevereiro: fim do mês é o dia 28 (e 29 em ano bissexto)', () {
      expect(
        vencimentoAtalhos(
          mesReferencia: DateTime(2027, 2, 1),
          hoje: hoje,
        ).last.data,
        DateTime(2027, 2, 28),
      );
      expect(
        vencimentoAtalhos(
          mesReferencia: DateTime(2028, 2, 1),
          hoje: hoje,
        ).last.data,
        DateTime(2028, 2, 29),
      );
    });

    test('atraso: data passada avisa quantos dias', () {
      expect(vencimentoEntraAtrasado(DateTime(2026, 10, 10), hoje), isTrue);
      expect(vencimentoEntraAtrasado(DateTime(2026, 10, 27), hoje), isFalse);
      expect(
        vencimentoAvisoAtraso(DateTime(2026, 10, 26), hoje),
        'Vai entrar como atrasada (venceu ontem).',
      );
      expect(
        vencimentoAvisoAtraso(DateTime(2026, 10, 10), hoje),
        'Vai entrar como atrasada (venceu há 17 dias).',
      );
    });
  });

  group('folha de vencimento', () {
    Future<DateTime?> abrir(
      WidgetTester tester, {
      required DateTime atual,
    }) async {
      DateTime? resultado;
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => TextButton(
                  onPressed: () async {
                    resultado = await showVencimentoSheet(
                      context,
                      mesReferencia: DateTime(2026, 10, 1),
                      atual: atual,
                      hoje: DateTime(2026, 10, 27),
                    );
                  },
                  child: const Text('abrir'),
                ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      return resultado;
    }

    testWidgets('atalho escolhe e fecha', (tester) async {
      await abrir(tester, atual: DateTime(2026, 10, 27));
      expect(find.text('Vencimento'), findsOneWidget);
      expect(find.text('Dia 10'), findsOneWidget);
      await tester.tap(find.text('Dia 10'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Vencimento'), findsNothing);
    });

    testWidgets('data passada avisa que entra como atrasada', (tester) async {
      await abrir(tester, atual: DateTime(2026, 10, 10));
      expect(find.textContaining('Vai entrar como atrasada'), findsOneWidget);
    });

    testWidgets('data futura não avisa', (tester) async {
      await abrir(tester, atual: DateTime(2026, 11, 5));
      expect(find.textContaining('Vai entrar como atrasada'), findsNothing);
    });
  });

  group('grade do dia do vencimento', () {
    testWidgets('mostra 1 a 31, marca o escolhido e responde ao toque', (
      tester,
    ) async {
      int? escolhido;
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          DiaVencimentoGrade(
            selecionado: 7,
            maximo: 31,
            hoje: DateTime(2026, 10, 27),
            onPick: (d) => escolhido = d,
          ),
        ),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      await tester.tap(find.text('15'));
      expect(escolhido, 15);
    });

    testWidgets('dia selecionado é lido pelo leitor de tela', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          DiaVencimentoGrade(
            selecionado: 7,
            maximo: 28,
            hoje: DateTime(2026, 10, 27),
            onPick: (_) {},
          ),
        ),
      );
      final no = tester.getSemantics(find.bySemanticsLabel('Dia 7'));
      // ignore: deprecated_member_use
      expect(no.hasFlag(SemanticsFlag.isSelected), isTrue);
      // ignore: deprecated_member_use
      expect(no.hasFlag(SemanticsFlag.isButton), isTrue);
      handle.dispose();
    });
  });

  group('etapa de escolher aluno (sem folha por cima de folha)', () {
    testWidgets('busca filtra, toque escolhe, voltar volta', (tester) async {
      Aluno? escolhido;
      var voltou = 0;
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          FinanceiroAlunoEtapa(
            alunos: [
              _aluno(1, 'Hugo'),
              _aluno(2, 'guilherme -'),
              _aluno(3, 'Higor Muniz'),
            ],
            selecionadoId: 1,
            onPick: (a) => escolhido = a,
            onVoltar: () => voltou++,
          ),
        ),
      );
      // o traço solto do nome não aparece
      expect(find.text('Guilherme'), findsOneWidget);
      expect(find.text('guilherme -'), findsNothing);

      await tester.enterText(find.byType(TextField), 'hig');
      await tester.pump();
      expect(find.text('Higor Muniz'), findsOneWidget);
      expect(find.text('Hugo'), findsNothing);

      await tester.tap(find.text('Higor Muniz'));
      expect(escolhido?.id, 3);

      await tester.tap(find.byTooltip('Voltar'));
      expect(voltou, 1);
    });

    testWidgets('sem resultado, diz que não achou', (tester) async {
      await tester.pumpWidget(
        _app(
          FinanceiroAlunoEtapa(
            alunos: [_aluno(1, 'Hugo')],
            selecionadoId: null,
            onPick: (_) {},
            onVoltar: () {},
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('Nenhum aluno encontrado.'), findsOneWidget);
    });
  });
}
