import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../utils/exercise_library_meta.dart';

/// Linha inset da biblioteca — paridade Perfil (52px, thumb, chevron).
class ExerciseLibraryRow extends StatelessWidget {
  const ExerciseLibraryRow({
    super.key,
    required this.exercicio,
    required this.onTap,
    this.selected = false,
    this.alreadyInTreino = false,
    this.showDivider = true,
    this.onPreviewThumb,
    this.onUploadVideo,
    this.uploadEnabled = true,
    this.picker = true,
  });

  final Exercicio exercicio;
  final VoidCallback onTap;
  final bool selected;
  final bool alreadyInTreino;
  final bool showDivider;
  final VoidCallback? onPreviewThumb;
  final VoidCallback? onUploadVideo;
  final bool uploadEnabled;
  final bool picker;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final meta = exerciseLibraryMeta(exercicio, alreadyInTreino: alreadyInTreino);
    final hasPreview = onPreviewThumb != null && canPreviewExerciseMedia(exercicio);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          selected: selected,
          label:
              selected
                  ? '${exercicio.nomeDisplay}, selecionado. $meta'
                  : '${exercicio.nomeDisplay}. $meta',
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            onLongPress:
                onUploadVideo == null
                    ? null
                    : () {
                      HapticFeedback.selectionClick();
                      if (uploadEnabled) onUploadVideo!();
                    },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FxSettingsLayout.rowMinHeight,
              ),
              child: Row(
                children: [
                    GestureDetector(
                      onTap:
                          hasPreview
                              ? () {
                                HapticFeedback.selectionClick();
                                onPreviewThumb!();
                              }
                              : null,
                      child: ExerciseMediaThumb.fromExercicio(
                        exercicio,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: FxSettingsLayout.iconGap),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercicio.nomeDisplay,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.rowLabel(
                              color: selected ? brand : ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.subhead(color: mute),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_rounded, color: brand, size: 20)
                    else if (picker)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: mute,
                        size: FxSettingsLayout.chevronSize,
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(
              left: 40 + FxSettingsLayout.iconGap,
            ),
            child: Divider(
              height: FxSettingsLayout.dividerThickness,
              thickness: FxSettingsLayout.dividerThickness,
              color: line,
            ),
          ),
      ],
    );
  }
}
