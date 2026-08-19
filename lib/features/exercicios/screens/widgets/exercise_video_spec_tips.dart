import 'package:flutter/material.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../utils/exercise_video_upload_spec.dart';

class ExerciseVideoSpecTips extends StatelessWidget {
  const ExerciseVideoSpecTips({
    super.key,
    required this.isDark,
    this.compact = false,
  });

  final bool isDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final tips =
        compact
            ? ExerciseVideoUploadSpec.tips.take(2).toList()
            : ExerciseVideoUploadSpec.tips;

    return Semantics(
      label:
          'Como filmar: ${ExerciseVideoUploadSpec.aspectLabel}, '
          '${ExerciseVideoUploadSpec.idealResolution}, '
          '${ExerciseVideoUploadSpec.durationLabel}, '
          '${ExerciseVideoUploadSpec.formatsLabel}, '
          '${ExerciseVideoUploadSpec.sizeLabel}.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Como filmar',
              style: FocuxHubTypography.sectionTitle(context, color: primary),
            ),
            SizedBox(height: TokensStrip.s1),
            Text(
              '${ExerciseVideoUploadSpec.idealResolution} · '
              '${ExerciseVideoUploadSpec.aspectLabel} · '
              '${ExerciseVideoUploadSpec.formatsLabel} · '
              '${ExerciseVideoUploadSpec.sizeLabel}',
              style: FocuxHubTypography.bodyMuted(
                color: chrome.mute,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            for (final tip in tips) ...[
              Text(
                tip.title,
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
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
              if (tip != tips.last) SizedBox(height: TokensStrip.s2),
            ],
          ],
        ),
      ),
    );
  }
}
