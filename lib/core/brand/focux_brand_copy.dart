/// Copy de marca — fonte única para taglines e microcopy público.
abstract final class FocuxBrandCopy {
  static const tagline = onboardingHook;

  static const taglineShort = 'Personal e aluno juntos.';

  static const onboardingHook =
      'O app onde personal e aluno finalmente caminham juntos.';

  static const onboardingHookHighlight = 'caminham juntos.';

  /// Um slogan só, para Personal e Aluno (antes o do aluno era outro e deixava
  /// "app." sozinho na última linha).
  static const onboardingHookAluno = onboardingHook;

  static const onboardingHookAlunoHighlight = onboardingHookHighlight;

  /// Fallback neutro quando o pulse público não responde (sem número inventado).
  static const onboardingSocialProofFallback =
      'Personais e alunos treinando todo dia';

  static const onboardingCtaFinish = 'Começar grátis';

  static const onboardingCtaFinishHint = 'Grátis para começar · sem cartão';

  /// Aluno exige convite no register — CTA não promete "grátis sem fricção".
  static const onboardingCtaFinishAluno = 'Tenho um convite';

  static const onboardingCtaFinishHintAluno = 'Peça o link ao seu personal';

  static String onboardingFinishCta(OnboardingPersona persona) =>
      persona == OnboardingPersona.aluno
          ? onboardingCtaFinishAluno
          : onboardingCtaFinish;

  static String onboardingFinishHint(OnboardingPersona persona) =>
      persona == OnboardingPersona.aluno
          ? onboardingCtaFinishHintAluno
          : onboardingCtaFinishHint;

  static const authExistingAccountLead = 'Já tem conta? ';

  static const authExistingAccountAction = 'Entrar';

  /// Convite aluno — quem já tem conta não precisa de código.
  static const authInviteExistingAccountCta = 'Entrar na minha conta';

  static const onboardingPersonaPersonal = 'Personal';

  static const onboardingPersonaAluno = 'Aluno';

  /// Rótulos do seletor na primeira abertura (mesmo texto do login).
  static const onboardingSouPersonal = 'Sou personal';

  static const onboardingSouAluno = 'Sou aluno';

  static const alunoActivationReadyTitle = 'Tudo pronto para evoluir';

  static const alunoActivationReadyBody =
      'Sua base está fechada. Agora é treinar — seu personal vê tudo em tempo real.';

  static String onboardingTitulo(OnboardingPersona persona) =>
      persona == OnboardingPersona.aluno
          ? 'Seu treino, do jeito que seu personal montou.'
          : 'Seus alunos treinam. Você acompanha.';

  static List<OnboardingBeneficio> onboardingBeneficios(
    OnboardingPersona persona,
  ) =>
      persona == OnboardingPersona.aluno
          ? _beneficiosAluno
          : _beneficiosPersonal;

  static const _beneficiosPersonal = <OnboardingBeneficio>[
    OnboardingBeneficio(
      OnboardingIcone.treino,
      'Monte treinos e veja cada check-in',
    ),
    OnboardingBeneficio(
      OnboardingIcone.cobranca,
      'Cobre mensalidades por PIX, sem planilha',
    ),
    OnboardingBeneficio(
      OnboardingIcone.atencao,
      'Saiba quem precisa de atenção hoje',
    ),
  ];

  static const _beneficiosAluno = <OnboardingBeneficio>[
    OnboardingBeneficio(
      OnboardingIcone.video,
      'Veja o treino do dia e registre carga e séries em poucos toques',
    ),
    OnboardingBeneficio(
      OnboardingIcone.evolucao,
      'Acompanhe sua evolução e seus recordes',
    ),
    OnboardingBeneficio(
      OnboardingIcone.chat,
      'Fale com seu personal pelo app',
    ),
  ];
}

enum OnboardingPersona { personal, aluno }

/// Ícone de cada benefício; a tela resolve para um [IconData].
enum OnboardingIcone { treino, cobranca, atencao, video, evolucao, chat }

class OnboardingBeneficio {
  const OnboardingBeneficio(this.icone, this.texto);

  final OnboardingIcone icone;
  final String texto;
}
