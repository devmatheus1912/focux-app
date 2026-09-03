import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/winback_repository.dart';
import '../utils/winback_display.dart';

final winbackRepositoryProvider = Provider(
  (ref) => WinbackRepository(ref.read(apiClientProvider)),
);

class WinbackScreen extends ConsumerStatefulWidget {
  const WinbackScreen({super.key});

  @override
  ConsumerState<WinbackScreen> createState() => _WinbackScreenState();
}

class _WinbackScreenState extends ConsumerState<WinbackScreen> {
  List<WinbackLogEntry> _entries = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final entries = await ref.read(winbackRepositoryProvider).log();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  void _abrirSaude() {
    HapticFeedback.selectionClick();
    context.push('/retencao');
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Win-back automático',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Win-back automático',
          subtitle: winbackHubSubtitle(freshness),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 5),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _carregar,
                )
                : FxContentWidthLimiter(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          Text(
            'Push automático para alunos inativos. Trial do personal não entra neste log.',
            style: FocuxHubTypography.bodyMuted(
              color: fxScreenMute(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Align(
            alignment: Alignment.centerLeft,
            child: DashboardHomeActionChip(
              label: 'Saúde da retenção',
              accent: primary,
              isDark: chrome.isDark,
              onPressed: _abrirSaude,
            ),
          ),
          const SizedBox(height: TokensStrip.s5),
          if (_entries.isEmpty)
            const FxEmptyState(
              icon: 'bell',
              title: 'Nenhum envio ainda',
              subtitle:
                  'Quando a automação disparar, os registros aparecem aqui.',
            )
          else ...[
            const DashboardSectionHeader(title: 'Envios'),
            const SizedBox(height: TokensStrip.s3),
            for (final entry in _entries)
              FxSatelliteListTile(
                title: winbackAlunoLabel(entry.alunoNome),
                subtitle: Text(
                  winbackSubtitle(
                    tipo: entry.tipo,
                    mensagem: entry.mensagem,
                  ),
                ),
                trailing: Text(
                  winbackWhenLabel(entry.enviadoEm),
                  style: FocuxHubTypography.bodyMuted(
                    color: fxScreenMute(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
