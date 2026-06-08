import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_evolucao_inteligente_logic.dart';

void main() {
  group('Aluno360EvolucaoInteligenteLogic', () {
    test('duplicates single non-zero week for sparkline', () {
      expect(
        Aluno360EvolucaoInteligenteLogic.resolveVolumeSparklineData([0, 420, 0]),
        [420, 420],
      );
      expect(
        Aluno360EvolucaoInteligenteLogic.resolveVolumeSparklineData([0, 420]),
        [420, 420],
      );
      expect(
        Aluno360EvolucaoInteligenteLogic.resolveVolumeSparklineData(
          [280, 310, 350],
        ),
        [280, 310, 350],
      );
    });

    test('returns empty when no volume', () {
      expect(
        Aluno360EvolucaoInteligenteLogic.resolveVolumeSparklineData(
          const [0, 0, 0],
        ),
        isEmpty,
      );
    });

    test('detects single week volume', () {
      expect(
        Aluno360EvolucaoInteligenteLogic.isSingleWeekVolume([0, 420]),
        isTrue,
      );
      expect(
        Aluno360EvolucaoInteligenteLogic.isSingleWeekVolume([100, 420]),
        isFalse,
      );
    });
  });
}
