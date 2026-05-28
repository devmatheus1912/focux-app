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
    this.onReviewContent,
  });

  final List<LandingChecklistItem> items;
  final ValueChanged<LandingChecklistItem>? onItemTap;
  final int contentIssueCount;
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rLg),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
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
                landingReadinessSubtitle(contentIssueCount: contentIssueCount),
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 13,
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
              final tappable = onItemTap != null && landingChecklistTarget(item.id) != null;

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
                'Toque em um item para ir direto ao campo.',
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, TokensStrip.s4, 8),
      child: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (var i = 0; i < labels.length; i++)
            ButtonSegment(value: i, label: Text(labels[i])),
        ],
        selected: {index},
        onSelectionChanged: (value) => onChanged(value.first),
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
