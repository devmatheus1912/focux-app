import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../utils/exercise_video_upload_spec.dart';

class ExerciseVideoSpecTips extends StatefulWidget {
  const ExerciseVideoSpecTips({
    super.key,
    required this.isDark,
    this.compact = false,
    this.initiallyExpanded = false,
  });

  final bool isDark;
  final bool compact;
  final bool initiallyExpanded;

  @override
  State<ExerciseVideoSpecTips> createState() => _ExerciseVideoSpecTipsState();
}

class _ExerciseVideoSpecTipsState extends State<ExerciseVideoSpecTips> {
  late bool _expanded;

  static String get _summary =>
      '${ExerciseVideoUploadSpec.idealResolution} · '
      '${ExerciseVideoUploadSpec.aspectLabel} · '
      '${ExerciseVideoUploadSpec.formatsLabel} · '
      '${ExerciseVideoUploadSpec.sizeLabel}';

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoSpecTips oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded &&
        widget.initiallyExpanded) {
      _expanded = true;
    }
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(widget.isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final tips =
        widget.compact
            ? ExerciseVideoUploadSpec.tips.take(2).toList()
            : ExerciseVideoUploadSpec.tips;

    return Semantics(
      container: true,
      label:
          _expanded
              ? 'Como filmar, detalhes abertos. $_summary.'
              : 'Como filmar, recolhido. $_summary.',
      child: Container(
        decoration: fxListCardDecoration(context, accent: primary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
                child: Semantics(
                  button: true,
                  label:
                      _expanded
                          ? 'Recolher como filmar'
                          : 'Expandir como filmar. $_summary',
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Como filmar',
                                  style: FocuxHubTypography.sectionTitle(
                                    context,
                                    color: primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _summary,
                                  style: FocuxHubTypography.bodyMuted(
                                    color: chrome.mute,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: chrome.mute,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration:
                  reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child:
                  _expanded
                      ? Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final tip in tips) ...[
                              Text(
                                tip.title,
                                style: FocuxHubTypography.cardTitle(
                                  color: chrome.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tip.body,
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (tip != tips.last)
                                SizedBox(height: TokensStrip.s2),
                            ],
                          ],
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
