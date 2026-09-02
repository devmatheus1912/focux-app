import '../../../core/brand/focux_brand_copy.dart';

String onboardingPrimaryTileValue({
  required bool isLast,
  required OnboardingPersona persona,
}) {
  if (!isLast) return 'Slide';
  return persona == OnboardingPersona.aluno ? 'Aluno' : 'Personal';
}

String onboardingLoginTileValue() => 'Login';
