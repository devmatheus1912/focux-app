import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/alunos/widgets/aluno_operacao_adherence_bars.dart';

String _isoDay(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

const _active = Color(0xFF22C55E);
const _miss = Color(0xFFDC6B6B);
const _today = Color(0xFF12A3A3);

void main() {
  testWidgets('cada dia pinta conforme o status', (tester) async {
    final now = DateTime.now();
    final anchor = DateTime(now.year, now.month, now.day);
    String iso(int daysAgo) =>
        _isoDay(anchor.subtract(Duration(days: daysAgo)));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlunoOperacaoAdherenceBars(
            points: [
              AderenciaWeekPoint(checkins: 1, date: iso(3)),
              AderenciaWeekPoint(
                checkins: 0,
                date: iso(2),
                status: AderenciaDiaStatus.faltou,
              ),
              AderenciaWeekPoint(
                checkins: 0,
                date: iso(1),
                status: AderenciaDiaStatus.semPlano,
              ),
              AderenciaWeekPoint(checkins: 0, date: iso(0)),
            ],
            activeColor: _active,
            missColor: _miss,
            todayRingColor: _today,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boxes =
        tester
            .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
            .map((c) => c.decoration! as BoxDecoration)
            .toList();
    expect(boxes, hasLength(4));

    Color border(BoxDecoration d) => (d.border! as Border).top.color;

    expect(boxes[0].color, _active.withValues(alpha: 0.18));
    expect(boxes[1].color, _miss.withValues(alpha: 0.14));
    expect(border(boxes[1]), _miss.withValues(alpha: 0.55));
    expect(boxes[2].color, Colors.transparent);
    expect(
      border(boxes[2]).toARGB32(),
      isNot(_miss.withValues(alpha: 0.55).toARGB32()),
    );
    expect(boxes[3].color, Colors.transparent);
    expect(border(boxes[3]), _today);

    for (final label in ['treinou', 'faltou', 'sem treino previsto', 'hoje']) {
      expect(
        find.bySemanticsLabel(RegExp('· $label(\$|\\n)')),
        findsOneWidget,
        reason: label,
      );
    }
  });
}
