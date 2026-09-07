import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_execucao_display.dart';

void main() {
  test('checkinDurationLabel formata mm:ss e hh:mm:ss', () {
    expect(checkinDurationLabel(const Duration(seconds: 5)), '00:05');
    expect(
      checkinDurationLabel(const Duration(minutes: 12, seconds: 4)),
      '12:04',
    );
    expect(
      checkinDurationLabel(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '01:02:03',
    );
  });

  test('checkinSerieKpiLabel e contexto cabem em uma linha', () {
    expect(checkinSerieKpiLabel(2, 4), '2/4');
    expect(checkinSerieKpiLabel(1, null), '1');
    expect(checkinSeriesRepsLabel(3, '12'), '3 × 12');
    expect(
      checkinSerieContextLine(
        index: 2,
        total: 6,
        seriesReps: '3 × 12',
        carga: '80 kg',
        descansoSegundos: 60,
      ),
      '2/6 · 3 × 12 · 80 kg · descanso 60s',
    );
    expect(
      checkinChromeContextLine(duration: '08:12', concluido: 1, total: 5),
      '08:12 · 1/5 exercícios',
    );
  });

  test('checkinElapsedSince e rest sobrevivem background', () {
    final started = DateTime(2026, 9, 7, 18, 0, 0);
    expect(
      checkinElapsedSince(
        started.toIso8601String(),
        started.add(const Duration(minutes: 8)),
      ),
      const Duration(minutes: 8),
    );
    expect(checkinElapsedSince(null), Duration.zero);
    final ends = DateTime.utc(2026, 9, 7, 18, 1, 0);
    expect(
      checkinRestRemaining(
        endsAt: ends,
        now: DateTime.utc(2026, 9, 7, 18, 0, 40),
      ),
      20,
    );
    expect(
      checkinRestRemaining(
        endsAt: ends,
        now: DateTime.utc(2026, 9, 7, 18, 2, 0),
      ),
      0,
    );
  });

  test('checkinCargaLabel usa vírgula BR', () {
    expect(checkinCargaLabel(80), '80 kg');
    expect(checkinCargaLabel(7.5), '7,5 kg');
    expect(checkinRegistrarLabel(first: true), 'Registrar série');
    expect(checkinPularDescansoLabel(), 'Pular descanso');
  });
}
