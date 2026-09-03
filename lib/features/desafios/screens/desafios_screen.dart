import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

final _repo = Provider((ref) => DesafioRepository(ref.read(apiClientProvider)));

class DesafiosScreen extends ConsumerStatefulWidget {
  const DesafiosScreen({super.key});

  @override
  ConsumerState<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends ConsumerState<DesafiosScreen> {
  List<Desafio> _desafios = [];
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _desafios = await ref.read(_repo).listar();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _criar() async {
    final ctrl = TextEditingController();
    var created = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Novo desafio',
        icon: Icons.flag_outlined,
        confirmLabel: 'Criar',
        child: AlunoInsetFormField(
          controller: ctrl,
          label: 'Título',
          icon: Icons.title_outlined,
          showDivider: false,
        ),
      );
      if (ok != true || ctrl.text.trim().isEmpty) return;
      await ref.read(_repo).criar(titulo: ctrl.text.trim());
      created = true;
      if (mounted) FeedbackHelper.showSuccess(context, 'Desafio criado');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      ctrl.dispose();
    }
    if (created) await _load();
  }

  Future<void> _abrirLeaderboard(Desafio d) async {
    try {
      final lb = await ref.read(_repo).leaderboard(d.id);
      if (!mounted) return;
      showFxHomeSheet<void>(
        context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primary = Theme.of(ctx).colorScheme.primary;
          return FxHomeSheetSurface(
            isDark: isDark,
            expand: true,
            maxHeight:
                MediaQuery.sizeOf(ctx).height *
                FxHomeSheetChrome.expandHeightFactor,
            child: Column(
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: FxSettingsLayout.headerToGroup),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Ranking',
                  subtitle: d.titulo,
                  leading: Icon(Icons.emoji_events_outlined, color: primary, size: 18),
                ),
                SizedBox(height: FxSettingsLayout.headerToGroup),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      24,
                    ),
                    children: [
                      if (lb.isEmpty)
                        Text(desafioLeaderboardEmpty())
                      else
                        FxSettingsGroup(
                          header: 'Participantes',
                          children: [
                            for (var i = 0; i < lb.length; i++)
                              FxSettingsTile(
                                fxIcon: 'star',
                                label: desafioLeaderboardName(
                                  lb[i]['alunoNome'] as String?,
                                ),
                                subtitle: '${i + 1}º lugar',
                                value: desafioLeaderboardPoints(lb[i]['pontos']),
                                numeric: true,
                                showDivider: i != lb.length - 1,
                                onTap: () {},
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Desafios',
      child: FeatureGate(
        featureName: 'Desafios',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'comunidadeGrupos',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Desafios',
            subtitle: desafioHubSubtitle(freshnessLabel),
            actions: [
              ShellHeaderIconButton(
                icon: 'plus',
                tooltip: 'Novo desafio',
                onTap: _criar,
              ),
            ],
          ),
          body:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                  : _error != null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: scheme.primary,
                    message: _error!,
                    onRetry: _load,
                  )
                  : FxContentWidthLimiter(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          if (_desafios.isEmpty)
            FxEmptyState(
              icon: 'spark',
              title: 'Nenhum desafio',
              subtitle: 'Crie o primeiro desafio para engajar seus alunos.',
              action: FxEmptyAction(label: 'Criar desafio', onTap: _criar),
            )
          else ...[
            const DashboardSectionHeader(title: 'Desafios ativos'),
            const SizedBox(height: TokensStrip.s2),
            Text(
              'Toque para ver o ranking.',
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            for (final desafio in _desafios)
              FxSatelliteListTile(
                title: desafio.titulo,
                subtitle: Text(
                  desafioSubtitle(
                    tipo: desafio.tipo,
                    metaPontos: desafio.metaPontos,
                  ),
                ),
                trailing: Text(
                  '${desafio.metaPontos}',
                  style: FocuxHubTypography.bodyMuted(
                    color: fxScreenMute(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => _abrirLeaderboard(desafio),
              ),
          ],
        ],
      ),
    );
  }
}
