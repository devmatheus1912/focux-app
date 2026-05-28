import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/data/setup_steps_catalog.dart';

void main() {
  group('OnboardingStatusData', () {
    test('progressoExibido reflete etapas visíveis (5/7 = 71%)', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        primeiroPagamentoRecebido: false,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: true,
        progressoPercentual: 71,
      );

      expect(data.etapasFeitas, 5);
      expect(data.etapasTotal, 7);
      expect(data.progressoExibido, 71);
      expect(data.ativacaoCompleta, isFalse);
    });

    test('ativacaoCompleta quando todas as 7 etapas concluídas', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        primeiroPagamentoRecebido: true,
        pacoteCriado: true,
        habitoConfigurado: true,
        linkBioConfigurado: true,
        progressoPercentual: 100,
      );

      expect(data.progressoExibido, 100);
      expect(data.ativacaoCompleta, isTrue);
    });

    test('fromJson inclui pacote, hábito e link na bio', () {
      final data = OnboardingStatusData.fromJson({
        'perfilCompleto': true,
        'primeiroAlunoAdicionado': false,
        'primeiroTreinoCriado': false,
        'pagamentoConfigurado': false,
        'primeiroPagamentoRecebido': false,
        'pacoteCriado': true,
        'habitoConfigurado': false,
        'linkBioConfigurado': true,
        'progressoPercentual': 43,
      });

      expect(data.pacoteCriado, isTrue);
      expect(data.linkBioConfigurado, isTrue);
      expect(data.progressoExibido, 43);
    });
  });

  group('setupStepCatalog', () {
    test('expõe 7 passos alinhados ao wizard', () {
      expect(setupStepCatalog.length, 7);
    });

    test('nextSetupStep retorna primeiro pendente', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        primeiroPagamentoRecebido: false,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: true,
        progressoPercentual: 71,
      );

      expect(nextSetupStep(data)?.id, 'pacote');
    });

    test('dashboardSetupPreview limita passos pendentes visíveis', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        primeiroPagamentoRecebido: false,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: true,
        progressoPercentual: 71,
      );

      expect(pendingSetupSteps(data).length, 2);
      expect(dashboardSetupPreview(data).length, 2);
      expect(hiddenPendingSetupCount(data), 0);
    });

    test('dashboardSetupPreview oculta passos além do limite', () {
      final data = OnboardingStatusData(
        perfilCompleto: false,
        primeiroAlunoAdicionado: false,
        primeiroTreinoCriado: false,
        pagamentoConfigurado: false,
        primeiroPagamentoRecebido: false,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: false,
        progressoPercentual: 0,
      );

      expect(dashboardSetupPreview(data).length, dashboardSetupPreviewLimit);
      expect(hiddenPendingSetupCount(data), 4);
    });
  });
}
