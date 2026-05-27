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

  static const onboardingSocialProof =
      '+200 personal trainers · alunos treinando todo dia';

  static const onboardingSkip = 'Pular';

  static const onboardingCtaNext = 'Quero isso →';

  static const onboardingCtaFinish = 'Começar grátis';

  static const onboardingCtaFinishHint = 'Grátis para começar · sem cartão';

  static const onboardingLoginLead = 'Já treina com a gente? ';

  static const onboardingLoginAction = 'Entrar';

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
          'Command Center para você. Check-in com carga e RPE para ele. '
          'Um progresso, zero planilha.',
      metrics: [
        OnboardingMetricCopy(value: '360°', label: 'Visão do aluno'),
        OnboardingMetricCopy(value: 'Ao vivo', label: 'Check-in real'),
        OnboardingMetricCopy(value: 'Score', label: 'Focux Score™'),
      ],
      features: [
        'Comando: quem precisa de você hoje, primeiro',
        'Check-in com timer, RPE e histórico no app',
        'Aderência, risco e PRs no perfil 360',
      ],
    ),
    OnboardingSlideCopy(
      title: 'Copiloto que analisa. ',
      titleHighlight: 'Você aplica.',
      subtitle:
          'Treino, dieta e progressão com contexto real de cada aluno — '
          'sugestões prontas na hora, decisão sempre sua.',
      metrics: [
        OnboardingMetricCopy(value: '3', label: 'Modos IA'),
        OnboardingMetricCopy(value: '1 toque', label: 'Próxima ação'),
        OnboardingMetricCopy(value: 'Fila', label: 'Do dia'),
      ],
      features: [
        'Modos Treino, Dieta e Progressão por aluno',
        'Sugestões de carga para aceitar ou ajustar',
        'Ações do Copiloto caem direto na sua fila do dia',
      ],
    ),
    OnboardingSlideCopy(
      title: 'Receba sem perseguir. ',
      titleHighlight: 'Treine em paz.',
      subtitle:
          'PIX, mensalidades e alertas de inadimplência no painel — '
          'seu aluno paga, você volta pro que importa: resultado.',
      metrics: [
        OnboardingMetricCopy(value: 'PIX', label: 'Cobrar fácil'),
        OnboardingMetricCopy(value: 'Hoje', label: 'Quem atrasou'),
        OnboardingMetricCopy(value: 'Meta', label: 'Receita do mês'),
      ],
      features: [
        'Mensalidades com PIX, QR e cobrar direto no chat',
        'Inadimplentes no dashboard antes de virar problema',
        'Panorama financeiro: receita vs meta do mês',
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
        OnboardingMetricCopy(value: 'Score', label: 'Focux Score™'),
      ],
      features: [
        'Treinos atribuídos com carga, descanso e histórico',
        'Evolução semanal e recordes pessoais visíveis',
        'Chat com seu personal no mesmo app do treino',
      ],
    ),
    OnboardingSlideCopy(
      title: 'Assistente que te guia. ',
      titleHighlight: 'Você executa.',
      subtitle:
          'IA com contexto do seu treino e progressão — '
          'recomendações claras, você decide o ritmo.',
      metrics: [
        OnboardingMetricCopy(value: 'Chat', label: 'Assistente IA'),
        OnboardingMetricCopy(value: 'IA', label: 'Progressão'),
        OnboardingMetricCopy(value: 'Form', label: 'Check vídeo'),
      ],
      features: [
        'Assistente IA para dúvidas de treino e execução',
        'Sugestões de progressão alinhadas ao seu histórico',
        'Form check para feedback do personal com vídeo',
      ],
    ),
    OnboardingSlideCopy(
      title: 'Mensalidade clara. ',
      titleHighlight: 'Treino liberado.',
      subtitle:
          'Veja status de pagamento, evite bloqueios e foque no que importa: '
          'resultado na academia.',
      metrics: [
        OnboardingMetricCopy(value: 'Status', label: 'Mensalidade'),
        OnboardingMetricCopy(value: 'PIX', label: 'Pagamento'),
        OnboardingMetricCopy(value: 'App', label: 'Tudo junto'),
      ],
      features: [
        'Minhas mensalidades com status claro por mês',
        'Sem surpresa: saiba se está em dia antes do treino',
        'Treino, chat e financeiro no mesmo lugar',
      ],
    ),
  ];

  @Deprecated('Use slidesFor(OnboardingPersona.personal)')
  static List<OnboardingSlideCopy> get onboardingSlides =>
      onboardingSlidesPersonal;
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
