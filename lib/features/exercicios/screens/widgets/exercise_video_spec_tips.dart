import 'package:flutter/material.dart';

import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/shell_chrome.dart';
import '../../../../core/theme/tokens_strip.dart';
import '../../../../core/widgets/fx_help.dart';
import '../../../../core/widgets/fx_shell_scaffold.dart';
import '../../utils/exercise_video_upload_spec.dart';

/// Resumo das specs + `?` da Home. O mural vai para [showFxHelpSheet].
class ExerciseVideoSpecTips extends StatelessWidget {
  const ExerciseVideoSpecTips({
    super.key,
    required this.isDark,
    this.embedded = false,
  });

  final bool isDark;
  final bool embedded;

  static String get summary =>
      '${ExerciseVideoUploadSpec.idealResolution} · '
      '${ExerciseVideoUploadSpec.aspectLabel} · '
      '${ExerciseVideoUploadSpec.formatsLabel} · '
      '${ExerciseVideoUploadSpec.sizeLabel}';

  static const _title = 'Como filmar';

  static Future<void> open(BuildContext context) {
    return showFxHelpSheet(
      context,
      title: _title,
      subtitle: summary,
      tips: [
        for (final tip in ExerciseVideoUploadSpec.tips)
          FxHelpTip(tip.title, tip.body, icon: tip.icon),
      ],
    );
  }

  Future<void> _open(BuildContext context) => open(context);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final pad =
        embedded
            ? const EdgeInsets.fromLTRB(2, 2, 0, 2)
            : const EdgeInsets.fromLTRB(12, 8, 8, 8);

    final row = Semantics(
      button: true,
      label: '$_title. $summary',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: FxHelpChrome.touchTarget),
        child: Padding(
          padding: pad,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _open(context),
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: FocuxHubTypography.sectionTitle(
                            context,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FxHelpIconButton(
                tooltip: _title,
                onTap: () => _open(context),
                expandHitTarget: true,
              ),
            ],
          ),
        ),
      ),
    );

    return embedded
        ? row
        : Container(
          decoration: fxListCardDecoration(context, accent: primary),
          child: row,
        );
  }
}
