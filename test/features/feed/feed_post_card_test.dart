import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feed/data/feed_repository.dart';
import 'package:focux_app/features/feed/widgets/feed_post_card.dart';
import 'package:focux_app/l10n/app_localizations.dart';

FeedPost _post({bool fixado = false, String tipo = 'TEXTO'}) => FeedPost(
  id: 1,
  titulo: 'Treino de sábado',
  conteudo: 'Às 9h no parque.',
  tipoPost: tipo,
  autorNome: 'Ana Coach',
  fixado: fixado,
  criadoEm: DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
);

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: S.localizationsDelegates,
  supportedLocales: S.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('selos Fixado e Dica, tempo por extenso', (tester) async {
    await tester.pumpWidget(
      _app(
        FeedPostCard(
          post: _post(fixado: true, tipo: 'DICA'),
          index: 0,
          primary: Colors.teal,
          curtidas: 2,
          comentarios: 0,
          onComentar: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fixado'), findsOneWidget);
    expect(find.text('Dica'), findsOneWidget);
    expect(find.text('há 1 semana'), findsOneWidget);
    expect(find.text('Treino de sábado'), findsOneWidget);
    // Sem dono das ações, sem "⋯".
    expect(find.byTooltip('Mais opções'), findsNothing);
  });

  testWidgets('personal: o número de curtidas abre Quem curtiu', (
    tester,
  ) async {
    var abriu = false;
    var mais = false;
    await tester.pumpWidget(
      _app(
        FeedPostCard(
          post: _post(),
          index: 0,
          primary: Colors.teal,
          curtidas: 3,
          comentarios: 1,
          onComentar: () {},
          onQuemCurtiu: () => abriu = true,
          onMais: () => mais = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fixado'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Quem curtiu, 3'));
    await tester.tap(find.byTooltip('Mais opções'));
    expect(abriu, isTrue);
    expect(mais, isTrue);
  });
}
