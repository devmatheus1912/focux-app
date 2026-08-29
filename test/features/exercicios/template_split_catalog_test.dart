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

    test('catálogo traz nomes curtos usados no BR', () {
      final names = templateSplits.map((t) => t.nome).toSet();
      expect(names, contains('Full body'));
      expect(names, contains('Superior / Inferior'));
      expect(names, contains('ABC'));
      expect(names, contains('PPL'));
      expect(names, contains('Glúteo e pernas'));
      expect(names, contains('Em casa'));
      expect(names, isNot(contains('Bro split clássico')));
      expect(names, isNot(contains('Upper / Lower')));
    });

    test('subtitle é curto: frequência · ex · quando', () {
      final full = templateSplits.firstWhere((t) => t.id == 'fullbody-iniciante');
      final line = templateSplitTileSubtitle(full);
      expect(line, '3x · 5 ex. · Tudo em um dia');
    });

    test('headers de grupo são curtos', () {
      expect(TemplateSplitGroup.ate3Dias.header, '2–3 dias');
      expect(TemplateSplitGroup.quatroDias.caption, 'Equilíbrio de volume');
    });
  });
}
