import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/api/pagina.dart';
import '../data/automacao_repository.dart';
import '../utils/automacao_display.dart';

part 'automacoes_screen_logs.part.dart';
part 'automacoes_screen_list.part.dart';

final _repo = Provider(
  (ref) => AutomacaoRepository(ref.read(apiClientProvider)),
);

class AutomacoesScreen extends ConsumerStatefulWidget {
  const AutomacoesScreen({super.key});

  @override
  ConsumerState<AutomacoesScreen> createState() => _AutomacoesScreenState();
}

class _AutomacoesScreenState extends ConsumerState<AutomacoesScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<AutomacaoFluxo> _fluxos = const [];
  List<AutomacaoTemplate> _templates = const [];
  PlanoFeatures? _planoFromHome;
  var _loading = true;
  var _carregandoMais = false;
  var _hasMore = false;
  var _page = 0;
  var _totalFluxos = 0;
  String? _error;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = AutomacaoChip.todos;

  @override
  void initState() {
    super.initState();
    prefetchAlunosHome(ref);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (!mounted || next == _query) return;
      _query = next;
      _load();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    if (_query.isEmpty) return;
    _query = '';
    _load();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/perfil/ferramentas');
  }

  List<AutomacaoTemplate> get _visibleTemplates {
    if (_chip == AutomacaoChip.ativos) return const [];
    return _templates;
  }

  List<AutomacaoFluxo> get _visibleFluxos {
    if (_chip == AutomacaoChip.templates) return const [];
    return _fluxos;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(_repo).getHome(q: _query);
      if (!mounted) return;
      setState(() {
        _fluxos = home.fluxos;
        _templates = home.templates;
        _planoFromHome = home.planoFeatures;
        _page = home.page;
        _hasMore = home.hasNext;
        _totalFluxos = home.totalFluxos;
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
          .read(_repo)
          .getHome(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _fluxos.map((f) => f.id).toSet();
      setState(() {
        _fluxos = [
          ..._fluxos,
          ...home.fluxos.where((f) => seen.add(f.id)),
        ];
        _page = home.page;
        _hasMore = home.hasNext;
        _totalFluxos = home.totalFluxos;
        _carregandoMais = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
    }
  }

  Future<void> _ativar(AutomacaoTemplate t) async {
    final ok = await showFxConfirmSheet(
      context,
      title: automacaoAtivarTitle(t.nome),
      message: automacaoAtivarMessage(),
      icon: Icons.bolt_outlined,
      confirmLabel: 'Ativar',
    );
    if (!ok || !mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.automacaoTemplateActivated,
      props: {'feature': 'automacoes', 'template_id': t.id},
    );
    try {
      await ref.read(_repo).ativarTemplate(t.id);
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Template “${t.nome}” ativado');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _openLogs(AutomacaoFluxo fluxo) async {
    try {
      final pagina = await ref.read(_repo).logs(fluxo.id);
      if (!mounted) return;
      await _showAutomacaoLogsSheet(
        context: context,
        fluxo: fluxo,
        initial: pagina,
        onLoadMore: (page) => ref.read(_repo).logs(fluxo.id, page: page),
        onIniciar: () => _iniciarParaAluno(fluxo),
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final templates = _visibleTemplates;
    final fluxos = _visibleFluxos;
    final planoFromHome = _planoFromHome;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    return fxScreenA11yScope(
      label: 'Automações',
      child: FeatureGate(
        featureName: 'Automações',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'automacoes',
        child: PopScope(
          canPop: !keyboardOpen && !_searchFocus.hasFocus,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (keyboardOpen || _searchFocus.hasFocus) {
              FxKeyboardDismissScope.dismiss();
              return;
            }
            _leave();
          },
          child: FxShellScaffold(
            useMesh: true,
            dismissKeyboard: true,
            appBar: FxShellAppBar(
              title: 'Automações',
              subtitle: FxHubFreshness.joinCount(
                automacaoCountLabel(
                  templates: _chip == AutomacaoChip.ativos
                      ? 0
                      : templates.length,
                  fluxos: _chip == AutomacaoChip.templates ? 0 : _totalFluxos,
                ),
                FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar automações',
                  onTap: () => showFxHelpSheet(
                    context,
                    title: 'Automações',
                    subtitle: 'Templates viram fluxos quando o gatilho dispara.',
                    tips: const [
                      FxHelpTip(
                        'Ativar',
                        'Toque no template e confirme. O fluxo aparece em Ativos.',
                      ),
                      FxHelpTip(
                        'Histórico',
                        'Toque em um fluxo ativo para ver as execuções.',
                      ),
                      FxHelpTip(
                        'Iniciar',
                        'No histórico, escolha um aluno para disparar agora.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    TokensStrip.s2,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: DecoratedBox(
                    decoration: fxStripCardDecoration(
                      context,
                      accent: primary,
                      radius: TokensStrip.rCard,
                      glowStrength: 0.03,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onQueryChanged,
                      onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Buscar template ou fluxo',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: primary,
                          size: 20,
                        ),
                        suffixIcon: _query.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: _clearQuery,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: chrome.mute,
                                  size: 18,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      for (final chip in AutomacaoChip.values)
                        FxToggleChip(
                          label: automacaoChipLabel(chip),
                          selected: _chip == chip,
                          isDark: chrome.isDark,
                          onTap: () {
                            if (_chip == chip) return;
                            setState(() => _chip = chip);
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                          child: SkeletonList(count: 5),
                        )
                      : _error != null
                      ? FxErrorState(
                          chromeOnDark: chrome.isDark,
                          primary: primary,
                          message: _error!,
                          onRetry: _load,
                        )
                      : FxContentWidthLimiter(
                          child: _buildList(templates, fluxos),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
