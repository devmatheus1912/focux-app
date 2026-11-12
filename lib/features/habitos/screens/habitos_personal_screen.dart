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
import '../../../core/widgets/fx_barra_progresso.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
import '../../../core/theme/fx_icons.dart';

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
  var _mostrarBateram = false;

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
      label: 'Hábitos',
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
              title: 'Hábitos',
              subtitle: FxHubFreshness.joinCount(
                _loading
                    ? habitoCountLabel(0)
                    : habitoSubtituloLista(
                      habitos: _habitos.length,
                      abaixoDaMeta:
                          habitoOrdenarSemana(_compliance).pendentes.length,
                      temSemana: _compliance.any((c) => c.metaSemana > 0),
                    ),
                _loading ? null : freshnessLabel,
              ),
              onBack: () {
                FxKeyboardDismissScope.dismiss();
                safePopOrGo(context, '/perfil/ferramentas');
              },
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar os hábitos',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Hábitos',
                        subtitle:
                            'O que o aluno faz fora do treino e marca no app.',
                        tips: const [
                          FxHelpTip('Esta semana', habitoComoCalculamos),
                          FxHelpTip(
                            'Seus hábitos',
                            'Toque no hábito para ver cada aluno. Desativar fica no ⋯.',
                          ),
                          FxHelpTip(
                            'Novo',
                            'Escolha um modelo, quantas vezes por semana e para quem.',
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

  Future<void> _abrirHabito(Habito habito) async {
    await context.push(habitoDetailPath(habito.id), extra: habito);
    if (mounted) await _carregar();
  }

  List<Widget> get _linhas {
    final chrome = ShellChrome.of(context);
    final semana = habitoOrdenarSemana(_compliance);
    final temSemana = semana.pendentes.isNotEmpty || semana.bateram.isNotEmpty;

    Widget linhaAluno(ComplianceItem c) => _LinhaSemana(
      nome: habitoComplianceLabel(c.alunoNome),
      feitos: c.checksSemana,
      meta: c.metaSemana,
      onTap: () => context.push('/alunos/${c.alunoId}'),
    );

    if (_habitos.isEmpty && _query.trim().isEmpty) {
      return [
        const SizedBox(height: TokensStrip.s6),
        FxEmptyState(
          icon: FxIcons.concluido,
          title: 'Nenhum hábito ainda',
          subtitle: habitoVazioTexto,
          action: FxEmptyAction(label: 'Novo hábito', onTap: _novoHabito),
        ),
      ];
    }

    return [
      if (temSemana) ...[
        const DashboardSectionHeader(title: 'Esta semana'),
        const SizedBox(height: TokensStrip.s2),
        for (final c in semana.pendentes) linhaAluno(c),
        if (semana.bateram.isNotEmpty)
          FxSatelliteListTile(
            title: 'Bateram a meta (${semana.bateram.length})',
            titleCase: false,
            trailing: Icon(
              _mostrarBateram ? FxIcons.chevronCima : FxIcons.chevronBaixo,
              color: chrome.mute,
            ),
            onTap: () => setState(() => _mostrarBateram = !_mostrarBateram),
          ),
        if (_mostrarBateram)
          for (final c in semana.bateram) linhaAluno(c),
        if (_hasMore)
          FxSatelliteListTile(
            title: _carregandoMais ? 'Carregando…' : 'Carregar mais',
            subtitle:
                _carregandoMais
                    ? null
                    : Text(
                      'Mais ${_totalCompliance - _compliance.length} alunos.',
                    ),
            onTap: _carregandoMais ? null : _carregarMais,
          ),
        const SizedBox(height: FxSettingsLayout.groupGap),
      ] else if (_query.trim().isNotEmpty) ...[
        FxEmptyState(
          icon: FxIcons.buscar,
          title: 'Nenhum aluno encontrado',
          subtitle: 'Nada com esse nome nesta semana.',
          action: FxEmptyAction(
            label: 'Limpar busca',
            secondary: true,
            onTap: () {
              _searchCtrl.clear();
              setState(() => _query = '');
              _carregar();
            },
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
      ],
      const DashboardSectionHeader(title: 'Seus hábitos'),
      const SizedBox(height: TokensStrip.s2),
      for (final habito in _habitos)
        FxSatelliteListTile(
          title: habito.titulo,
          subtitle: Text(
            habitoRegra(
              metaSemanal: habito.metaSemanal,
              alunoId: habito.alunoId,
            ),
          ),
          onTap: () => _abrirHabito(habito),
        ),
    ];
  }

  Widget _buildBody() {
    final busca = habitoMostraBusca(total: _totalCompliance, query: _query);
    final linhas = _linhas;
    return Column(
      children: [
        if (busca)
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
                prefixIcon: const Icon(FxIcons.buscar),
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _carregar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s6,
              ),
              children: linhas,
            ),
          ),
        ),
      ],
    );
  }
}

/// Um aluno em "Esta semana": nome, "3 de 7 esta semana" e a barra.
class _LinhaSemana extends StatelessWidget {
  const _LinhaSemana({
    required this.nome,
    required this.feitos,
    required this.meta,
    required this.onTap,
  });

  final String nome;
  final int feitos;
  final int meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final bateu = meta > 0 && feitos >= meta;
    return Semantics(
      button: true,
      label: '$nome, ${habitoSemanaLinha(feitos, meta)}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: TokensStrip.s2,
            horizontal: TokensStrip.s1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.body(color: chrome.ink),
                    ),
                  ),
                  Text(
                    habitoSemanaLinha(feitos, meta),
                    style: FocuxHubTypography.rotulo(color: chrome.mute),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s1),
              FxBarraProgresso(
                fracao: habitoFracao(feitos, meta),
                cor: bateu ? EagleTokens.good : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
