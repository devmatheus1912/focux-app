import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/mfa_disable_otp_copy.dart';
import 'package:focux_app/features/alunos/utils/aluno360_evolucao_inteligente_logic.dart';

void main() {
  group('mfaDisableOtpSentMessage', () {
    test('relay Apple explica Mail da conta', () {
      final msg = mfaDisableOtpSentMessage('a***@privaterelay.appleid.com');
      expect(msg, contains('e-mail oculto da Apple'));
      expect(msg, contains('Mail da conta Apple'));
    });

    test('e-mail comum usa máscara direta', () {
      final msg = mfaDisableOtpSentMessage('m***@gmail.com');
      expect(msg, contains('m***@gmail.com'));
      expect(msg, isNot(contains('oculto')));
    });
  });

  group('formatTendenciaVolumeHint', () {
    test('clampa % absurdo em texto legível', () {
      expect(
        Aluno360EvolucaoInteligenteLogic.formatTendenciaVolumeHint(596),
        'Volume bem acima da semana anterior',
      );
      expect(
        Aluno360EvolucaoInteligenteLogic.formatTendenciaVolumeHint(18),
        '+18% vs semana anterior',
      );
    });
  });
}
