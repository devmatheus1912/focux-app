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

part 'landing_editor_widgets_tabs.part.dart';
part 'landing_editor_widgets_templates.part.dart';


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
    return Semantics(
      container: true,
      label: '$title. $subtitle. Link: $displayLabel',
      child: Card(
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
                          color: scheme.onSurface.withValues(alpha: 0.72),
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
                Semantics(
                  button: true,
                  label: 'Copiar link $displayLabel',
                  child: IconButton.filledTonal(
                    tooltip: 'Copiar link',
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              LandingReadinessProgressBars(
                configDone: done,
                configTotal: items.length,
                textsReviewed: contentReviewedCount,
                textsTotal: contentReviewScope,
                contentIssueCount: contentIssueCount,
              ),
              const SizedBox(height: 6),
              Text(
                landingReadinessProgressHint(
                  configDone: done,
                  configTotal: items.length,
                  textsReviewed: contentReviewedCount,
                  textsTotal: contentReviewScope,
                  contentIssueCount: contentIssueCount,
                ),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
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
    this.configComplete = false,
    this.onReview,
  });

  final int reviewCount;
  final bool configComplete;
  final VoidCallback? onReview;

  static const _bg = Color(0xFFFFF4D6);
  static const _title = Color(0xFF7A5200);
  static const _body = Color(0xFF9A6700);
  static const _icon = Color(0xFFE6A800);

  @override
  Widget build(BuildContext context) {
    if (reviewCount <= 0) return const SizedBox.shrink();
    final summary = landingContentReviewBannerSummary(
      reviewCount,
      configComplete: configComplete,
    );

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
    this.badgeLabel,
    required this.expanded,
    required this.onExpandedChanged,
    this.onAdd,
    required this.child,
  });

  final String title;
  final String? hint;
  final String? badgeLabel;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback? onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      expanded: expanded,
      header: true,
      label: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(TokensStrip.rMd),
              onTap: () => onExpandedChanged(!expanded),
              focusColor: scheme.primary.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: TokensStrip.fontH2,
                                    letterSpacing: TokensStrip.trackingH2,
                                  ),
                                ),
                              ),
                              if (badgeLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: scheme.primaryContainer.withValues(alpha: 0.55),
                                  ),
                                  child: Text(
                                    badgeLabel!,
                                    style: TextStyle(
                                      fontSize: TokensStrip.fontBodySm,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (hint != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              hint!,
                              style: TokensStrip.bodyMuted(
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onAdd != null)
                      TextButton.icon(
                        onPressed: onAdd,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Adicionar'),
                      ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
      ),
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

  static const _labels = ['Links', 'Conteúdo', 'Ordem'];
  static const _compactLabels = ['Links', 'Textos', 'Ordem'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final labels = compact ? _compactLabels : _labels;

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
                      onTap: () {
                        if (index != i) {
                          HapticFeedback.selectionClick();
                        }
                        onChanged(i);
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
}

