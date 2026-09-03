part of 'pacotes_storefront_widgets.dart';

class _PacoteTag extends StatelessWidget {
  const _PacoteTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: FocuxHubTypography.bodyMuted(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Estado de erro com retry — delega ao canônico [FxErrorState].
class PacotesLoadErrorState extends StatelessWidget {
  const PacotesLoadErrorState({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return FxErrorState(
      chromeOnDark: Theme.of(context).brightness == Brightness.dark,
      primary: Theme.of(context).colorScheme.primary,
      title: 'Não foi possível carregar seus planos',
      message: message ?? 'Verifique sua conexão e tente novamente.',
      onRetry: onRetry,
    );
  }
}

void copyStorefrontLink(BuildContext context, String? slug) {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para gerar o link da sua página de vendas.',
    );
    return;
  }
  Clipboard.setData(ClipboardData(text: Env.landingPageUrl(slug)));
  FeedbackHelper.showSuccess(context, 'Link copiado!');
}

Future<void> openStorefrontPreview(BuildContext context, String? slug) async {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para abrir sua página de vendas.',
    );
    return;
  }
  final uri = Uri.parse(Env.landingPageUrl(slug));
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (opened) {
      FeedbackHelper.showInfo(context, 'Abrindo como seu cliente vê…');
    } else {
      FeedbackHelper.showWarn(context, 'Não foi possível abrir o link.');
    }
  } catch (_) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, 'Não foi possível abrir a página.');
  }
}

