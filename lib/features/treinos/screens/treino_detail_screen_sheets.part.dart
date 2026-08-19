part of 'treino_detail_screen.dart';

class _RemoveExerciseSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _RemoveExerciseSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final dangerSoft =
        isDark
            ? EagleTokens.bad.withValues(alpha: 0.16)
            : EagleTokens.badSoft.withValues(alpha: 0.88);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 10, 20, 18),
          decoration: _treinoHomeSheetDecoration(context, isDark: isDark),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: dangerSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: EagleTokens.bad,
                      size: 23,
                    ),
                  ),
                  SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover exercício?',
                          style: FocuxHubTypography.pageTitle(
                            context,
                            color: chrome.ink,
                          ).copyWith(fontWeight: FontWeight.w800, height: 1.15),
                        ),
                        SizedBox(height: TokensStrip.s2),
                        Text(
                          '$title sai apenas deste treino. O exercício continua na biblioteca.',
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: TokensStrip.s4),
              SizedBox(
                height: TreinosLayout.touchTarget,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: EagleTokens.bad,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Remover',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: TreinosLayout.touchTarget,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: chrome.mute,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteTrainingSheet extends StatelessWidget {
  final String title;
  final bool isDark;

  const _DeleteTrainingSheet({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final dangerSoft =
        isDark
            ? EagleTokens.bad.withValues(alpha: 0.16)
            : EagleTokens.badSoft.withValues(alpha: 0.88);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 10, 20, 18),
          decoration: _treinoHomeSheetDecoration(context, isDark: isDark),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: TokensStrip.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: dangerSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: EagleTokens.bad,
                      size: 23,
                    ),
                  ),
                  SizedBox(width: TokensStrip.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Excluir treino?',
                          style: FocuxHubTypography.pageTitle(
                            context,
                            color: chrome.ink,
                          ).copyWith(fontWeight: FontWeight.w800, height: 1.15),
                        ),
                        SizedBox(height: TokensStrip.s2),
                        Text(
                          '$title sai da biblioteca. Históricos já concluídos continuam preservados.',
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: TokensStrip.s4),
              SizedBox(
                height: TreinosLayout.touchTarget,
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: EagleTokens.bad,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Excluir',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: TreinosLayout.touchTarget,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: chrome.mute,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
