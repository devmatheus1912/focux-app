import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/relatorio_repository.dart';
import '../utils/relatorio_global_display.dart';
import '../widgets/relatorio_global_help_sheet.dart';

class RelatorioGlobalScreen extends ConsumerStatefulWidget {
  const RelatorioGlobalScreen({super.key});

  @override
  ConsumerState<RelatorioGlobalScreen> createState() =>
      _RelatorioGlobalScreenState();
}

class _RelatorioGlobalScreenState extends ConsumerState<RelatorioGlobalScreen> {
  final _openedAt = DateTime.now();
  ResumoGlobal? _dados;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final dados = await RelatorioRepository(
        ref.read(apiClientProvider),
      ).resumoGlobal();
      if (!mounted) return;
      setState(() {
        _dados = dados;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    final dados = _dados;
    AnalyticsService.instance.track(
      ProductEvents.relatoriosHubViewed,
      props: {
        'alunos': dados?.totalAlunos ?? 0,
        'media': dados?.aderenciaMediaGeral ?? 0,
      },
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.relatoriosHubTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
          'alunos': dados?.totalAlunos ?? 0,
        },
      );
    }
  }

  void _abrirRelatorioAluno(ResumoAluno aluno) {
    context.push(
      '/alunos/${aluno.alunoId}/relatorio',
      extra: aluno.alunoNome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final dados = _dados;

    return fxScreenA11yScope(
      label: 'Relatórios',
      child: FeatureGate(
        featureName: 'Relatórios',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'relatorios',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Relatórios',
            subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
            onBack: () => safePopOrGo(context, '/dashboard/personal'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como ler os relatórios',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.relatoriosHubHelpOpened,
                  );
                  showRelatorioGlobalHelpSheet(context);
                },
              ),
            ],
          ),
          body: _loading
              ? const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 6),
              )
              : _erro != null
              ? FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: _erro!,
                onRetry: _load,
              )
              : RefreshIndicator(
                color: primary,
                onRefresh: () async {
                  AnalyticsService.instance.track(
                    ProductEvents.relatoriosHubRefreshed,
                  );
                  await _load();
                },
                child: dados == null || dados.totalAlunos == 0
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: FxEmptyState(
                            icon: 'users',
                            title: 'Nenhum aluno na base',
                            subtitle:
                                'Quando houver alunos, a média de aderência e os rankings aparecem aqui.',
                            action: FxEmptyAction(
                              label: 'Ver alunos',
                              onTap: () => context.go('/alunos'),
                            ),
                          ),
                        ),
                      ],
                    )
                    : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        8,
                        FxSettingsLayout.pageInset,
                        110,
                      ),
                      children: [
                        const DashboardSectionHeader(title: 'Base'),
                        const SizedBox(height: TokensStrip.s3),
                        OperationalMetricTile(
                          label: 'Aderência média',
                          value: relatorioAderenciaMediaLabel(
                            dados.aderenciaMediaGeral,
                          ),
                          hint: 'Média de todos os alunos, não só do ranking',
                          color: primary,
                          isDark: isDark,
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        InkWell(
                          onTap: () => context.go('/alunos'),
                          borderRadius: BorderRadius.circular(12),
                          child: OperationalMetricTile(
                            label: 'Alunos',
                            value: '${dados.totalAlunos}',
                            hint: 'Abrir a lista da base',
                            color: primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s5),
                        const DashboardSectionHeader(
                          title: 'Mais comprometidos',
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Text(
                          'Toque para o relatório do aluno.',
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        ..._rankingTiles(
                          dados.maisComprometidos,
                          emptyLabel: 'Ainda não há treinos concluídos',
                          attention: false,
                        ),
                        const SizedBox(height: TokensStrip.s5),
                        const DashboardSectionHeader(
                          title: 'Precisam de atenção',
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Text(
                          'Priorize contato. Isso não é o motor de alertas.',
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        ..._rankingTiles(
                          dados.menosComprometidos,
                          emptyLabel: 'Ninguém precisa de atenção extra',
                          attention: true,
                        ),
                      ],
                    ),
              ),
        ),
      ),
    );
  }

  List<Widget> _rankingTiles(
    List<ResumoAluno> alunos, {
    required String emptyLabel,
    required bool attention,
  }) {
    if (alunos.isEmpty) {
      return [
        FxSatelliteListTile(title: emptyLabel),
      ];
    }
    return [
      for (var i = 0; i < alunos.length; i++)
        Semantics(
          label:
              '${alunos[i].alunoNome}. '
              '${relatorioAderenciaPercentLabel(alunos[i].treinosConcluidos, alunos[i].totalTreinos)}. '
              '${relatorioTreinosSubtitle(alunos[i].treinosConcluidos, alunos[i].totalTreinos)}. '
              '${relatorioUltimoTreinoLabel(alunos[i].ultimoTreino)}',
          button: true,
          child: FxSatelliteListTile(
            title: alunos[i].alunoNome,
            subtitle: Text(
              relatorioTreinosSubtitle(
                alunos[i].treinosConcluidos,
                alunos[i].totalTreinos,
              ),
            ),
            trailing: Text(
              relatorioAderenciaPercentLabel(
                alunos[i].treinosConcluidos,
                alunos[i].totalTreinos,
              ),
              style: FocuxHubTypography.bodyMuted(
                color: attention &&
                        alunos[i].totalTreinos > 0 &&
                        alunos[i].treinosConcluidos * 100 <
                            alunos[i].totalTreinos * 50
                    ? EagleTokens.bad
                    : fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: !attention && i == 0
                ? Theme.of(context).colorScheme.primary
                : attention &&
                        alunos[i].totalTreinos > 0 &&
                        alunos[i].treinosConcluidos * 100 <
                            alunos[i].totalTreinos * 50
                    ? EagleTokens.bad
                    : null,
            onTap: () => _abrirRelatorioAluno(alunos[i]),
          ),
        ),
    ];
  }
}
