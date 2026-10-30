import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:focux_app/features/notificacoes/notificacao_display.dart';
import 'package:focux_app/features/notificacoes/screens/notificacoes_screen.dart';
import 'package:google_fonts/google_fonts.dart';

NotificacaoApp _aviso(int id, {String titulo = 'Mensalidade de set/2026', String mensagem = 'R\$ 100,00', String tipo = 'INFO'}) =>
    NotificacaoApp(
      id: id,
      titulo: titulo,
      mensagem: mensagem,
      tipo: tipo,
      lida: false,
      criadaEm: DateTime.now(),
    );

class _Repo implements NotificacoesRepository {
  _Repo(this.items);

  final List<NotificacaoApp> items;
  final lidas = <int>[];

  @override
  Future<NotificacoesInbox> listar({int page = 0, int size = 30, String q = '', bool naoLidas = false}) async =>
      NotificacoesInbox(items: items, hasMore: false, page: 0, total: items.length);

  @override
  Future<int> totalNaoLidas() async => items.length;

  @override
  Future<NotificacaoApp> marcarLida(int id) async {
    lidas.add(id);
    return items.firstWhere((n) => n.id == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> abrir(WidgetTester tester, _Repo repo) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notificacoesRepositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(home: NotificacoesScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('avisos iguais: uma linha, contador da linha e abrir marca todos', (tester) async {
    final repo = _Repo([_aviso(1), _aviso(2), _aviso(3)]);
    await abrir(tester, repo);

    expect(find.text('Mensalidade de set/2026'), findsOneWidget);
    expect(find.text('Não lidas · 1'), findsOneWidget);

    await tester.tap(find.text('Mensalidade de set/2026'));
    await tester.pump();
    expect(repo.lidas..sort(), [1, 2, 3]);
    await tester.pumpAndSettle();
  });

  testWidgets('Radar: título é a ação e a segunda linha é o nome limpo', (tester) async {
    await abrir(
      tester,
      _Repo([
        _aviso(1, titulo: 'Radar Focux: guilherme -', mensagem: 'guilherme · mapa corporal', tipo: 'FOCUX_SCORE'),
      ]),
    );
    expect(find.text('Mapa corporal pendente'), findsOneWidget);
    expect(find.textContaining('Guilherme'), findsOneWidget);
    expect(find.textContaining('precisa de ação'), findsNothing);
  });

  test('número da tela: lista completa manda; senão, o servidor', () {
    expect(notificacaoNaoLidasDaTela(servidor: 22, naLista: 1, listaCompleta: true), 1);
    expect(notificacaoNaoLidasDaTela(servidor: 22, naLista: 1, listaCompleta: false), 22);
    expect(notificacaoNaoLidasDaTela(servidor: 22, naLista: null, listaCompleta: true), 22);
  });

  test('nome limpo', () {
    expect(notificacaoNomeLimpo('João -'), 'João');
    expect(notificacaoNomeLimpo('guilherme'), 'Guilherme');
    expect(notificacaoNomeLimpo('  Julio Cesar  '), 'Julio Cesar');
  });
}
