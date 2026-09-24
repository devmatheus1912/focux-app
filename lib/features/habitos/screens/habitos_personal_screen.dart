import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';
import '../widgets/habito_novo_sheet.dart';

final _repoProvider = Provider(
  (ref) => HabitoRepository(ref.read(apiClientProvider)),
);

class HabitosPersonalScreen extends ConsumerStatefulWidget {
  const HabitosPersonalScreen({super.key});

  @override
  ConsumerState<HabitosPersonalScreen> createState() =>
      _HabitosPersonalScreenState();
}

class _HabitosPersonalScreenState extends ConsumerState<HabitosPersonalScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  var _query = '';
  List<Habito> _habitos = [];
  List<ComplianceItem> _compliance = [];
  PlanoFeatures? _planoFromHome;
  var _page = 0;
  var _hasMore = false;
  var _totalCompliance = 0;
  var _loading = true;
  var _carregandoMais = false;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == _query) return;
      _query = next;
      _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(_repoProvider).getHome(q: _query);
      if (!mounted) return;
      setState(() {
        _habitos = home.habitos;
        _compliance = home.compliance;
        _planoFromHome = home.planoFeatures;
        _page = home.page;
        _hasMore = home.hasNext;
        _totalCompliance = home.totalCompliance;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final home = await ref
          .read(_repoProvider)
          .getHome(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _compliance.map((c) => c.alunoId).toSet();
      setState(() {
        _compliance = [
          ..._compliance,
          ...home.compliance.where((c) => seen.add(c.alunoId)),
        ];
        _page = home.page;
        _hasMore = home.hasNext;
        _totalCompliance = home.totalCompliance;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
    }
  }

  Future<void> _novoHabito() async {
    final created = await showHabitoNovoSheet(
      context: context,
      repo: ref.read(_repoProvider),
      loadAlunos: () => ref.read(alunoRepositoryProvider).listar(),
    );
    if (!created || !mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.habitoCreated,
      props: {'feature': 'habitos'},
    );
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final planoFromHome = _planoFromHome;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Hábitos & Compliance',
      child: FeatureGate(
        featureName: 'Habit Coaching',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'habitCoaching',
        child: PopScope(
          canPop: !keyboardOpen,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            FxKeyboardDismissScope.dismiss();
          },
          child: FxShellScaffold(
          useMesh: true,
          safeArea: false,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Hábitos & Compliance',
            subtitle: FxHubFreshness.joinCount(
              habitoCountLabel(_loading ? 0 : _habitos.length),
              _loading ? null : freshnessLabel,
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/perfil/ferramentas');
            },
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar os hábitos',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Hábitos',
                  subtitle: 'Metas diárias da base e quem está cumprindo.',
                  tips: const [
                    FxHelpTip('Como calculamos', habitoComoCalculamos),
                    FxHelpTip(
                      'Lista',
                      'Toque no hábito para abrir. Desativar fica no detalhe.',
                    ),
                    FxHelpTip(
                      'Novo',
                      'O criar no rodapé abre para todos ou para um aluno só.',
                    ),
                  ],
                ),
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
                    primary: primary,
                    message: _error!,
                    onRetry: _carregar,
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: FxContentWidthLimiter(child: _buildBody()),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2 +
                                MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: FxLiquidPrimaryButton(
                            label: 'Novo hábito',
                            onPressed: _novoHabito,
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
        ),
      ),
    );
  }

  List<Widget> get _habitoRows {
    final mute = fxScreenMute(context);
    final isDark = ShellChrome.of(context).isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final focus = habitoFocusCompliance(_compliance);
    final focusDanger =
        focus != null && habitoComplianceDanger(focus.compliancePct);
    final complianceRows = habitoComplianceListExcludingFocus(
      _compliance,
      focusDanger ? focus : null,
    );

    return [
      if (focusDanger) ...[
        FxStripCard(
          emphasize: true,
          semanticsLabel:
              'Compliance baixa: ${habitoComplianceLabel(focus.alunoNome)}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quem precisa de atenção',
                style: FocuxHubTypography.chip(mute),
              ),
              const SizedBox(height: 6),
              Text(
                habitoComplianceLabel(focus.alunoNome),
                style: FocuxHubTypography.kpi(
                  color: ShellChrome.of(context).ink,
                  fontSize: FocuxHubTypography.metricLg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${habitoComplianceValue(focus.compliancePct)} · ${habitoComplianceSubtitle(focus.checksSemana)}',
                style: FocuxHubTypography.body(
                  color: ShellChrome.of(context).ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: TokensStrip.s3),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  DashboardHomeActionChip(
                    label: 'Abrir aluno',
                    accent: primary,
                    isDark: isDark,
                    onPressed: () => context.push('/alunos/${focus.alunoId}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
      ] else if (_habitos.isNotEmpty) ...[
        FxStripCard(
          emphasize: true,
          semanticsLabel: 'Próximo hábito: ${_habitos.first.titulo}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Próximo hábito', style: FocuxHubTypography.chip(mute)),
              const SizedBox(height: 6),
              Text(
                _habitos.first.titulo,
                style: FocuxHubTypography.kpi(
                  color: ShellChrome.of(context).ink,
                  fontSize: FocuxHubTypography.metricLg,
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  DashboardHomeActionChip(
                    label: 'Abrir',
                    accent: primary,
                    isDark: isDark,
                    onPressed: () async {
                      final habito = _habitos.first;
                      await context.push(
                        habitoDetailPath(habito.id),
                        extra: habito,
                      );
                      if (mounted) await _carregar();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
      ],
      if (_habitos.isEmpty)
        FxEmptyState(
          icon: 'circle-check',
          title: habitoEmptyTitle(hasCompliance: _compliance.isNotEmpty),
          subtitle: habitoEmptySubtitle(hasCompliance: _compliance.isNotEmpty),
        )
      else ...[
        const DashboardSectionHeader(title: 'Hábitos cadastrados'),
        const SizedBox(height: TokensStrip.s2),
        Text(
          'Toque para abrir a meta e desativar.',
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        for (final habito in _habitos)
          FxSatelliteListTile(
            title: habito.titulo,
            subtitle: Text(
              habitoSubtitle(
                descricao: habito.descricao,
                metaSemanal: habito.metaSemanal,
                alunoId: habito.alunoId,
              ),
            ),
            trailing: Text(
              habitoMetaValue(habito.metaSemanal),
              style: FocuxHubTypography.bodyMuted(
                color: mute,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () async {
              await context.push(
                habitoDetailPath(habito.id),
                extra: habito,
              );
              if (mounted) await _carregar();
            },
          ),
      ],
      const SizedBox(height: FxSettingsLayout.groupGap),
      if (_compliance.isEmpty)
        FxEmptyState(
          icon: 'trend',
          title: habitoComplianceEmptyTitle(_query),
          subtitle: habitoComplianceEmptySubtitle(_query),
          action:
              _query.trim().isEmpty
                  ? null
                  : FxEmptyAction(
                    label: 'Limpar busca',
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                      _carregar();
                    },
                  ),
        )
      else ...[
        const DashboardSectionHeader(title: 'Compliance da semana'),
        const SizedBox(height: TokensStrip.s3),
        for (final item in complianceRows)
          FxSatelliteListTile(
            title: habitoComplianceLabel(item.alunoNome),
            subtitle: Text(habitoComplianceSubtitle(item.checksSemana)),
            trailing: Text(
              habitoComplianceValue(item.compliancePct),
              style: FocuxHubTypography.bodyMuted(
                color:
                    habitoComplianceDanger(item.compliancePct)
                        ? EagleTokens.bad
                        : mute,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => context.push('/alunos/${item.alunoId}'),
          ),
        if (_hasMore)
          FxSatelliteListTile(
            title: _carregandoMais ? 'Carregando…' : 'Carregar mais',
            subtitle:
                _carregandoMais
                    ? null
                    : Text(
                      'Mais ${_totalCompliance - _compliance.length} nesta lista.',
                    ),
            onTap: _carregandoMais ? null : _carregarMais,
          ),
      ],
    ];
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s2,
            TokensStrip.s4,
            TokensStrip.s2,
          ),
          child: TextField(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            onSubmitted: (value) {
              _debounce?.cancel();
              final next = value.trim();
              if (next == _query && _compliance.isNotEmpty) return;
              _query = next;
              _carregar();
            },
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            decoration: InputDecoration(
              hintText: 'Buscar aluno',
              prefixIcon: const Icon(Icons.search_rounded),
              border: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                88,
              ),
              itemCount: _habitoRows.length,
              itemBuilder: (context, index) => _habitoRows[index],
            ),
          ),
        ),
      ],
    );
  }
}
