import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercise_enum_api.dart';

void main() {
  test('dartEnumNameToBackendKey converte camelCase para SCREAMING_SNAKE', () {
    expect(dartEnumNameToBackendKey('squat'), 'SQUAT');
    expect(dartEnumNameToBackendKey('pushHorizontal'), 'PUSH_HORIZONTAL');
    expect(
      dartEnumNameToBackendKey('coreAntiExtensao'),
      'CORE_ANTI_EXTENSAO',
    );
    expect(
      dartEnumNameToBackendKey('costasLatissimo'),
      'COSTAS_LATISSIMO',
    );
  });

  test('exercisePickerStatCount resolve chave do backend', () {
    expect(
      exercisePickerStatCount(const {'SQUAT': 12}, 'squat'),
      12,
    );
    expect(
      exercisePickerStatCount(const {'PUSH_HORIZONTAL': 4}, 'pushHorizontal'),
      4,
    );
  });
}
