import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_timeline_logic.dart';

void main() {
  group('sanitizeTimeline360Copy', () {
    test('translates legacy english radar narrativa', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz needs human action today: complete body map.',
        ),
        'Beatriz precisa de uma ação humana hoje: completar mapa corporal.',
      );
    });

    test('fixes acao without accent', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz precisa de uma acao humana hoje: completar mapa corporal.',
        ),
        contains('ação'),
      );
    });
  });

  group('timeline360ShouldShowMetaChip', () {
    test('hides PERSONAL remetente duplicate', () {
      expect(
        timeline360ShouldShowMetaChip(
          meta: 'PERSONAL',
          priority: 'P3',
          title: 'Chat · Personal',
        ),
        isFalse,
      );
    });

    test('shows proxima acao meta for radar', () {
      expect(
        timeline360ShouldShowMetaChip(
          meta: 'Completar mapa corporal',
          priority: 'P0',
          title: 'Radar Focux · 19 pts',
        ),
        isTrue,
      );
    });
  });
}
