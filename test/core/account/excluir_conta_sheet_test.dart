import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/account/excluir_conta_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:focux_app/l10n/app_localizations_pt.dart';
import 'package:google_fonts/google_fonts.dart';

class _Abertura {
  Future<ExcluirContaCredencial?>? resultado;
}

Future<_Abertura> _abrir(
  WidgetTester tester, {
  required ExcluirContaPapel papel,
  bool avisoAssinatura = false,
  double textScale = 1,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final abertura = _Abertura();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
      home: Scaffold(
        body: Builder(
          builder:
              (context) => Center(
                child: ElevatedButton(
                  onPressed:
                      () =>
                          abertura.resultado = showExcluirContaSheet(
                            context,
                            dio: Dio(),
                            papel: papel,
                            avisoAssinatura: avisoAssinatura,
                          ),
                  child: const Text('abrir'),
                ),
              ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return abertura;
}

void main() {
  final l10n = SPt();

  group('excluirContaPodeExcluir', () {
    test('exige EXCLUIR e a credencial do modo escolhido', () {
      expect(
        excluirContaPodeExcluir(
          senha: 'x',
          codigo: '',
          confirmacao: 'EXCLUIR',
          usarCodigo: false,
        ),
        isTrue,
      );
      expect(
        excluirContaPodeExcluir(
          senha: '',
          codigo: '12345',
          confirmacao: 'EXCLUIR',
          usarCodigo: true,
        ),
        isFalse,
        reason: 'o código tem 6 dígitos',
      );
      expect(
        excluirContaPodeExcluir(
          senha: '',
          codigo: '123456',
          confirmacao: 'EXCLUIR',
          usarCodigo: true,
        ),
        isTrue,
      );
      expect(
        excluirContaPodeExcluir(
          senha: 'x',
          codigo: '',
          confirmacao: 'excluir',
          usarCodigo: false,
        ),
        isFalse,
      );
    });
  });

  group('excluirContaConsequencias', () {
    test('aluno: dados, histórico, aviso ao personal e irreversível', () {
      final linhas = excluirContaConsequencias(l10n, ExcluirContaPapel.aluno);
      expect(linhas, hasLength(4));
      expect(linhas.last, 'Não dá para desfazer.');
    });

    test('personal avisa que os alunos perdem o acesso', () {
      final linhas = excluirContaConsequencias(
        l10n,
        ExcluirContaPapel.personal,
        avisoAssinatura: true,
      );
      expect(linhas, contains('Seus alunos perdem o acesso ao app na hora.'));
      expect(linhas, contains(l10n.excluirContaAvisoAssinatura));
      expect(linhas.last, 'Não dá para desfazer.');
    });
  });

  testWidgets('o aviso aparece inteiro, antes dos campos, e o botão começa '
      'desabilitado', (tester) async {
    await _abrir(tester, papel: ExcluirContaPapel.personal);
    expect(find.text('O que acontece'), findsOneWidget);
    expect(find.text('Seus alunos perdem o acesso ao app na hora.'),
        findsOneWidget);
    // ordem: o que acontece -> confirme que é você -> para finalizar
    final y1 = tester.getTopLeft(find.text('O que acontece')).dy;
    final y2 = tester.getTopLeft(find.text('Confirme que é você')).dy;
    final y3 = tester.getTopLeft(find.text('Para finalizar')).dy;
    expect(y1, lessThan(y2));
    expect(y2, lessThan(y3));
    final botao = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Excluir definitivamente'),
    );
    expect(botao.onPressed, isNull);
  });

  testWidgets('habilita só com senha e EXCLUIR, e devolve a credencial', (
    tester,
  ) async {
    final abertura = await _abrir(tester, papel: ExcluirContaPapel.aluno);
    await tester.enterText(find.widgetWithText(TextField, 'Senha atual'), 'segredo');
    await tester.pump();
    var botao = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Excluir definitivamente'),
    );
    expect(botao.onPressed, isNull, reason: 'falta digitar EXCLUIR');
    await tester.enterText(find.widgetWithText(TextField, 'Digite EXCLUIR'), 'EXCLUIR');
    await tester.pump();
    botao = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Excluir definitivamente'),
    );
    expect(botao.onPressed, isNotNull);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir definitivamente'));
    await tester.pumpAndSettle();
    final cred = await abertura.resultado;
    expect(cred?.senha, 'segredo');
    expect(cred?.confirmacao, 'EXCLUIR');
    expect(cred?.usarCodigo, isFalse);
  });

  testWidgets('Cancelar é botão e fecha sem credencial', (tester) async {
    final abertura = await _abrir(tester, papel: ExcluirContaPapel.aluno);
    expect(find.byType(TextButton), findsNothing);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(await abertura.resultado, isNull);
  });

  for (final escala in [1.0, 2.0]) {
    testWidgets('aguenta letra ${escala}x sem estourar', (tester) async {
      await _abrir(
        tester,
        papel: ExcluirContaPapel.personal,
        avisoAssinatura: true,
        textScale: escala,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Não dá para desfazer.'), findsOneWidget);
    });
  }
}
