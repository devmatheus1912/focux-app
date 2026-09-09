import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/onboarding/data/onboarding_repository.dart';
import 'package:focux_app/features/onboarding/data/onboarding_status_data.dart';
import 'package:focux_app/features/onboarding/data/setup_steps_catalog.dart';
import 'package:focux_app/features/onboarding/utils/onboarding_wizard_normalize.dart';

void main() {
  group('OnboardingStatusData', () {
    test('progressoExibido reflete etapas visíveis (5/7 = 71%)', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: true,
      );

      expect(data.etapasFeitas(), 5);
      expect(data.etapasTotal(), 7);
      expect(data.progressoExibido(), 71);
      expect(data.ativacaoCompleta(), isFalse);
    });

    test('sem landing esconde link-bio da contagem', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        pacoteCriado: true,
        habitoConfigurado: true,
        linkBioConfigurado: false,
      );

      expect(data.etapasTotal(includeLinkBio: false), 6);
      expect(data.ativacaoCompleta(includeLinkBio: false), isTrue);
      expect(data.ativacaoCompleta(includeLinkBio: true), isFalse);
    });

    test('ativacaoCompleta quando todas as 7 etapas concluídas', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        pacoteCriado: true,
        habitoConfigurado: true,
        linkBioConfigurado: true,
      );

      expect(data.progressoExibido(), 100);
      expect(data.ativacaoCompleta(), isTrue);
    });

    test('fromJson inclui pacote, hábito e link na bio', () {
      final data = OnboardingStatusData.fromJson({
        'perfilCompleto': true,
        'primeiroAlunoAdicionado': false,
        'primeiroTreinoCriado': false,
        'pagamentoConfigurado': false,
        'pacoteCriado': true,
        'habitoConfigurado': false,
        'linkBioConfigurado': true,
      });

      expect(data.pacoteCriado, isTrue);
      expect(data.linkBioConfigurado, isTrue);
      expect(data.progressoExibido(), 43);
    });

    test('fromJson mapeia primeiroPagamentoRecebido legado em pagamento', () {
      final data = OnboardingStatusData.fromJson({
        'primeiroPagamentoRecebido': true,
      });

      expect(data.pagamentoConfigurado, isTrue);
    });
  });

  group('setupStepCatalog', () {
    test('ordem canônica começa em aluno e treino', () {
      expect(setupStepCatalog.map((s) => s.id).toList(), [
        'primeiro-aluno',
        'primeiro-treino',
        'perfil',
        'pagamento',
        'pacote',
        'habito',
        'link-bio',
      ]);
      expect(
        setupStepCatalog.firstWhere((s) => s.id == 'perfil').description,
        'Foto, bio e contato profissional.',
      );
      expect(
        setupStepCatalog.firstWhere((s) => s.id == 'perfil').description,
        isNot(contains('marca')),
      );
    });

    test('nextSetupStep retorna aluno antes de perfil', () {
      final data = OnboardingStatusData(
        perfilCompleto: false,
        primeiroAlunoAdicionado: false,
        primeiroTreinoCriado: false,
        pagamentoConfigurado: false,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: false,
      );
      expect(nextSetupStep(data)?.id, 'primeiro-aluno');
    });

    test('nextSetupStep retorna primeiro pendente', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        pacoteCriado: false,
        habitoConfigurado: false,
        linkBioConfigurado: true,
      );

      expect(nextSetupStep(data)?.id, 'pacote');
    });

    test('link-bio some sem landingCompleta', () {
      final data = OnboardingStatusData(
        perfilCompleto: true,
        primeiroAlunoAdicionado: true,
        primeiroTreinoCriado: true,
        pagamentoConfigurado: true,
        pacoteCriado: true,
        habitoConfigurado: true,
        linkBioConfigurado: false,
      );
      expect(nextSetupStep(data, landingCompleta: false), isNull);
      expect(nextSetupStep(data, landingCompleta: true)?.id, 'link-bio');
      expect(
        visibleSetupSteps(landingCompleta: false).map((s) => s.id),
        isNot(contains('link-bio')),
      );
    });

    test('descrições cabem em uma linha no fold inset', () {
      for (final step in setupStepCatalog) {
        expect(step.description.length, lessThanOrEqualTo(40));
      }
    });

    test('título do pacote alinhado ao wizard', () {
      expect(
        setupStepCatalog.firstWhere((s) => s.id == 'pacote').title,
        'Crie seu primeiro pacote',
      );
    });
  });

  group('normalizeOnboardingWizard', () {
    test('reordena BFF e aplica copy sem cor da marca', () {
      final raw = OnboardingWizard(
        steps: [
          OnboardingStep(
            id: 'perfil',
            title: 'Complete seu perfil',
            description: 'Cor da marca e bio profissional.',
            icon: 'person',
            completed: false,
            actionRoute: '/perfil/editar',
            estimatedMinutes: 2,
          ),
          OnboardingStep(
            id: 'primeiro-aluno',
            title: 'Cadastre seu primeiro aluno',
            description: 'Cadastre ou importe.',
            icon: 'person_add',
            completed: true,
            actionRoute: '/alunos/novo',
            estimatedMinutes: 2,
          ),
          OnboardingStep(
            id: 'link-bio',
            title: 'Crie seu link na bio',
            description: 'Página pública.',
            icon: 'link',
            completed: false,
            actionRoute: '/perfil/landing-editor',
            estimatedMinutes: 2,
          ),
        ],
        completedCount: 1,
        totalCount: 3,
        progressPercent: 33,
        nextActionLabel: 'Complete seu perfil',
        nextActionRoute: '/perfil/editar',
        wizardCompleto: false,
        allStepsDone: false,
      );

      final free = normalizeOnboardingWizard(raw, landingCompleta: false);
      expect(free.steps.first.id, 'primeiro-aluno');
      expect(free.steps.first.completed, isTrue);
      expect(free.nextActionRoute, '/treinos/novo');
      expect(free.steps.map((s) => s.id), isNot(contains('link-bio')));
      expect(
        free.steps.firstWhere((s) => s.id == 'perfil').description,
        'Foto, bio e contato profissional.',
      );

      final ent = normalizeOnboardingWizard(raw, landingCompleta: true);
      expect(ent.steps.map((s) => s.id), contains('link-bio'));
    });

    test('descarta passos órfãos do BFF fora do catálogo', () {
      final raw = OnboardingWizard(
        steps: [
          OnboardingStep(
            id: 'cor-da-marca',
            title: 'Cor da marca',
            description: 'Escolha a paleta.',
            icon: 'palette',
            completed: false,
            actionRoute: '/setup/identidade',
            estimatedMinutes: 2,
          ),
          OnboardingStep(
            id: 'primeiro-aluno',
            title: 'Cadastre seu primeiro aluno',
            description: 'Cadastre ou importe.',
            icon: 'person_add',
            completed: false,
            actionRoute: '/alunos/novo',
            estimatedMinutes: 2,
          ),
        ],
        completedCount: 0,
        totalCount: 2,
        progressPercent: 0,
        nextActionLabel: 'Cor da marca',
        nextActionRoute: '/setup/identidade',
        wizardCompleto: false,
        allStepsDone: false,
      );

      final normalized = normalizeOnboardingWizard(
        raw,
        landingCompleta: false,
      );
      expect(normalized.steps.map((s) => s.id), isNot(contains('cor-da-marca')));
      expect(normalized.steps.first.id, 'primeiro-aluno');
      expect(normalized.nextActionRoute, '/alunos/novo');
    });
  });
}
