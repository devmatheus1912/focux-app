import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/treino_atribuicao_prazo.dart';

void main() {
  final today = DateTime(2026, 9, 22);

  test('chipLabel sem prazo', () {
    expect(TreinoAtribuicaoPrazo.chipLabel(null, today: today), isNull);
  });

  test('chipLabel futuro', () {
    expect(
      TreinoAtribuicaoPrazo.chipLabel(DateTime(2026, 10, 1), today: today),
      'Até 01/10',
    );
    expect(
      TreinoAtribuicaoPrazo.isAtrasado(DateTime(2026, 10, 1), today: today),
      isFalse,
    );
  });

  test('chipLabel hoje', () {
    expect(
      TreinoAtribuicaoPrazo.chipLabel(today, today: today),
      'Vence hoje',
    );
  });

  test('chipLabel atrasado', () {
    expect(
      TreinoAtribuicaoPrazo.chipLabel(DateTime(2026, 9, 1), today: today),
      'Atrasado · até 01/09',
    );
    expect(
      TreinoAtribuicaoPrazo.isAtrasado(DateTime(2026, 9, 1), today: today),
      isTrue,
    );
  });

  test('homeHint soft copy', () {
    expect(
      TreinoAtribuicaoPrazo.homeHint(DateTime(2026, 10, 1), today: today),
      'Até 01/10',
    );
    expect(
      TreinoAtribuicaoPrazo.homeHint(DateTime(2026, 9, 1), today: today),
      'Atrasado · até 01/09 — ainda pode treinar.',
    );
  });

  test('parseIsoDate e toIsoDate', () {
    expect(
      TreinoAtribuicaoPrazo.parseIsoDate('2026-10-01'),
      DateTime(2026, 10, 1),
    );
    expect(
      TreinoAtribuicaoPrazo.toIsoDate(DateTime(2026, 10, 1)),
      '2026-10-01',
    );
  });
}
