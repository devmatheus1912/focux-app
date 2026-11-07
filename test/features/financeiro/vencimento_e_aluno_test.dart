import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
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

    test('mês corrente: Hoje, Dia 5, 10, 15 e Último dia', () {
      final a = vencimentoAtalhos(
        mesReferencia: DateTime(2026, 10, 1),
        hoje: hoje,
      );
      expect(a.map((e) => e.rotulo), ['Hoje', 'Dia 5', 'Dia 10', 'Dia 15', 'Último dia']);
      expect(a.last.data, DateTime(2026, 10, 31));
    });

    test('outro mês não oferece "Hoje"', () {
      final a = vencimentoAtalhos(
        mesReferencia: DateTime(2026, 11, 1),
        hoje: hoje,
      );
      expect(a.map((e) => e.rotulo), ['Dia 5', 'Dia 10', 'Dia 15', 'Último dia']);
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

    testWidgets('atalho escolhe o dia e o botão confirma', (tester) async {
      await abrir(tester, atual: DateTime(2026, 10, 27));
      expect(find.text('Vencimento'), findsOneWidget);
      await tester.ensureVisible(find.text('Dia 10'));
      await tester.tap(find.text('Dia 10'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('Vence 10/10'), findsOneWidget);
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

  group('mês já lançado', () {
    Mensalidade m(int id, String ref, String status) => Mensalidade.fromJson({
      'id': id,
      'alunoId': 1,
      'alunoNome': 'Julio',
      'valor': '175.00',
      'mesReferencia': ref,
      'vencimento': ref.replaceFirst('-01', '-12'),
      'status': status,
    });

    test('lançado bloqueia; cancelado não; a própria mensalidade não conta', () {
      final occ = vencimentoMesesOcupados([
        m(1, '2026-11-01', 'PAGO'),
        m(2, '2026-10-01', 'CANCELADO'),
        m(3, '2026-12-01', 'PENDENTE'),
      ], ignorarId: 3);
      expect(occ['2026-11']!.bloqueia, isTrue);
      expect(occ['2026-11']!.rotulo, 'Já lançada · R\$ 175,00 · paga');
      expect(occ['2026-10']!.bloqueia, isFalse);
      expect(occ.containsKey('2026-12'), isFalse);
    });

    test('sugestão pula o mês ocupado e usa o dia da última cobrança', () {
      final doAluno = [m(1, '2026-11-01', 'PAGO')];
      final d = vencimentoSugerido(
        hoje: DateTime(2026, 11, 7),
        ocupados: vencimentoMesesOcupados(doAluno),
        dia: vencimentoDiaPreferido(doAluno),
      );
      expect(d, DateTime(2026, 12, 12));
    });

    testWidgets('na folha, o mês lançado aparece marcado e não responde ao toque', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      DateTime? resultado;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                resultado = await showVencimentoSheet(
                  context,
                  atual: DateTime(2026, 12, 12),
                  hoje: DateTime(2026, 11, 7),
                  ocupados: vencimentoMesesOcupados([m(1, '2026-11-01', 'PAGO')]),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Já lançada · R\$ 175,00 · paga'), findsOneWidget);
      await tester.tap(find.text('Novembro 2026'));
      await tester.pump();
      // Continua em dezembro.
      expect(find.textContaining('Vence 12/12'), findsOneWidget);
      await tester.ensureVisible(find.textContaining('Vence 12/12'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Vence 12/12'), warnIfMissed: true);
      await tester.pumpAndSettle();
      expect(resultado, DateTime(2026, 12, 12));
    });
  });
}
