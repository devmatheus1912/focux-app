import 'package:flutter/material.dart';
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
        'Beatriz ainda não completou o mapa corporal — vale lembrar hoje.',
      );
    });

    test('fixes acao without accent', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz precisa de uma acao humana hoje: completar mapa corporal.',
        ),
        'Beatriz ainda não completou o mapa corporal — vale lembrar hoje.',
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
        'Vale reforçar o check-in com o aluno esta semana.',
      );
    });

    test('collapses copilot without colon action segment', () {
      expect(
        sanitizeTimeline360Copy(
          '! Passei pelo seu acompanhamento agora.',
        ),
        'Acompanhamento registrado — revise o próximo passo no chat.',
      );
    });

    test('collapses copilot after chat formatters', () {
      expect(
        sanitizeTimeline360Copy(
          '**! Passei pelo seu acompanhamento agora** e o proximo passo para seu objetivo é: reforçar check-in.',
        ),
        'Vale reforçar o check-in com o aluno esta semana.',
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
      expect(a, 'chat:copilot_acompanhamento');
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
      final body = 'A' * 105;
      expect(
        timeline360BodyExpandable(body, kind: 'Chat', previewBody: body),
        isTrue,
      );
      expect(timeline360BodyExpandable(body, kind: 'Radar'), isFalse);
    });

    test('expands chat near two-line limit', () {
      final body = 'A' * 73;
      expect(
        timeline360BodyExpandable(body, kind: 'Chat', previewBody: body),
        isTrue,
      );
    });

    test('expands when preview is shorter than full body', () {
      const preview = 'Como foi seu último treino?';
      const full =
          '$preview Me manda carga, repetições e qualquer sensação fora do normal.';
      expect(
        timeline360BodyExpandable(full, kind: 'Chat', previewBody: preview),
        isTrue,
      );
    });
  });

  group('legacy radar copy', () {
    test('rewrites vale cobrar to vale lembrar', () {
      expect(
        sanitizeTimeline360Copy(
          'Beatriz ainda não completou o mapa corporal — vale cobrar hoje.',
        ),
        'Beatriz ainda não completou o mapa corporal — vale lembrar hoje.',
      );
    });
  });

  group('timeline360ChatPreviewBody', () {
    test('keeps first sentence for recovery bodies', () {
      expect(
        timeline360ChatPreviewBody(
          'Você sumiu do radar — me responde por aqui que eu ajusto o plano. '
          'Quer retomar? Me responde com um oi.',
        ),
        'Você sumiu do radar — me responde por aqui que eu ajusto o plano.',
      );
    });
  });

  group('formatTimeline360Date', () {
    test('null date uses accessible label', () {
      expect(formatTimeline360Date(null), 'data não informada');
    });
  });

  group('resolveTimeline360DeepLinkForPersonal', () {
    test('rewrites aluno checkin shell to treinos-list', () {
      expect(
        resolveTimeline360DeepLinkForPersonal(
          link: '/checkin/treinos',
          alunoId: 42,
        ),
        '/alunos/42/treinos-list',
      );
    });

    test('keeps personal routes intact', () {
      expect(
        resolveTimeline360DeepLinkForPersonal(
          link: '/alunos/7/chat',
          alunoId: 7,
        ),
        '/alunos/7/chat',
      );
    });
  });

  group('timeline360ExpandLinkLabel', () {
    test('chat vs other kinds', () {
      expect(
        timeline360ExpandLinkLabel(kind: 'Chat'),
        'Ler mensagem inteira',
      );
      expect(timeline360ExpandLinkLabel(kind: 'Radar'), 'Ver detalhes');
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

    test('maps trivial oi-only chat to coach-friendly label', () {
      expect(
        timeline360ChatPreviewBody('oi'),
        'Saudação no chat',
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

  group('timeline360ListLabel', () {
    test('check-in short label without treino name', () {
      expect(
        timeline360ListLabel(
          kind: 'Check-in',
          title: 'Check-in concluído · Treino A',
          meta: 'CONCLUIDO',
        ),
        'Check-in concluído',
      );
    });

    test('long autonomia title falls back to kind', () {
      expect(
        timeline360ListLabel(
          kind: 'Autonomia',
          title: 'Conferir agenda da semana completa com o aluno',
          meta: 'CLICKED',
        ),
        'Autonomia',
      );
    });
  });

  group('timeline360ListSubtitle', () {
    test('check-in uses treino from legacy title', () {
      expect(
        timeline360ListSubtitle(
          kind: 'Check-in',
          title: 'Check-in concluído · Treino A',
          body: 'Treino registrado com séries.',
        ),
        'Treino A',
      );
    });

    test('radar body stays without priority or meta join', () {
      expect(
        timeline360ListSubtitle(
          kind: 'Radar',
          title: 'Radar Focux · 87 pts',
          body: 'Nathalia fechou 2 treino(s) em 7 dias.',
        ),
        'Nathalia fechou 2 treino(s) em 7 dias.',
      );
    });
  });

  group('timeline360ShouldShowMetaChip', () {
    test('hides radar mapa corporal meta when P0 badge is shown', () {
      expect(
        timeline360ShouldShowMetaChip(
          kind: 'Radar',
          meta: 'Completar mapa corporal',
          priority: 'P0',
          title: 'Radar Focux · 19 pts',
        ),
        isFalse,
      );
    });
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

    test('shows non-mapa radar meta', () {
      expect(
        timeline360ShouldShowMetaChip(
          kind: 'Radar',
          meta: 'Revisar aderência semanal',
          priority: 'P1',
          title: 'Radar Focux · 12 pts',
        ),
        isTrue,
      );
    });

    test('hides autonomia business priority and action codes', () {
      expect(
        timeline360ShouldShowMetaChip(
          kind: 'Autonomia',
          meta: 'ALTA',
          priority: 'P2',
          title: 'Completar perfil base',
        ),
        isFalse,
      );
      expect(
        timeline360ShouldShowMetaChip(
          kind: 'Autonomia',
          meta: 'VIEWED',
          priority: 'P2',
          title: 'Completar perfil base',
        ),
        isFalse,
      );
    });
  });

  group('timeline360LocalizeAutonomiaActionCode', () {
    test('translates VIEWED to Visualizado', () {
      expect(
        sanitizeTimeline360Copy('VIEWED'),
        'Visualizado',
      );
      expect(
        timeline360LocalizeAutonomiaActionCode('CLICKED'),
        'Abriu no app',
      );
    });
  });

  group('dedupeAutonomiaTimelineByTask', () {
    test('keeps one row per task title', () {
      final kinds = ['Autonomia', 'Autonomia', 'Chat'];
      final titles = [
        'Completar perfil base',
        'Completar perfil base',
        'Oi',
      ];
      final deduped = dedupeAutonomiaTimelineByTask(
        List.generate(3, (i) => i),
        kindOf: (i) => kinds[i],
        titleOf: (i) => titles[i],
      );
      expect(deduped, [0, 2]);
    });
  });

  group('isSmokeTimelineContent', () {
    test('detects smoke chat prefix', () {
      expect(isSmokeTimelineContent('Smoke chat 20260502232331'), isTrue);
    });

    test('detects copilot boilerplate', () {
      expect(
        isSmokeTimelineContent(
          'Acompanhamento registrado — revise o próximo passo no chat.',
        ),
        isTrue,
      );
    });

    test('keeps real coach copy', () {
      expect(
        isSmokeTimelineContent('Nathalia ainda não completou o mapa corporal.'),
        isFalse,
      );
    });
  });

  group('timeline360PriorityInk', () {
    test('darkens brand teal on light surfaces', () {
      const primary = Color(0xFF18B5B5);
      final ink = timeline360PriorityInk(primary, isDark: false);
      expect(ink, isNot(same(primary)));
      expect(ink.computeLuminance(), lessThan(primary.computeLuminance()));
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
