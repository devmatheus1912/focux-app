import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
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
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) => _QuickSearchSheet(isDark: isDark, primary: primary),
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
  final _focus = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _row({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final mute = dashboardReadableCaption(context, isDark: widget.isDark);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxHomeSheetChrome.touchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                FxIcon(name: icon, color: widget.primary, size: 18),
                SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mute, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
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
    final mute = dashboardReadableCaption(context, isDark: widget.isDark);

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: widget.isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: widget.isDark,
            title: DashboardMicrocopy.buscaRapida,
            subtitle: DashboardMicrocopy.buscaRapidaHint,
            leading: Icon(
              Icons.search_rounded,
              color: widget.primary,
              size: 18,
            ),
          ),
          SizedBox(height: TokensStrip.s3),
          TextField(
            controller: _controller,
            focusNode: _focus,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: DashboardMicrocopy.buscaRapidaHint,
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded, color: widget.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TokensStrip.rInput),
              ),
            ),
          ),
          SizedBox(height: TokensStrip.s3),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                _row(
                  icon: 'users',
                  label:
                      q.isEmpty ? 'Ver alunos' : 'Buscar “$_query” em alunos',
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
                SizedBox(height: TokensStrip.s2),
                Text(
                  'Ferramentas',
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
                const SizedBox(height: 4),
                if (tools.isEmpty)
                  Text(
                    DashboardMicrocopy.nenhumaFerramenta,
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  )
                else
                  ...tools.map(
                    (t) => _row(
                      icon: t.icon,
                      label: t.label,
                      onTap: () {
                        Navigator.pop(context);
                        openDashboardShortcut(context, ref, t);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
