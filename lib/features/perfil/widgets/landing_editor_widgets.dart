import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../data/landing_growth_repository.dart';
import '../screens/landing_editor_checklist.dart';
import '../screens/landing_editor_quality.dart';
import '../screens/landing_editor_sections.dart';
import '../screens/landing_section_templates.dart';

class LandingLinkCard extends StatelessWidget {
  const LandingLinkCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.displayLabel,
    required this.copyUrl,
    required this.onOpen,
    required this.onCopy,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String displayLabel;
  final String copyUrl;
  final VoidCallback onOpen;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rLg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.68),
                          height: 1.35,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(TokensStrip.rMd),
              ),
              child: Text(
                displayLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.01,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Ver como cliente'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Copiar link',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LandingChecklistCard extends StatelessWidget {
  const LandingChecklistCard({
    super.key,
    required this.items,
    this.onItemTap,
    this.contentIssueCount = 0,
    this.contentReviewScope = 0,
    this.contentReviewedCount = 0,
    this.onReviewContent,
  });

  final List<LandingChecklistItem> items;
  final ValueChanged<LandingChecklistItem>? onItemTap;
  final int contentIssueCount;
  final int contentReviewScope;
  final int contentReviewedCount;
  final VoidCallback? onReviewContent;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final done = items.where((e) => e.done).length;
    final scheme = Theme.of(context).colorScheme;
    final allReady = contentIssueCount == 0 && done == items.length;

    return Semantics(
      label: landingReadinessTitle(
        configDone: done,
        configTotal: items.length,
        contentIssueCount: contentIssueCount,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rLg),
            side: BorderSide(
              color: allReady
                  ? const Color(0xFF0F9D7A).withValues(alpha: 0.55)
                  : scheme.outlineVariant.withValues(alpha: 0.6),
              width: allReady ? 1.5 : 1,
            ),
          ),
          color: allReady
              ? const Color(0xFF0F9D7A).withValues(alpha: 0.06)
              : scheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                landingReadinessTitle(
                  configDone: done,
                  configTotal: items.length,
                  contentIssueCount: contentIssueCount,
                ),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                landingReadinessSubtitle(
                  contentIssueCount: contentIssueCount,
                  configDone: done,
                  configTotal: items.length,
                ),
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              LandingReadinessProgressBars(
                configDone: done,
                configTotal: items.length,
                textsReviewed: contentReviewedCount,
                textsTotal: contentReviewScope,
              ),
              if (contentIssueCount > 0 && onReviewContent != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onReviewContent,
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    label: Text(
                      contentIssueCount == 1
                          ? 'Revisar 1 texto'
                          : 'Revisar $contentIssueCount textos',
                    ),
                  ),
                ),
              ] else if (allReady) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      size: 16,
                      color: const Color(0xFF0F9D7A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Textos revisados',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F9D7A),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              ...items.map((item) {
                final label = landingChecklistLabel(item.id, item.label);
                final tappable =
                    onItemTap != null && landingChecklistTarget(item.id) != null;

                return ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                onTap: tappable ? () => onItemTap!(item) : null,
                leading: Icon(
                  item.done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: item.done ? const Color(0xFF0F9D7A) : scheme.outline,
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: item.done ? FontWeight.w600 : FontWeight.w500,
                    color: item.done
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                subtitle: tappable && !item.done
                    ? Text(
                        landingChecklistHint(item.id),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary.withValues(alpha: 0.85),
                        ),
                      )
                    : null,
                trailing: tappable
                    ? Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.35),
                      )
                    : null,
                );
              }),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class LandingChecklistSkeleton extends StatelessWidget {
  const LandingChecklistSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rLg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: 180,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 4; i++) ...[
              Row(
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              if (i < 3) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class LandingContentWarningBanner extends StatelessWidget {
  const LandingContentWarningBanner({
    super.key,
    required this.reviewCount,
    this.onReview,
  });

  final int reviewCount;
  final VoidCallback? onReview;

  static const _bg = Color(0xFFFFF4D6);
  static const _title = Color(0xFF7A5200);
  static const _body = Color(0xFF9A6700);
  static const _icon = Color(0xFFE6A800);

  @override
  Widget build(BuildContext context) {
    if (reviewCount <= 0) return const SizedBox.shrink();
    final summary = landingContentReviewBannerSummary(reviewCount);

    return Semantics(
      liveRegion: true,
      button: onReview != null,
      label: 'Revise antes de publicar. $summary',
      child: Material(
        color: _bg,
        child: InkWell(
          onTap: onReview,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 22,
                  color: _icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revise antes de publicar',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: _title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: _body,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onReview != null)
                  TextButton(
                    onPressed: onReview,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      foregroundColor: _title,
                    ),
                    child: const Text('Revisar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showLandingContentReviewSheet(
  BuildContext context, {
  required List<LandingContentIssue> issues,
  required ValueChanged<LandingContentIssue> onIssueTap,
  VoidCallback? onFocusMode,
}) {
  final scheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final maxHeight = MediaQuery.sizeOf(ctx).height * 0.55;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'O que revisar',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toque em um item ou use o modo foco para ver só o pendente.',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              if (onFocusMode != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onFocusMode();
                  },
                  icon: const Icon(Icons.center_focus_strong_outlined, size: 18),
                  label: const Text('Modo foco — só textos pendentes'),
                ),
              ],
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final issue = issues[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFE6A800),
                      ),
                      title: Text(
                        issue.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.35),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onIssueTap(issue);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class LandingHighlightCard extends StatelessWidget {
  const LandingHighlightCard({
    super.key,
    required this.highlighted,
    required this.child,
    this.issueHint,
  });

  final bool highlighted;
  final Widget child;
  final String? issueHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rMd),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: const Color(0xFFE6A800).withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rMd),
          side: BorderSide(
            color: highlighted
                ? const Color(0xFFE6A800).withValues(alpha: 0.75)
                : scheme.outlineVariant.withValues(alpha: 0.55),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        color: highlighted
            ? const Color(0xFFFFF4D6).withValues(alpha: 0.55)
            : scheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (issueHint != null && highlighted) ...[
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFF9A6700),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issueHint!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7A5200),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class LandingCollapsibleSection extends StatelessWidget {
  const LandingCollapsibleSection({
    super.key,
    required this.title,
    this.hint,
    required this.expanded,
    required this.onExpandedChanged,
    this.onAdd,
    required this.child,
  });

  final String title;
  final String? hint;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback? onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rMd),
          onTap: () => onExpandedChanged(!expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: TokensStrip.fontH2,
                          letterSpacing: TokensStrip.trackingH2,
                        ),
                      ),
                      if (hint != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          hint!,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onAdd != null)
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                  ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: child,
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class LandingEditorTabBar extends StatelessWidget {
  const LandingEditorTabBar({
    super.key,
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const labels = ['Links', 'Conteúdo', 'Ordem'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, TokensStrip.s4, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(TokensStrip.rMd),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: _LandingEditorTabChip(
                  label: labels[i],
                  selected: index == i,
                  onTap: () => onChanged(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LandingEditorTabChip extends StatelessWidget {
  const _LandingEditorTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rMd - 2),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(TokensStrip.rMd - 2),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? scheme.onPrimary : scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingStickySaveBar extends StatelessWidget {
  const LandingStickySaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dirty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Alterações não salvas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const FxLoading(size: 22, strokeWidth: 2)
                    : Text(dirty ? 'Salvar alterações' : 'Salvar landing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingSectionOrderTile extends StatelessWidget {
  const LandingSectionOrderTile({
    super.key,
    required this.index,
    required this.sectionKey,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.canMoveUp,
    required this.canMoveDown,
    this.highlighted = false,
  });

  final int index;
  final String sectionKey;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rMd),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.28),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Card(
        key: ValueKey('$sectionKey-$index'),
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rMd),
          side: BorderSide(
            color: highlighted
                ? scheme.primary.withValues(alpha: 0.75)
                : scheme.outlineVariant.withValues(alpha: 0.55),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        color: highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.22)
            : scheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landingSectionLabel(sectionKey),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mover para cima',
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
              IconButton(
                tooltip: 'Mover para baixo',
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingReadinessProgressBars extends StatelessWidget {
  const LandingReadinessProgressBars({
    super.key,
    required this.configDone,
    required this.configTotal,
    required this.textsReviewed,
    required this.textsTotal,
  });

  final int configDone;
  final int configTotal;
  final int textsReviewed;
  final int textsTotal;

  @override
  Widget build(BuildContext context) {
    const ready = Color(0xFF0F9D7A);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _ProgressRow(
          label: 'Configuração',
          value: configTotal == 0 ? 0 : configDone / configTotal,
          caption: '$configDone/$configTotal',
          color: ready,
          track: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          label: 'Textos revisados',
          value: textsTotal == 0 ? 1 : textsReviewed / textsTotal,
          caption: '$textsReviewed/$textsTotal',
          color: ready,
          track: scheme.surfaceContainerHighest,
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.track,
  });

  final String label;
  final double value;
  final String caption;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $caption',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              minHeight: 6,
              backgroundColor: track.withValues(alpha: 0.85),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class LandingReviewFocusBanner extends StatelessWidget {
  const LandingReviewFocusBanner({
    super.key,
    required this.pendingCount,
    required this.onExit,
  });

  final int pendingCount;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              Icons.center_focus_strong_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pendingCount == 1
                    ? 'Modo foco · 1 texto pendente'
                    : 'Modo foco · $pendingCount textos pendentes',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
            TextButton(onPressed: onExit, child: const Text('Ver tudo')),
          ],
        ),
      ),
    );
  }
}

class LandingSectionTemplatesPanel extends StatelessWidget {
  const LandingSectionTemplatesPanel({
    super.key,
    required this.sectionOrder,
    required this.onApplyDefault,
    required this.onApplyPreset,
    required this.presets,
    this.applying = false,
  });

  final List<String> sectionOrder;
  final VoidCallback onApplyDefault;
  final ValueChanged<LandingNichePreset> onApplyPreset;
  final List<LandingNichePreset> presets;
  final bool applying;

  IconData _iconFor(String name) {
    return switch (name) {
      'person' => Icons.person_outline_rounded,
      'fitness' => Icons.fitness_center_outlined,
      'route' => Icons.route_outlined,
      'payments' => Icons.payments_outlined,
      'reviews' => Icons.reviews_outlined,
      'photo_library' => Icons.photo_library_outlined,
      'help' => Icons.help_outline_rounded,
      'chat' => Icons.chat_bubble_outline_rounded,
      _ => Icons.view_agenda_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final activeKeys = sectionOrder.map(normalizeLandingSectionKey).toSet();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rLg),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Modelo completo da landing',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Sua página tem 8 seções editáveis. Use um modelo para preencher textos de abertura, serviços, FAQ e botões.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: scheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 12),
            for (final section in landingSectionTemplateCatalog) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconFor(section.iconName),
                    size: 18,
                    color: activeKeys.contains(section.key)
                        ? const Color(0xFF0F9D7A)
                        : scheme.outline,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          section.description,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: scheme.onSurface.withValues(alpha: 0.62),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ex.: ${section.example}',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: applying ? null : onApplyDefault,
              icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
              label: const Text('Aplicar modelo padrão Focux'),
            ),
            if (presets.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Modelos por nicho',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preenche abertura, serviços, dúvidas, botões e ordem das seções.',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final preset in presets)
                    ActionChip(
                      label: Text(preset.label),
                      onPressed: applying ? null : () => onApplyPreset(preset),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> copyLandingLink(
  BuildContext context, {
  required String url,
  required String successMessage,
}) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  FeedbackHelper.showSuccess(context, successMessage);
}

Future<void> openLandingLink(
  BuildContext context, {
  required String url,
}) async {
  try {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
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
