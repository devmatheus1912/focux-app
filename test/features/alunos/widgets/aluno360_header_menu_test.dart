import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_menu_acoes.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_composite_header.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_menu_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Aluno _aluno({bool contaAtiva = false, String status = 'ATIVO'}) => Aluno(
  id: 1,
  nome: 'Hugo Silva',
  email: 'hugo@x.com',
  status: status,
  contaAtiva: contaAtiva,
);

Widget _app(Widget home) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: home),
);

Future<void> _abrirCabecalho(
  WidgetTester tester, {
  VoidCallback? onMenu,
  VoidCallback? onChat,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    _app(
      Aluno360HeaderToolbar(
        displayName: 'Hugo',
        showTitle: false,
        ink: Colors.black,
        onBack: () {},
        onChat: onChat,
        onHelp: () {},
        onMenu: onMenu,
      ),
    ),
  );
}

/// Abre a folha do ⋮; [resultado] completa quando ela fecha.
class _Folha {
  Future<Aluno360MenuItem?>? resultado;
}

Future<_Folha> _abrirFolha(WidgetTester tester, Aluno aluno) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final folha = _Folha();
  await tester.pumpWidget(
    _app(
      Builder(
        builder:
            (context) => Center(
              child: ElevatedButton(
                onPressed:
                    () => folha.resultado = showAluno360MenuSheet(context, aluno),
                child: const Text('abrir'),
              ),
            ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return folha;
}

void main() {
  testWidgets('Chat é ação do cabeçalho, não está escondido em "Mais ações"', (
    tester,
  ) async {
    var chat = 0;
    await _abrirCabecalho(tester, onMenu: () {}, onChat: () => chat++);
    await tester.tap(find.byTooltip('Conversar com o aluno'));
    expect(chat, 1);
  });

  testWidgets('o ⋮ do cabeçalho é um botão de ícone, não um menu flutuante', (
    tester,
  ) async {
    var abriu = 0;
    await _abrirCabecalho(tester, onMenu: () => abriu++);
    expect(find.byType(PopupMenuButton<Object?>), findsNothing);
    expect(find.byType(PopupMenuItem<Object?>), findsNothing);
    final alvo = tester.getSize(find.byTooltip('Mais opções do aluno'));
    expect(alvo.width, greaterThanOrEqualTo(48));
    expect(alvo.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('Mais opções do aluno'));
    expect(abriu, 1);
  });

  testWidgets('não há lixeira solta no cabeçalho', (tester) async {
    await _abrirCabecalho(tester, onMenu: () {});
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    expect(find.byTooltip('Excluir aluno'), findsNothing);
  });

  test('os itens saem agrupados: link sempre presente, perigo por último', () {
    final itens = aluno360MenuItens(_aluno());
    expect(itens.first.acao, Aluno360MenuAcao.editar);
    expect(itens.last.acao, Aluno360MenuAcao.excluir);
    expect(
      itens.where((i) => i.acao == Aluno360MenuAcao.reenviarLink),
      hasLength(1),
    );
    expect(
      aluno360MenuItens(_aluno(contaAtiva: true))
          .where((i) => i.acao == Aluno360MenuAcao.reenviarLink),
      hasLength(1),
      reason: 'conta ativa também precisa do link (senha esquecida)',
    );
    final bloquear = itens.firstWhere(
      (i) => i.novoStatus == 'BLOQUEADO',
    );
    expect(bloquear.grupo, Aluno360MenuGrupo.perigo);
    final pausar = itens.firstWhere((i) => i.novoStatus == 'INATIVO');
    expect(pausar.grupo, Aluno360MenuGrupo.acesso);
  });

  testWidgets('a folha mostra os grupos e Excluir fica por último', (
    tester,
  ) async {
    await _abrirFolha(tester, _aluno());
    final textos = [
      'Cadastro',
      'Editar cadastro',
      'Criar tarefa',
      'Acesso',
      'Reenviar link de acesso',
      'Pausar aluno',
      'Zona de perigo',
      'Bloquear acesso',
      'Excluir aluno',
    ];
    var ultimoY = -1.0;
    for (final t in textos) {
      final y = tester.getTopLeft(find.text(t)).dy;
      expect(y, greaterThan(ultimoY), reason: t);
      ultimoY = y;
    }
  });

  testWidgets('conta ativa oferece link para nova senha', (tester) async {
    await _abrirFolha(tester, _aluno(contaAtiva: true));
    expect(find.text('Enviar link para nova senha'), findsOneWidget);
    expect(find.text('Reenviar link de acesso'), findsNothing);
  });

  testWidgets('tocar em Pausar devolve o status de destino', (tester) async {
    final folha = await _abrirFolha(tester, _aluno());
    await tester.tap(find.text('Pausar aluno'));
    await tester.pumpAndSettle();
    final item = await folha.resultado;
    expect(item?.acao, Aluno360MenuAcao.status);
    expect(item?.novoStatus, 'INATIVO');
  });

  testWidgets('tocar em Excluir devolve a ação sem confirmar na própria folha', (
    tester,
  ) async {
    final folha = await _abrirFolha(tester, _aluno());
    await tester.tap(find.text('Excluir aluno'));
    await tester.pumpAndSettle();
    final item = await folha.resultado;
    expect(item?.acao, Aluno360MenuAcao.excluir);
  });
}
