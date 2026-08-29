import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/template_splits.dart';
import 'package:focux_app/features/exercicios/utils/template_split_catalog.dart';

void main() {
  group('buildTemplateSplitSections', () {
    test('agrupa na ordem da agenda do aluno', () {
      final sections = buildTemplateSplitSections();
      expect(
        sections.map((s) => s.grupo).toList(),
        [
          TemplateSplitGroup.ate3Dias,
          TemplateSplitGroup.quatroDias,
          TemplateSplitGroup.cincoSeisDias,
          TemplateSplitGroup.foco,
        ],
      );
      expect(
        sections.expand((s) => s.items).length,
        templateSplits.length,
      );
    });

    test('catálogo traz nomes PT-BR usados no BR', () {
      final names = templateSplits.map((t) => t.nome).toSet();
      expect(names, contains('Full body'));
      expect(names, contains('Superior / Inferior'));
      expect(names, contains('ABC clássico'));
      expect(names, contains('Empurrar / Puxar / Pernas'));
      expect(names, contains('Glúteo e pernas'));
      expect(names, isNot(contains('Bro split clássico')));
      expect(names, isNot(contains('Upper / Lower')));
    });

    test('subtitle inclui frequência semanal', () {
      final full = templateSplits.firstWhere((t) => t.id == 'fullbody-iniciante');
      final line = templateSplitTileSubtitle(full);
      expect(line, contains('3x/sem'));
      expect(line, contains('exercício'));
    });
  });
}
