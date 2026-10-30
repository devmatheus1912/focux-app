part of 'onboarding_wizard_screen.dart';

extension on _OnboardingWizardScreenState {
  Future<void> _abrirAjuda() {
    return showFxHelpSheet(
      context,
      title: wizardHelpTitle(),
      subtitle: wizardHelpSubtitle(),
      tips: [
        FxHelpTip('Passos', wizardHelpPassosBody(), icon: 'route'),
        FxHelpTip('Concluir', wizardHelpConcluirBody(), icon: 'circle-check'),
      ],
    );
  }

  Future<void> _concluir() async {
    if (_concluindo) return;
    setState(() => _concluindo = true);
    HapticFeedback.heavyImpact();
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.setupWizardCompleted,
        props: {
          'completed': _wizard?.completedCount,
          'total': _wizard?.totalCount,
        },
      ),
    );
    try {
      await OnboardingRepository(ref.read(apiClientProvider)).marcarCompleto();
      _evictHomeCaches();
      if (mounted) context.go('/dashboard/personal');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _concluindo = false);
    }
  }
}
