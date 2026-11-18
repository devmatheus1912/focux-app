import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Personal e aluno com o mesmo nome e o mesmo ícone (SPEC 10/11/2026).
void main() {
  for (final f in [
    'lib/features/feedback/screens/feedback_video_screen.dart',
    'lib/features/feedback/screens/aluno_feedback_video_screen.dart',
  ]) {
    test('$f: nome único e ícone de vídeo', () {
      final s = File(f).readAsStringSync();
      expect(s, contains('feedbackVideoNome'));
      expect(s, isNot(contains('FxIcons.ia')));
      expect(s, isNot(contains('Meus vídeos')));
    });
  }

  test('personal: busca só a partir de 6 e pedido pelo chat', () {
    final s = File(
      'lib/features/feedback/screens/feedback_video_screen.dart',
    ).readAsStringSync();
    expect(s, contains('feedbackVideoBuscaMinimo'));
    expect(s, contains("'draft': feedbackVideoPedidoRascunho"));
  });
}
