import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('conversation cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/chat/screens/conversation_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('_ConversationQuietEmpty'));
    expect(screen, contains('Envie a primeira mensagem'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('quiet: true'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/dashboard/aluno'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('showDialog')));
    expect(screen, contains('_showImageViewer'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('bolha de sistema tem peso próprio, sem cantos de chat humano', () {
    final widgets = readScreenSourceBundle(
      'lib/features/chat/widgets/conversation_message_widgets.dart',
    );
    expect(widgets, contains('this.system = false'));
    expect(widgets, contains('TokensStrip.rCard'));
    expect(widgets, contains("'Sistema'"));
    expect(widgets, contains('TokensStrip.pageBg'));
    expect(widgets, contains('FocuxHubTypography'));
    expect(widgets, isNot(contains('ConversationChatBackdropPainter')));
    expect(widgets, isNot(contains('Icons.done_all_rounded')));
    expect(widgets, isNot(contains('BorderRadius.only')));
    expect(widgets, isNot(contains('LinearGradient')));
  });

  test('compositor é card 48dp, sem send circular de messenger', () {
    final screen = readScreenSourceBundle(
      'lib/features/chat/screens/conversation_screen.dart',
    );
    expect(screen, contains('TokensStrip.rCard'));
    expect(screen, contains('const Size(48, 48)'));
    expect(screen, contains("hintText: 'Mensagem'"));
    expect(screen, isNot(contains('Icons.add_circle')));
    expect(screen, isNot(contains('BackdropFilter')));
    expect(screen, isNot(contains('ImageFilter.blur')));
    expect(screen, contains('const ConversationChatBackdrop()'));
  });
}
