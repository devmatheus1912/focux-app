import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';

void main() {
  group('OnboardingStatusData', () {
    test('progressoExibido reflete etapas visíveis (4/6 = 67%)', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        primeiroPagamentoRecebido: false,
        pacoteCriado: false,
        habitoConfigurado: false,
        progressoPercentual: 66,
      );

      expect(data.etapasFeitas, 4);
      expect(data.etapasTotal, 6);
      expect(data.progressoExibido, 67);
      expect(data.ativacaoCompleta, isFalse);
    });

    test('ativacaoCompleta quando todas as 6 etapas concluídas', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        primeiroPagamentoRecebido: true,
        pacoteCriado: true,
        habitoConfigurado: true,
        progressoPercentual: 100,
      );

      expect(data.progressoExibido, 100);
      expect(data.ativacaoCompleta, isTrue);
    });

    test('fromJson inclui pacote e hábito', () {
      final data = OnboardingStatusData.fromJson({
        'perfilCompleto': true,
        'primeiroAlunoAdicionado': false,
        'primeiroTreinoCriado': false,
        'pagamentoConfigurado': false,
        'primeiroPagamentoRecebido': false,
        'pacoteCriado': true,
        'habitoConfigurado': false,
        'progressoPercentual': 33,
      });

      expect(data.pacoteCriado, isTrue);
      expect(data.habitoConfigurado, isFalse);
      expect(data.progressoExibido, 33);
    });
  });
}
