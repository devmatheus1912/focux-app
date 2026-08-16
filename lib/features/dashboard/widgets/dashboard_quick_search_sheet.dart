import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../data/dashboard_tool_shortcuts.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_shortcut_navigation.dart';

/// Busca rápida: alunos + ferramentas do catálogo.
Future<void> showDashboardQuickSearchSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
}) {
  AnalyticsService.instance.track(ProductEvents.homeSearchOpened);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _QuickSearchSheet(isDark: isDark, primary: primary);
    },
  );
}

class _QuickSearchSheet extends ConsumerStatefulWidget {
  const _QuickSearchSheet({required this.isDark, required this.primary});

  final bool isDark;
  final Color primary;

  @override
  ConsumerState<_QuickSearchSheet> createState() => _QuickSearchSheetState();
}

class _QuickSearchSheetState extends ConsumerState<_QuickSearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final all = DashboardToolShortcut.moreTools;
    final tools =
        q.isEmpty
            ? all.take(8).toList()
            : all
                .where((t) => t.label.toLowerCase().contains(q))
                .take(12)
                .toList();
    final heading = BrandPalette.sectionHeading(
      widget.primary,
      dark: widget.isDark,
    );
    final mute = dashboardReadableCaption(context, isDark: widget.isDark);
    final ink =
        widget.isDark
            ? Theme.of(context).colorScheme.onSurface
            : TokensStrip.textPrimary;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Material(
          color:
              widget.isDark
                  ? const Color(0xFF101C2E)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                DashboardMicrocopy.buscaRapida,
                style: dashboardSectionTitleStyle(context, color: heading),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: DashboardMicrocopy.buscaRapidaHint,
                  prefixIcon: Icon(Icons.search, color: widget.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TokensStrip.rInput),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: FxIcon(
                  name: 'users',
                  color: widget.primary,
                  size: 20,
                ),
                title: Text(
                  q.isEmpty ? 'Ver alunos' : 'Buscar “$_query” em alunos',
                  style: FocuxHubTypography.cardTitle(color: ink),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  goPersonalShellTab(
                    context,
                    q.isEmpty
                        ? '/alunos'
                        : '/alunos?q=${Uri.encodeComponent(q)}',
                  );
                },
              ),
              const Divider(),
              Text(
                'Ferramentas',
                style: FocuxHubTypography.bodyMuted(color: mute),
              ),
              const SizedBox(height: 6),
              if (tools.isEmpty)
                Text(
                  DashboardMicrocopy.nenhumaFerramenta,
                  style: FocuxHubTypography.bodyMuted(color: mute),
                )
              else
                ...tools.map(
                  (t) => ListTile(
                    leading: FxIcon(
                      name: t.icon,
                      color: widget.primary,
                      size: 20,
                    ),
                    title: Text(
                      t.label,
                      style: FocuxHubTypography.cardTitle(color: ink),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      openDashboardShortcut(context, ref, t);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
