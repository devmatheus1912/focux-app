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

    test('strips markdown and rewrites contate imediatamente', () {
      expect(
        sanitizeTimeline360Copy(
          'Oi, Beatriz. **Contate Beatriz imediatamente** para retomar.',
        ),
        'Você sumiu do radar — me responde por aqui que eu ajusto o plano.',
      );
      expect(
        sanitizeTimeline360Copy(
          'Oi, Beatriz. **Contate Beatriz imediatamente** para retomar.',
        ),
        isNot(contains('**')),
      );
    });
  });

  group('timeline360ChatPreviewBody', () {
    test('drops redundant Oi greeting in chat preview', () {
      expect(
        timeline360ChatPreviewBody(
          'Oi, Beatriz. Como foi seu último treino?',
          alunoFirstName: 'Beatriz',
        ),
        'Como foi seu último treino?',
      );
    });
  });

  group('timeline360KindHeader', () {
    test('merges chat sender into kind header', () {
      expect(
        timeline360KindHeader(
          kind: 'Chat',
          title: 'Chat · Personal',
          meta: 'PERSONAL',
        ),
        'Chat · Personal',
      );
    });
  });

  group('timeline360ShowTitleRow', () {
    test('hides title row for chat', () {
      expect(
        timeline360ShowTitleRow(
          kind: 'Chat',
          title: 'Chat · Personal',
          meta: 'PERSONAL',
        ),
        isFalse,
      );
    });

    test('shows title row for radar', () {
      expect(
        timeline360ShowTitleRow(
          kind: 'Radar',
          title: 'Radar Focux · 19 pts',
          meta: 'Completar mapa corporal',
        ),
        isTrue,
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
}
