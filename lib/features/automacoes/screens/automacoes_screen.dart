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
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/automacao_repository.dart';
import '../utils/automacao_display.dart';

part 'automacoes_screen_logs.part.dart';

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
  String? _error;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = AutomacaoChip.todos;

  @override
  void initState() {
    super.initState();
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
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/perfil/ferramentas');
  }

  List<AutomacaoTemplate> get _visibleTemplates {
    if (_chip == AutomacaoChip.ativos) return const [];
    return _templates
        .where(
          (t) => automacaoMatchesQuery(
            nome: t.nome,
            descricao: t.descricao,
            triggerTipo: t.triggerTipo,
            query: _query,
          ),
        )
        .toList();
  }

  List<AutomacaoFluxo> get _visibleFluxos {
    if (_chip == AutomacaoChip.templates) return const [];
    return _fluxos
        .where(
          (f) => automacaoMatchesQuery(
            nome: f.nome,
            descricao: f.descricao,
            triggerTipo: f.triggerTipo,
            query: _query,
          ),
        )
        .toList();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(_repo).getHome();
      if (!mounted) return;
      setState(() {
        _fluxos = home.fluxos;
        _templates = home.templates;
        _planoFromHome = home.planoFeatures;
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
      final logs = await ref.read(_repo).logs(fluxo.id);
      if (!mounted) return;
      await _showAutomacaoLogsSheet(
        context: context,
        fluxo: fluxo,
        logs: logs,
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
                  templates: templates.length,
                  fluxos: fluxos.length,
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

  Widget _buildList(
    List<AutomacaoTemplate> templates,
    List<AutomacaoFluxo> fluxos,
  ) {
    final primary = Theme.of(context).colorScheme.primary;
    if (templates.isEmpty && fluxos.isEmpty) {
      final filtered =
          _query.trim().isNotEmpty || _chip != AutomacaoChip.todos;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? 'search' : 'zap',
              title: filtered
                  ? 'Nenhuma automação encontrada'
                  : 'Nenhuma automação ainda',
              subtitle: filtered
                  ? 'Ajuste a busca ou o filtro.'
                  : 'Templates aparecem aqui para você ativar o primeiro fluxo.',
              action: filtered
                  ? FxEmptyAction(label: 'Limpar filtros', onTap: _clearQuery)
                  : null,
            ),
          ],
        ),
      );
    }

    final rows = <Object>[
      if (templates.isNotEmpty) ...['Templates', ...templates],
      if (fluxos.isNotEmpty) ...['Fluxos ativos', ...fluxos],
    ];

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final row = rows[i];
          if (row is String) {
            return Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : TokensStrip.s3,
                bottom: TokensStrip.s2,
              ),
              child: Text(
                row,
                style: FocuxHubTypography.cardTitle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }
          if (row is AutomacaoTemplate) {
            return FxSatelliteListTile(
              title: row.nome,
              titleCase: false,
              subtitle: Text(
                row.descricao.trim().isEmpty
                    ? automacaoTriggerLabel(row.triggerTipo)
                    : row.descricao,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: Icon(Icons.bolt_outlined, color: primary),
              trailing: Text(
                'Ativar',
                style: FocuxHubTypography.bodyMuted(
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _ativar(row),
            );
          }
          final fluxo = row as AutomacaoFluxo;
          return FxSatelliteListTile(
            title: fluxo.nome,
            titleCase: false,
            subtitle: Text(automacaoTriggerLabel(fluxo.triggerTipo)),
            leading: Icon(
              fluxo.ativo
                  ? Icons.play_circle_rounded
                  : Icons.pause_circle_rounded,
              color: primary,
            ),
            trailing: Text(
              automacaoFluxoStatusLabel(ativo: fluxo.ativo),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _openLogs(fluxo),
          );
        },
      ),
    );
  }
}
