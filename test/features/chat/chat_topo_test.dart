import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/features/chat/screens/conversation_screen.dart';
import 'package:focux_app/core/widgets/fx_shell_inset_owner.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
      'dentro do shell do aluno, o cabeçalho não soma a barra de status duas vezes',
      (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetPadding);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (ctx, _) => Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: Stack(fit: StackFit.expand, children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.zero,
                child: MediaQuery.removePadding(
                  context: ctx,
                  removeBottom: false,
                  child: const FxShellInsetOwner(
                    removeTopPadding: true,
                    child: ConversationScreen.aluno(),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    ]);
    await tester.pumpWidget(ProviderScope(child: MaterialApp.router(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    )));
    await tester.pump(const Duration(milliseconds: 800));
    final appBar = tester.getRect(find.byType(AppBar));
    // começa logo abaixo da barra de status (47 dp) e tem a altura do próprio
    // cabeçalho (64 dp com subtítulo), sem somar a barra de status de novo
    expect(appBar.top, 47);
    expect(appBar.height, lessThanOrEqualTo(64));
  });
}
