import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_menu_acoes.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_composite_header.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Aluno _aluno({bool contaAtiva = false}) => Aluno(
  id: 1,
  nome: 'Hugo Silva',
  email: 'hugo@x.com',
  status: 'ATIVO',
  contaAtiva: contaAtiva,
);

Future<void> _abrir(
  WidgetTester tester, {
  required List<Aluno360MenuItem> itens,
  required void Function(Aluno360MenuItem) onMenu,
  VoidCallback? onChat,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(
        body: Aluno360HeaderToolbar(
          displayName: 'Hugo',
          showTitle: false,
          ink: Colors.black,
          onBack: () {},
          onChat: onChat,
          onHelp: () {},
          menuItens: itens,
          onMenu: onMenu,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Chat é ação do cabeçalho, não está escondido em "Mais ações"', (tester) async {
    var chat = 0;
    await _abrir(
      tester,
      itens: aluno360MenuItens(_aluno()),
      onMenu: (_) {},
      onChat: () => chat++,
    );
    await tester.tap(find.byTooltip('Conversar com o aluno'));
    expect(chat, 1);
  });

  testWidgets('não há lixeira solta no cabeçalho', (tester) async {
    await _abrir(tester, itens: aluno360MenuItens(_aluno()), onMenu: (_) {});
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byTooltip('Excluir aluno'), findsNothing);
  });

  testWidgets('o ⋮ lista os itens na ordem e Excluir é o último', (tester) async {
    await _abrir(tester, itens: aluno360MenuItens(_aluno()), onMenu: (_) {});
    await tester.tap(find.byTooltip('Mais opções do aluno'));
    await tester.pumpAndSettle();
    final textos = [
      'Editar cadastro',
      'Criar tarefa',
      'Reenviar link de acesso',
      'Pausar aluno',
      'Bloquear acesso',
      'Excluir aluno',
    ];
    var ultimoY = -1.0;
    for (final t in textos) {
      final y = tester.getTopLeft(find.text(t)).dy;
      expect(y, greaterThan(ultimoY), reason: t);
      ultimoY = y;
    }
    expect(find.byType(PopupMenuDivider), findsNWidgets(2));
  });

  testWidgets('conta já ativa não oferece reenviar link', (tester) async {
    await _abrir(tester, itens: aluno360MenuItens(_aluno(contaAtiva: true)), onMenu: (_) {});
    await tester.tap(find.byTooltip('Mais opções do aluno'));
    await tester.pumpAndSettle();
    expect(find.text('Reenviar link de acesso'), findsNothing);
  });

  testWidgets('escolher Excluir entrega a ação ao dono da tela (que pede confirmação)', (tester) async {
    Aluno360MenuItem? escolhido;
    await _abrir(
      tester,
      itens: aluno360MenuItens(_aluno()),
      onMenu: (i) => escolhido = i,
    );
    await tester.tap(find.byTooltip('Mais opções do aluno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir aluno'));
    await tester.pumpAndSettle();
    expect(escolhido?.acao, Aluno360MenuAcao.excluir);
  });

  testWidgets('escolher Pausar entrega o status de destino', (tester) async {
    Aluno360MenuItem? escolhido;
    await _abrir(
      tester,
      itens: aluno360MenuItens(_aluno()),
      onMenu: (i) => escolhido = i,
    );
    await tester.tap(find.byTooltip('Mais opções do aluno'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pausar aluno'));
    await tester.pumpAndSettle();
    expect(escolhido?.novoStatus, 'INATIVO');
  });
}
