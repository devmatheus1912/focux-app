import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/utils/landing_studio_guidance.dart';

void main() {
  test('CREF sozinho não conta como prova', () {
    expect(LandingStudioGuidance.isCrefOnly('CREF 01561-G'), isTrue);
    expect(
      LandingStudioGuidance.isCrefOnly(
        'Acompanhamento contínuo com alunos de hipertrofia há 6 anos',
      ),
      isFalse,
    );
  });
}
