import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_timeline_logic.dart';

void main() {
  group('sanitizeTimeline360Copy', () {
    test('translates legacy english radar narrativa to coach tone', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz needs human action today: complete body map.',
        ),
        contains('mapa corporal'),
      );
    });

    test('rewrites robotic narrativa to coach tone', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz precisa de uma ação humana hoje: completar mapa corporal.',
        ),
        'Beatriz ainda não completou o mapa corporal — vale cobrar hoje.',
      );
    });

    test('fixes acao without accent', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz precisa de uma acao humana hoje: completar mapa corporal.',
        ),
        'Beatriz ainda não completou o mapa corporal — vale cobrar hoje.',
      );
    });
  });

  group('timeline360ShouldShowMetaChip', () {
    test('hides PERSONAL remetente duplicate', () {
      expect(
        timeline360ShouldShowMetaChip(
          kind: 'Chat',
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
          kind: 'Radar',
          meta: 'Completar mapa corporal',
          priority: 'P0',
          title: 'Radar Focux · 19 pts',
        ),
        isTrue,
      );
    });
  });

  group('timeline360ShouldShowPriorityBadge', () {
    test('hides priority on chat events', () {
      expect(
        timeline360ShouldShowPriorityBadge(kind: 'Chat'),
        isFalse,
      );
    });

    test('shows priority on radar events', () {
      expect(
        timeline360ShouldShowPriorityBadge(kind: 'Radar'),
        isTrue,
      );
    });
  });

  group('timeline360SenderChipLabel', () {
    test('returns Personal for chat personal', () {
      expect(
        timeline360SenderChipLabel(
          kind: 'Chat',
          meta: 'PERSONAL',
          title: 'Chat · Personal',
        ),
        'Personal',
      );
    });
  });
}
