import '../../../l10n/pt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/screens/widgets/exercise_media_thumb.dart';
import '../../exercicios/utils/biblioteca_aba.dart';
import '../utils/exercise_library_meta.dart';
import '../../../core/theme/fx_icons.dart';

/// Linha inset da biblioteca — paridade Perfil (48–52px, thumb opcional, check).
class ExerciseLibraryRow extends StatelessWidget {
  const ExerciseLibraryRow({
    super.key,
    required this.exercicio,
    required this.onTap,
    this.selected = false,
    this.alreadyInTreino = false,
    this.alerta,
    this.resumoNoTreino,
    this.showDivider = true,
    this.onPreviewThumb,
    this.onUploadVideo,
    this.onFavoriteToggle,
    this.uploadEnabled = true,
    this.picker = true,
    this.searchQuery = '',
    this.insetGroup = false,
    this.titulo,
    this.marcado = false,
    this.onMarcar,
  });

  /// Texto da linha quando o começo do nome virou cabeçalho do grupo
  /// ("com halteres"). O leitor de tela lê o nome inteiro.
  final String? titulo;

  /// Marcado para adicionar junto (o "+" vira check).
  final bool marcado;

  /// "+" à direita: marca para adicionar vários de uma vez.
  final VoidCallback? onMarcar;

  final Exercicio exercicio;
  final VoidCallback onTap;
  final bool selected;
  final bool alreadyInTreino;

  /// Prescrição aplicada, quando o exercício já está no treino ("3 × 10-12").
  final String? resumoNoTreino;
  final bool showDivider;
  final VoidCallback? onPreviewThumb;

  /// "Atenção: joelho": região do aluno citada nas contraindicações. Só aviso.
  final String? alerta;
  final VoidCallback? onUploadVideo;

  /// Segurar o card: favoritar/desfavoritar (preferido no picker).
  final VoidCallback? onFavoriteToggle;
  final bool uploadEnabled;
  final bool picker;
  final String searchQuery;
  final bool insetGroup;

  bool get _hasThumbMedia => exercisePreviewMediaUrlFor(exercicio) != null;

  double get _rowMinHeight => 52;

  String _semanticLabel(String meta) {
    final base =
        selected || marcado
            ? '${exercicio.nomeDisplay}, selecionado. $meta'
            : alreadyInTreino
            ? '${exercicio.nomeDisplay}. $meta. Já no treino${resumoNoTreino == null ? '' : ', $resumoNoTreino'}.'
            : '${exercicio.nomeDisplay}. $meta';
    final fav = exercicio.favoritado ? ' Favorito.' : '';
    final action =
        onFavoriteToggle != null
            ? ' Segure para ${exercicio.favoritado ? 'remover dos favoritos' : 'favoritar'}.'
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
    final meta = [
      exerciseLibraryMeta(exercicio),
      if (!_hasThumbMedia) 'Vídeo em breve',
    ].where((p) => p.isNotEmpty).join(' · ');
    final hasPreview =
        onPreviewThumb != null && canPreviewExerciseMedia(exercicio);
    // Toda linha reserva o quadrado da foto: a coluna dos nomes não zigue-zagueia.
    final dividerInset =
        insetGroup ? 0.0 : 36.0 + FxSettingsLayout.iconGap;

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
                  if (!_hasThumbMedia) ...[
                    _QuadradoSemFoto(exercicio: exercicio, mute: mute, line: line),
                    const SizedBox(width: FxSettingsLayout.iconGap),
                  ] else ...[
                    Semantics(
                      button: hasPreview,
                      label:
                          hasPreview
                              ? ptS.a11yVerDemonstracao(exercicio.nomeDisplay)
                              : null,
                      child: GestureDetector(
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
                          // Quase todo exercício tem vídeo: o selo só fazia ruído.
                          showPlayBadge: false,
                        ),
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
                          title: titulo ?? exercicio.nomeDisplay,
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
                            if (!alreadyInTreino &&
                                !videoFocuxIntocado(exercicio)) ...[
                              const SizedBox(width: 6),
                              _MeuPill(brand: brand),
                            ],
                            if (alreadyInTreino) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: _InTreinoPill(
                                  mute: mute,
                                  resumo: resumoNoTreino,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (alerta != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  FxIcons.alertaPequeno,
                                  size: 14,
                                  color: EagleTokens.warn,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    alerta!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FxSettingsLayout.subhead(
                                      color: EagleTokens.warn,
                                    ).copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Estrela só nos favoritos (favoritar é segurar a linha).
                  if (exercicio.favoritado)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        FxIcons.estrelaAtiva,
                        color: EagleTokens.gold,
                        size: 18,
                        semanticLabel: 'Favorito',
                      ),
                    ),
                  if (onMarcar != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      tooltip: marcado
                          ? 'Desmarcar ${exercicio.nomeDisplay}'
                          : 'Marcar ${exercicio.nomeDisplay}',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onMarcar!();
                      },
                      icon: Icon(
                        marcado ? FxIcons.concluidoAtivo : FxIcons.adicionarCirculo,
                        color: marcado ? brand : mute,
                        size: 24,
                      ),
                    ),
                  if (selected && onMarcar == null)
                    Icon(FxIcons.check, color: brand, size: 20)
                  else if (!picker)
                    Icon(
                      FxIcons.chevronDireita,
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
        maxLines: 2,
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
        maxLines: 2,
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
            ).copyWith(fontWeight: FontWeight.w700),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Quadrado da foto quando o exercício não tem mídia: ícone do equipamento.
class _QuadradoSemFoto extends StatelessWidget {
  const _QuadradoSemFoto({
    required this.exercicio,
    required this.mute,
    required this.line,
  });

  final Exercicio exercicio;
  final Color mute;
  final Color line;

  @override
  Widget build(BuildContext context) {
    // Um ícone só para quem não tem mídia: o halter, sem fingir informação.
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: line),
        ),
        child: Icon(
          FxIcons.treino,
          size: 18,
          color: mute,
        ),
      ),
    );
  }
}

/// Marca os exercícios do próprio personal no meio dos da Focux.
class _MeuPill extends StatelessWidget {
  const _MeuPill({required this.brand});

  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Seu',
        style: FxSettingsLayout.footer(
          color: brand,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _InTreinoPill extends StatelessWidget {
  const _InTreinoPill({required this.mute, this.resumo});

  final Color mute;
  final String? resumo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: mute.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        resumo == null || resumo!.isEmpty ? 'No treino' : 'No treino · $resumo',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: FxSettingsLayout.footer(
          color: mute,
        ).copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
