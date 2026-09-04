import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/utils/relatorio_aluno_display.dart';

void main() {
  test('relatorioAlunoPeriodoValueLabel cobre preset e intervalo', () {
    expect(
      relatorioAlunoPeriodoValueLabel(dias: 30),
      '30 dias',
    );
    expect(
      relatorioAlunoPeriodoValueLabel(
        dias: 30,
        inicio: DateTime(2026, 8, 1),
        fim: DateTime(2026, 8, 31),
      ),
      '01/08 – 31/08',
    );
  });

  test('relatorioAlunoPeriodoKey e dias from key', () {
    expect(
      relatorioAlunoPeriodoKey(dias: 7, personalizado: false),
      '7',
    );
    expect(
      relatorioAlunoPeriodoKey(dias: 30, personalizado: true),
      'custom',
    );
    expect(relatorioAlunoDiasFromKey('90'), 90);
    expect(relatorioAlunoDiasFromKey('custom'), isNull);
    expect(relatorioAlunoPeriodoOpcaoLabel('custom'), 'Personalizado');
  });

  test('relatorioAlunoAderenciaStatus e comparativo', () {
    expect(relatorioAlunoAderenciaStatus(80), 'Excelente');
    expect(relatorioAlunoAderenciaStatus(50), 'Regular');
    expect(relatorioAlunoAderenciaStatus(10), 'Baixa');
    expect(relatorioAlunoAderenciaBaixa(49.9), isTrue);
  });

  test('relatorioAlunoDeltaLabel e check-ins', () {
    expect(relatorioAlunoDeltaLabel(10), '+10.0%');
    expect(relatorioAlunoDeltaLabel(-2.5), '-2.5%');
    expect(relatorioAlunoCheckinsLabel(0), 'Nenhum');
    expect(relatorioAlunoCheckinsLabel(1), '1 check-in');
    expect(relatorioAlunoCheckinsLabel(8), '8 check-ins');
  });

  test('hub e sticky do relatório do aluno', () {
    expect(relatorioAlunoStickyExport(), 'Exportar PDF');
    expect(
      relatorioAlunoHubSubtitle(alunoNome: 'Ana', diasAnalisados: 30),
      'Ana · 30 dias',
    );
    expect(
      relatorioAlunoHubSubtitle(
        alunoNome: 'Ana',
        diasAnalisados: 30,
        freshness: 'há 1 min',
      ),
      'Ana · 30 dias · há 1 min',
    );
  });
}
