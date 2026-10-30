import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/data/setup_steps_catalog.dart';
import 'package:focux_app/features/onboarding/utils/onboarding_wizard_normalize.dart';

OnboardingStatusData status({
  bool aluno = false,
  bool treino = false,
  bool enviado = false,
  bool pagamento = false,
  bool link = false,
  bool completo = false,
}) => OnboardingStatusData(
  perfilCompleto: false,
  primeiroAlunoAdicionado: aluno,
  primeiroTreinoCriado: treino,
  pagamentoConfigurado: pagamento,
  pacoteCriado: false,
  habitoConfigurado: false,
  linkBioConfigurado: link,
  wizardCompleto: completo,
  treinoEnviado: enviado,
);

void main() {
  test('todo plano tem os mesmos três passos', () {
    expect(setupStepCatalog.map((s) => s.id), [
      'primeiro-aluno',
      'primeiro-treino',
      'enviar-treino',
    ]);
    expect(status().etapasTotal(), 3);
  });

  test('progresso conta só os três passos', () {
    expect(status(aluno: true).etapasFeitas(), 1);
    expect(status(aluno: true).progressoExibido(), 33);
  });

  test('ativação completa com os três passos ou com o wizard encerrado', () {
    expect(status(aluno: true, treino: true).ativacaoCompleta(), isFalse);
    expect(
      status(aluno: true, treino: true, enviado: true).ativacaoCompleta(),
      isTrue,
    );
    expect(status(completo: true).ativacaoCompleta(), isTrue);
  });

  test('quem já fez um passo entra no próximo', () {
    expect(nextSetupStep(status())?.id, 'primeiro-aluno');
    expect(nextSetupStep(status(aluno: true))?.id, 'primeiro-treino');
    expect(nextSetupStep(status(aluno: true, treino: true))?.id, 'enviar-treino');
    expect(
      nextSetupStep(status(aluno: true, treino: true, enviado: true)),
      isNull,
    );
  });

  test('fromJson lê treinoEnviado e o campo antigo de pagamento', () {
    final d = OnboardingStatusData.fromJson({
      'treinoEnviado': true,
      'primeiroPagamentoRecebido': true,
    });
    expect(d.treinoEnviado, isTrue);
    expect(d.pagamentoConfigurado, isTrue);
  });

  test('sugestão vem uma por vez e respeita plano e dispensa', () {
    final d = status();
    expect(
      setupProximaSugestao(d, podeCobrar: true, temLanding: true)?.id,
      'pagamento',
    );
    expect(
      setupProximaSugestao(
        d,
        podeCobrar: true,
        temLanding: true,
        dispensadas: const {'pagamento'},
      )?.id,
      'link-bio',
    );
    expect(setupProximaSugestao(d, podeCobrar: false, temLanding: false), isNull);
  });

  test('wizard do backend vira os três passos, na ordem', () {
    OnboardingStep s(String id, {bool feito = false}) => OnboardingStep(
      id: id,
      title: 'antigo',
      description: '',
      icon: '',
      completed: feito,
      actionRoute: '',
      estimatedMinutes: 0,
    );
    final w = normalizeOnboardingWizard(
      OnboardingWizard(
        steps: [s('perfil'), s('enviar-treino'), s('primeiro-aluno', feito: true)],
        completedCount: 1,
        totalCount: 3,
        progressPercent: 33,
        nextActionLabel: '',
        nextActionRoute: '',
        wizardCompleto: false,
        allStepsDone: false,
      ),
    );
    expect(w.steps.map((e) => e.id), [
      'primeiro-aluno',
      'primeiro-treino',
      'enviar-treino',
    ]);
    expect(w.completedCount, 1);
    expect(w.steps.first.title, 'Cadastre seu primeiro aluno');
  });
}
