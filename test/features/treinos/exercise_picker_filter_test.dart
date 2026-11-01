import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercise_enum_api.dart';

void main() {
  group('enumSetQueryParam', () {
    test('gera csv ordenado para backend', () {
      expect(
        enumSetQueryParam({Equipamento.halter, Equipamento.barra}),
        'BARRA,HALTER',
      );
    });
  });

}
