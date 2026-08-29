import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../utils/exercise_library_meta.dart';

/// Linha inset da biblioteca — paridade Perfil (48–52px, thumb opcional, check).
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
    this.onFavoriteToggle,
    this.uploadEnabled = true,
    this.picker = true,
    this.searchQuery = '',
    this.insetGroup = false,
  });

  final Exercicio exercicio;
  final VoidCallback onTap;
  final bool selected;
  final bool alreadyInTreino;
  final bool showDivider;
  final VoidCallback? onPreviewThumb;
  final VoidCallback? onUploadVideo;
  /// Segurar o card: favoritar/desfavoritar (preferido no picker).
  final VoidCallback? onFavoriteToggle;
  final bool uploadEnabled;
  final bool picker;
  final String searchQuery;
  final bool insetGroup;

  bool get _hasThumbMedia => exercisePreviewMediaUrlFor(exercicio) != null;

  double get _rowMinHeight => _hasThumbMedia ? 52 : 48;

  String _semanticLabel(String meta) {
    final base =
        selected
            ? '${exercicio.nomeDisplay}, selecionado. $meta'
            : alreadyInTreino
            ? '${exercicio.nomeDisplay}. $meta. Já no treino.'
            : '${exercicio.nomeDisplay}. $meta';
    final fav = exercicio.favoritado ? ' Favorito.' : '';
    final action =
        onFavoriteToggle != null
            ? ' Toque na estrela ou segure para ${exercicio.favoritado ? 'remover dos favoritos' : 'favoritar'}.'
            : '';
    return '$base$fav$action';
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final meta = exerciseLibraryMeta(exercicio);
    final hasPreview = onPreviewThumb != null && canPreviewExerciseMedia(exercicio);
    final dividerInset = insetGroup
        ? 0.0
        : (_hasThumbMedia ? 36.0 : 0.0) +
            (_hasThumbMedia ? FxSettingsLayout.iconGap : 0.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          selected: selected,
          label: _semanticLabel(meta),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            onLongPress:
                onFavoriteToggle != null ||
                        (onUploadVideo != null && uploadEnabled)
                    ? () {
                      if (onFavoriteToggle != null) {
                        HapticFeedback.mediumImpact();
                        onFavoriteToggle!();
                        return;
                      }
                      HapticFeedback.selectionClick();
                      onUploadVideo!();
                    }
                    : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: insetGroup ? 44 : _rowMinHeight,
              ),
              child: Row(
                children: [
                  if (_hasThumbMedia) ...[
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
                        size: 36,
                        radius: 10,
                        showPlayBadge: hasPreview,
                      ),
                    ),
                    const SizedBox(width: FxSettingsLayout.iconGap),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ExerciseTitle(
                          title: exercicio.nomeDisplay,
                          query: searchQuery,
                          ink: selected ? brand : ink,
                          highlight: brand,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: FxSettingsLayout.subhead(color: mute),
                              ),
                            ),
                            if (alreadyInTreino) ...[
                              const SizedBox(width: 6),
                              _InTreinoPill(mute: mute),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onFavoriteToggle != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      tooltip:
                          exercicio.favoritado
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        onFavoriteToggle!();
                      },
                      icon: Icon(
                        exercicio.favoritado
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color:
                            exercicio.favoritado ? EagleTokens.gold : mute,
                        size: 22,
                      ),
                    ),
                  if (selected)
                    Icon(Icons.check_rounded, color: brand, size: 20)
                  else if (!picker)
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
            padding: EdgeInsets.only(left: dividerInset),
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

class _ExerciseTitle extends StatelessWidget {
  const _ExerciseTitle({
    required this.title,
    required this.query,
    required this.ink,
    required this.highlight,
  });

  final String title;
  final String query;
  final Color ink;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim();
    if (normalized.length < 2) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FxSettingsLayout.rowLabel(color: ink),
      );
    }

    final lowerTitle = title.toLowerCase();
    final lowerQuery = normalized.toLowerCase();
    final index = lowerTitle.indexOf(lowerQuery);
    if (index < 0) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FxSettingsLayout.rowLabel(color: ink),
      );
    }

    final before = title.substring(0, index);
    final match = title.substring(index, index + normalized.length);
    final after = title.substring(index + normalized.length);

    return Text.rich(
      TextSpan(
        style: FxSettingsLayout.rowLabel(color: ink),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: FxSettingsLayout.rowLabel(
              color: highlight,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _InTreinoPill extends StatelessWidget {
  const _InTreinoPill({required this.mute});

  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: mute.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'No treino',
        style: FxSettingsLayout.footer(color: mute).copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
