import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_volume_format.dart';
import 'package:focux_app/features/dashboard/utils/birth_date_api_format.dart';
import 'package:focux_app/features/anamnese/data/anamnese_repository.dart';
import 'package:focux_app/features/anamnese/utils/anamnese_display.dart';

void main() {
  group('aluno bugs P0', () {
    test('sonoHoras aceita string e number', () {
      expect(Anamnese.fromJson({'sonoHoras': '7.5'}).sonoHoras, 7.5);
      expect(Anamnese.fromJson({'sonoHoras': 7}).sonoHoras, 7.0);
      expect(Anamnese.fromJson({'sonoHoras': 7.5}).sonoHoras, 7.5);
      expect(anamneseSonoHorasLabel(7.5), '7.5 horas');
      expect(anamneseSonoHorasLabel(7), '7 horas');
    });

    test('volume kg não usa t enganoso', () {
      expect(formatAlunoVolumeKg(4400), '4,4 mil kg');
      expect(formatAlunoVolumeKg(4000), '4 mil kg');
      expect(formatAlunoVolumeKg(240), '240 kg');
      expect(formatAlunoVolumeKg(0), '—');
      expect(formatAlunoVolumeKg(8200, compact: true), '8,2 mil');
      expect(formatAlunoVolumeKg(4400), isNot(contains('t')));
    });

    test('nascimento exibe dd-MM-yyyy', () {
      expect(formatBirthDateForDisplay('1995-12-19'), '19-12-1995');
      expect(formatBirthDateForDisplay('19/12/1995'), '19-12-1995');
      expect(normalizeBirthDateForApi('19-12-1995'), '1995-12-19');
    });
  });
}
