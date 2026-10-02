import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';
import 'package:focux_app/features/feed/widgets/feed_comments_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';

class _FakeFeedRepo implements FeedRepository {
  final denunciados = <int>[];
  final bloqueados = <int>[];
  final apagados = <int>[];

  @override
  Future<Pagina<FeedComentario>> listarComentarios(
    int postId, {
    String? cursor,
  }) async {
    return Pagina(
      hasNext: false,
      content: [
        FeedComentario(id: 1, alunoId: 7, alunoNome: 'Eu', texto: 'meu', criadoEm: ''),
        FeedComentario(id: 2, alunoId: 8, alunoNome: 'Outro', texto: 'chato', criadoEm: ''),
        FeedComentario(id: 3, alunoId: 8, alunoNome: 'Outro', texto: 'de novo', criadoEm: ''),
      ],
    );
  }

  @override
  Future<void> denunciarComentario(int comentarioId) async => denunciados.add(comentarioId);

  @override
  Future<void> bloquearAluno(int alunoId) async => bloqueados.add(alunoId);

  @override
  Future<void> apagarComentario(int comentarioId) async => apagados.add(comentarioId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(FeedRepository repo, {int? alunoId, bool canCompose = true}) {
  return MaterialApp(
    locale: const Locale('pt'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: FeedCommentsSheet(
        postId: 100,
        repo: repo,
        currentAlunoId: alunoId,
        canCompose: canCompose,
        onComentou: (_) {},
      ),
    ),
  );
}

Future<void> _confirmar(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aluno: no próprio comentário só pode apagar', (tester) async {
    await tester.pumpWidget(_app(_FakeFeedRepo(), alunoId: 7));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opções do comentário').first);
    await tester.pumpAndSettle();

    expect(find.text('Apagar comentário'), findsOneWidget);
    expect(find.text('Denunciar comentário'), findsNothing);
  });

  testWidgets('aluno denuncia comentário de outro e ele some', (tester) async {
    final repo = _FakeFeedRepo();
    await tester.pumpWidget(_app(repo, alunoId: 7));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opções do comentário').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denunciar comentário'));
    await tester.pumpAndSettle();
    await _confirmar(tester, 'Denunciar comentário');

    expect(repo.denunciados, [2]);
    expect(find.text('chato'), findsNothing);
    expect(find.text('de novo'), findsOneWidget);
  });

  testWidgets('bloquear esconde todos os comentários do autor', (tester) async {
    final repo = _FakeFeedRepo();
    await tester.pumpWidget(_app(repo, alunoId: 7));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opções do comentário').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear Outro'));
    await tester.pumpAndSettle();
    await _confirmar(tester, 'Bloquear Outro');

    expect(repo.bloqueados, [8]);
    expect(find.text('chato'), findsNothing);
    expect(find.text('de novo'), findsNothing);
    expect(find.text('meu'), findsOneWidget);
  });

  testWidgets('personal apaga qualquer comentário', (tester) async {
    final repo = _FakeFeedRepo();
    await tester.pumpWidget(_app(repo, canCompose: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Opções do comentário').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar comentário'));
    await tester.pumpAndSettle();
    await _confirmar(tester, 'Apagar comentário');

    expect(repo.apagados, [2]);
    expect(find.text('chato'), findsNothing);
  });
}
