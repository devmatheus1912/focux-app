import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';
import 'package:focux_app/features/notificacoes/screens/notificacoes_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeRepo implements NotificacoesRepository {
  final apagadas = <int>[];

  final items = [
    NotificacaoApp(
      id: 1,
      titulo: 'Mensalidade paga',
      mensagem: 'Pix confirmado',
      tipo: 'INFO',
      lida: false,
      criadaEm: DateTime.now(),
    ),
    NotificacaoApp(
      id: 2,
      titulo: 'Novo post no feed',
      mensagem: 'Veja',
      tipo: 'INFO',
      lida: true,
      criadaEm: DateTime.now(),
    ),
  ];

  @override
  Future<NotificacoesInbox> listar({
    int page = 0,
    int size = 30,
    String q = '',
  }) async {
    final visiveis = items.where((n) => !apagadas.contains(n.id)).toList();
    return NotificacoesInbox(
      items: visiveis,
      hasMore: false,
      page: 0,
      total: visiveis.length,
    );
  }

  @override
  Future<int> totalNaoLidas() async =>
      items.where((n) => !n.lida && !apagadas.contains(n.id)).length;

  @override
  Future<void> apagar(int id) async => apagadas.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeRepo> pump(WidgetTester tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificacoesRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: NotificacoesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('filtro Não lidas esconde as lidas', (tester) async {
    await pump(tester);
    expect(find.text('Novo post no feed'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notificacoes-filtro-nao-lidas')));
    await tester.pumpAndSettle();

    expect(find.text('Novo post no feed'), findsNothing);
    expect(find.text('Mensalidade paga'), findsOneWidget);
  });

  testWidgets('arrastar apaga e Desfazer devolve sem chamar a API', (
    tester,
  ) async {
    final repo = await pump(tester);

    await tester.drag(find.text('Novo post no feed'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('Novo post no feed'), findsNothing);
    expect(find.text('Desfazer'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('Novo post no feed'), findsOneWidget);
    expect(repo.apagadas, isEmpty);
  });

  testWidgets('arrastar sem desfazer apaga no servidor', (tester) async {
    final repo = await pump(tester);

    await tester.drag(find.text('Novo post no feed'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(repo.apagadas, [2]);
    expect(find.text('Novo post no feed'), findsNothing);
  });
}
