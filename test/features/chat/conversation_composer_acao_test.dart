import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/chat/widgets/conversation_composer_acao.dart';
import 'package:focux_app/features/chat/widgets/conversation_composer_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
  ),
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: child)),
);

ConversationMessageComposer _composer({
  required bool comTexto,
  bool gravando = false,
  VoidCallback? onSendText,
  VoidCallback? onStartRecording,
}) {
  final texto = TextEditingController();
  final foco = FocusNode();
  addTearDown(texto.dispose);
  addTearDown(foco.dispose);
  return ConversationMessageComposer(
    isDark: false,
    uploading: false,
    composerHasText: comTexto,
    recordingAudio: gravando,
    textController: texto,
    composerFocus: foco,
    replySender: null,
    replyPreview: null,
    showReplyBar: false,
    recordDurationLabel: '0:03',
    onCloseReply: () {},
    onCancelRecording: () {},
    onSendRecording: () {},
    onAttach: () {},
    onEmoji: () {},
    onSendText: onSendText ?? () {},
    onStartRecording: onStartRecording ?? () {},
    onStopRecordingSend: () {},
  );
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('enviar: visual de 36dp, alvo de 48dp que responde na borda', (
    tester,
  ) async {
    var enviou = 0;
    await tester.pumpWidget(
      _app(_composer(comTexto: true, onSendText: () => enviou++)),
    );

    final alvo = find.byType(ConversationComposerAcao);
    expect(tester.getSize(alvo), const Size.square(48));
    final visual = find.descendant(of: alvo, matching: find.byType(Material));
    expect(
      tester.getSize(visual),
      const Size.square(conversationComposerAcaoVisual),
    );

    await tester.tapAt(tester.getTopLeft(alvo) + const Offset(2, 2));
    expect(enviou, 1);
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(enviou, 2);
  });

  testWidgets('anexar, emoji e barra de gravação têm alvo de 48dp', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_composer(comTexto: false, gravando: true)));

    final icones = [
      Icons.add_rounded,
      Icons.sentiment_satisfied_outlined,
      Icons.delete_outline_rounded,
      Icons.arrow_upward_rounded,
    ];
    for (final icone in icones) {
      final alvo = tester.getSize(find.widgetWithIcon(IconButton, icone));
      expect(alvo.width, greaterThanOrEqualTo(48), reason: '$icone');
      expect(alvo.height, greaterThanOrEqualTo(48), reason: '$icone');
    }
  });

  testWidgets('botões do compositor anunciam papel e rótulo', (tester) async {
    final semantics = tester.ensureSemantics();
    var gravou = false;
    await tester.pumpWidget(
      _app(_composer(comTexto: false, onStartRecording: () => gravou = true)),
    );

    expect(
      tester.getSemantics(find.byType(ConversationComposerAcao)),
      isSemantics(
        label: 'Gravar áudio',
        isButton: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await tester.tap(find.byType(ConversationComposerAcao));
    expect(gravou, isTrue);

    await tester.pumpWidget(_app(_composer(comTexto: false, gravando: true)));
    expect(
      tester.getSemantics(find.byType(ConversationComposerAcao)),
      isSemantics(label: 'Enviar áudio', isButton: true),
    );

    await tester.pumpWidget(_app(_composer(comTexto: true)));
    expect(
      tester.getSemantics(find.byType(ConversationComposerAcao)),
      isSemantics(label: 'Enviar mensagem', isButton: true),
    );
    expect(
      tester.getSemantics(find.widgetWithIcon(IconButton, Icons.add_rounded)),
      isSemantics(tooltip: 'Anexar', isButton: true),
    );
    expect(
      tester.getSemantics(
        find.widgetWithIcon(IconButton, Icons.sentiment_satisfied_outlined),
      ),
      isSemantics(tooltip: 'Inserir emoji', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('botão principal cumpre o alvo de toque do Android', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        ConversationComposerAcao(
          icon: Icons.arrow_upward_rounded,
          label: 'Enviar mensagem',
          color: EagleTokens.brandAccent,
          onPressed: () {},
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    semantics.dispose();
  });
}
