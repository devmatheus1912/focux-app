part of 'aluno_detail_screen.dart';

class _AlunoRecoveryInsightCard extends StatelessWidget {
  const _AlunoRecoveryInsightCard({
    required this.recoveryAsync,
    required this.isDark,
    required this.primary,
  });

  final AsyncValue<RecoverySnapshot?> recoveryAsync;
  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return recoveryAsync.when(
      loading: () => const SizedBox.shrink(),
      error:
          (_, __) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: chrome.panel(radius: TokensStrip.rCard),
            child: Row(
              children: [
                Icon(Icons.watch_off_outlined, color: EagleTokens.warn, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Wearable indisponível',
                    style: TextStyle(
                      color: chrome.mute,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      data: (snapshot) {
        if (snapshot == null) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: chrome.panel(radius: TokensStrip.rCard),
            child: Row(
              children: [
                Icon(Icons.watch_outlined, color: primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sem dados de wearable hoje — peça ao aluno conectar Apple Health ou Google Fit.',
                    style: TextStyle(
                      color: chrome.mute,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Container(
          padding: const EdgeInsets.all(TokensStrip.s4),
          decoration: chrome.panel(
            radius: TokensStrip.rCard,
            accent: primary,
          ),
          child: Row(
              children: [
                RecoveryScoreRing(score: snapshot.recoveryScore, color: primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prontidão wearable',
                        style: TextStyle(
                          color: chrome.mute,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        snapshot.recoveryLabel,
                        style: TextStyle(
                          color: chrome.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot.recoveryHint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chrome.mute,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        );
      },
    );
  }
}
