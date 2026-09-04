import 'focux_microcopy.dart';

/// Copy de marca — fonte única para taglines e microcopy público.
abstract final class FocuxBrandCopy {
  static const tagline = onboardingHook;

  static const taglineShort = 'Personal e aluno juntos.';

  static const splashLoading = 'Carregando';

  static const onboardingHook =
      'O app onde personal e aluno finalmente caminham juntos.';

  static const onboardingHookHighlight = 'caminham juntos.';

  static const onboardingHookAluno =
      'Treino, progresso e personal — tudo no mesmo app.';

  static const onboardingHookAlunoHighlight = 'mesmo app.';

  /// Fallback neutro quando o pulse público não responde (sem número inventado).
  static const onboardingSocialProofFallback =
      'Personais e alunos treinando todo dia';

  static const onboardingSkip = 'Pular';

  static const onboardingCtaNext = 'Quero isso →';

  static const onboardingCtaFinish = 'Começar grátis';

  static const onboardingCtaFinishHint = 'Grátis para começar · sem cartão';

  /// Aluno exige convite no register — CTA não promete “grátis sem fricção”.
  static const onboardingCtaFinishAluno = 'Entrar com convite';

  static const onboardingCtaFinishHintAluno =
      'Precisa do código do seu personal';

  static String onboardingFinishCta(OnboardingPersona persona) =>
      persona == OnboardingPersona.aluno
          ? onboardingCtaFinishAluno
          : onboardingCtaFinish;

  static String onboardingFinishHint(OnboardingPersona persona) =>
      persona == OnboardingPersona.aluno
          ? onboardingCtaFinishHintAluno
          : onboardingCtaFinishHint;

  static const onboardingLoginLead = 'Já treina com a gente? ';

  static const onboardingLoginAction = 'Entrar';

  static const onboardingExistingAccountCta = 'Já tenho conta';

  static const authExistingAccountLead = 'Já tem conta? ';

  static const authExistingAccountAction = 'Entrar';

  /// Convite aluno — quem já tem conta não precisa de código.
  static const authInviteExistingAccountCta = 'Entrar na minha conta';

  static const onboardingPersonaPersonal = 'Personal';

  static const onboardingPersonaAluno = 'Aluno';

  static const alunoActivationHeroSubtitle =
      'Complete estes passos e seu personal acompanha cada evolução com você — '
      'desde o primeiro treino.';

  static const alunoActivationReadyTitle = 'Tudo pronto para evoluir';

  static const alunoActivationReadyBody =
      'Sua base está fechada. Agora é treinar — seu personal vê tudo em tempo real.';

  static List<OnboardingSlideCopy> slidesFor(OnboardingPersona persona) {
    return persona == OnboardingPersona.aluno
        ? onboardingSlidesAluno
        : onboardingSlidesPersonal;
  }

  static const onboardingSlidesPersonal = <OnboardingSlideCopy>[
    OnboardingSlideCopy(
      title: 'Enquanto você organiza, seu aluno ',
      titleHighlight: 'evolui.',
      subtitle:
          '${FocuxMicrocopy.commandCenter} para você. Check-in com carga e RPE para ele. '
          'Um progresso, zero planilha.',
      metrics: [
        OnboardingMetricCopy(value: '360°', label: 'Visão do aluno'),
        OnboardingMetricCopy(value: 'Ao vivo', label: 'Check-in real'),
        OnboardingMetricCopy(value: 'Score', label: FocuxMicrocopy.focuxScore),
      ],
      // Checklist no slide 2 — slide 1 fica marca + headline + métricas.
      features: [],
    ),
    OnboardingSlideCopy(
      title: 'Copiloto, PIX e fila do dia. ',
      titleHighlight: 'Você no comando.',
      subtitle:
          'IA com contexto real de cada aluno, cobranças no painel e '
          'próxima ação em um toque — você decide.',
      // Slide 2 = checklist; métricas só no slide 1 (hero budget).
      metrics: [],
      features: [
        'Modos Treino e Progressão por aluno',
        'Mensalidades com PIX, QR e alerta de inadimplência',
        'Ações do Copiloto caem direto na sua fila do dia',
      ],
    ),
  ];

  static const onboardingSlidesAluno = <OnboardingSlideCopy>[
    OnboardingSlideCopy(
      title: 'Seu treino. Seu progresso. ',
      titleHighlight: 'Na palma da mão.',
      subtitle:
          'Execute com timer e RPE, veja PRs e evolução — '
          'seu personal acompanha cada sessão em tempo real.',
      metrics: [
        OnboardingMetricCopy(value: 'Live', label: 'Check-in'),
        OnboardingMetricCopy(value: 'PRs', label: 'Recordes'),
        OnboardingMetricCopy(value: 'Score', label: FocuxMicrocopy.focuxScore),
      ],
      // Checklist no slide 2 — slide 1 fica marca + headline + métricas.
      features: [],
    ),
    OnboardingSlideCopy(
      title: 'IA, form check e mensalidade. ',
      titleHighlight: 'Sem surpresa.',
      subtitle:
          'Assistente com contexto do seu treino, feedback em vídeo e '
          'status de pagamento claro — tudo no mesmo app.',
      metrics: [],
      features: [
        'Treinos atribuídos com carga, descanso e histórico',
        'Assistente IA e Form check com vídeo do personal',
        'Minhas mensalidades com status claro por mês',
      ],
    ),
  ];
}

enum OnboardingPersona { personal, aluno }

class OnboardingSlideCopy {
  const OnboardingSlideCopy({
    required this.title,
    required this.titleHighlight,
    required this.subtitle,
    required this.metrics,
    required this.features,
  });

  final String title;
  final String titleHighlight;
  final String subtitle;
  final List<OnboardingMetricCopy> metrics;
  final List<String> features;
}

class OnboardingMetricCopy {
  const OnboardingMetricCopy({required this.value, required this.label});

  final String value;
  final String label;
}
