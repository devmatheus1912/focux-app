part of 'aluno_detail_screen.dart';

class _AlunoDetailErrorState extends StatelessWidget {
  const _AlunoDetailErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: primary),
            const SizedBox(height: 14),
            Text(
              'Não foi possível carregar o aluno',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aluno360HeaderIconButton extends StatelessWidget {
  const _Aluno360HeaderIconButton({
    required this.onHero,
    required this.onPressed,
    required this.icon,
    this.iconSize = 18,
    this.tooltip,
  });

  final bool onHero;
  final VoidCallback onPressed;
  final IconData icon;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;

    final button = IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Container(
        width: 38,
        height: 38,
        decoration:
            onHero
                ? BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.26),
                  ),
                )
                : chrome.headerAction(radius: 12),
        child: Icon(
          icon,
          size: iconSize,
          color: onHero ? Colors.white : ink,
        ),
      ),
    );

    return button;
  }
}
