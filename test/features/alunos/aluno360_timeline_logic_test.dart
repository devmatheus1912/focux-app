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

    test('strips bang and collapses copilot follow-up template', () {
      expect(
        sanitizeTimeline360Copy(
          '! Passei pelo seu acompanhamento agora e o próximo passo para seu objetivo é: reforçar check-in.',
        ),
        'Próximo passo do plano: reforçar check-in.',
      );
    });

    test('rewrites copilot contate action to recovery coach tone', () {
      expect(
        sanitizeTimeline360Copy(
          '! Passei pelo seu acompanhamento agora e o próximo passo para seu objetivo é: Contate Beatriz para entender inatividade.',
        ),
        'Beatriz sumiu do radar — manda um oi direto hoje.',
      );
    });

    test('strips inactivity suffix from middle of message', () {
      expect(
        sanitizeTimeline360Copy(
          'Você sumiu do radar — me responde por aqui que eu ajusto o plano. para entender o motivo da inatividade e verificar se há algum interesse. Quer retomar?',
        ),
        'Você sumiu do radar — me responde por aqui que eu ajusto o plano. Quer retomar?',
      );
    });

    test('removes orphan inactivity suffix after radar rewrite', () {
      expect(
        sanitizeTimeline360Copy(
          'Você sumiu do radar — me responde por aqui que eu ajusto o plano. para entender o motivo da inatividade.',
        ),
        'Você sumiu do radar — me responde por aqui que eu ajusto o plano.',
      );
    });

    test('rewrites afastamento contact template', () {
      expect(
        sanitizeTimeline360Copy(
          'Entre em contato com Beatriz para entender o motivo do afastamento.',
        ),
        'Beatriz sumiu do radar — manda um oi direto hoje.',
      );
    });

    test('rewrites contate para entender inatividade', () {
      expect(
        sanitizeTimeline360Copy(
          'Contate Beatriz para entender os motivos de sua inatividade e incentivá-la.',
        ),
        'Beatriz sumiu do radar — manda um oi direto hoje.',
      );
    });

    test('fixes acao before humana fragment', () {
      expect(
        sanitizeTimeline360Copy('precisa de uma acao humana'),
        'precisa de atenção',
      );
    });
  });

  group('timeline360ChatBodyFingerprint', () {
    test('dedupes identical copilot messages', () {
      final a = timeline360ChatBodyFingerprint(
        '! Passei pelo seu acompanhamento agora e o próximo passo para seu objetivo é: reforçar check-in.',
      );
      final b = timeline360ChatBodyFingerprint(
        'Passei pelo seu acompanhamento agora e o próximo passo para seu objetivo é: reforçar check-in.',
      );
      expect(a, b);
    });

    test('buckets recovery variants', () {
      expect(
        timeline360ChatBodyFingerprint(
          'Você sumiu do radar — me responde por aqui que eu ajusto o plano.',
        ),
        'chat:recovery',
      );
      expect(
        timeline360ChatBodyFingerprint(
          'Beatriz sumiu do radar — manda um oi direto hoje.',
        ),
        'chat:recovery',
      );
    });

    test('buckets copilot contate action as recovery', () {
      expect(
        timeline360ChatBodyFingerprint(
          '! Passei pelo seu acompanhamento agora e o próximo passo para seu objetivo é: Contate Beatriz.',
        ),
        'chat:recovery',
      );
    });
  });

  group('timeline360BodyExpandable', () {
    test('uses lower threshold for chat preview', () {
      final body = 'A' * 80;
      expect(
        timeline360BodyExpandable(body, kind: 'Chat', previewBody: body),
        isTrue,
      );
      expect(timeline360BodyExpandable(body, kind: 'Radar'), isFalse);
    });
  });

  group('timeline360SheetTitle', () {
    test('avoids duplicate chat label', () {
      expect(
        timeline360SheetTitle(
          kind: 'Chat',
          title: 'Chat · Personal',
          meta: 'PERSONAL',
        ),
        'Chat · Personal',
      );
    });
  });

  group('dedupeChatTimelineByFingerprint', () {
    test('keeps one recovery chat', () {
      final items = ['Chat', 'Chat', 'Chat'];
      final bodies = [
        'Você sumiu do radar — me responde por aqui que eu ajusto o plano.',
        'Beatriz sumiu do radar — manda um oi direto hoje.',
        'Como foi seu último treino?',
      ];
      final deduped = dedupeChatTimelineByFingerprint(
        List.generate(3, (i) => i),
        kindOf: (i) => items[i],
        bodyOf: (i) => bodies[i],
      );
      expect(deduped, [0, 2]);
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
