import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/widgets/agenda_day_chip.dart';

void main() {
  testWidgets('chips com e sem contagem ficam com a mesma altura', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AgendaDayChip(
                weekdayLabel: 'Qua',
                dayNumber: 19,
                selected: false,
                count: 1,
                onTap: () {},
              ),
              AgendaDayChip(
                weekdayLabel: 'Qui',
                dayNumber: 20,
                selected: true,
                count: 0,
                isToday: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final qua = tester.getSize(find.text('19').first);
    final qui = tester.getSize(find.text('20').first);
    expect(qua.height, qui.height);

    final chipQua = tester.getSize(find.byType(AgendaDayChip).first);
    final chipQui = tester.getSize(find.byType(AgendaDayChip).last);
    expect(chipQua.height, chipQui.height);
    expect(chipQua.height, greaterThanOrEqualTo(48));
  });
}
