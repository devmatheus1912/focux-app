import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../widgets/leads_list_help_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/lead_repository.dart';
import '../providers/leads_provider.dart';
import '../utils/lead_display.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _leads = <Lead>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasNext = false;
  var _page = 0;
  var _total = 0;
  String? _erro;
  DateTime? _fetchedAt;
  String? _status;
  var _query = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _erro = null;
        _page = 0;
        _leads.clear();
        _hasNext = false;
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }
    try {
      if (reset) {
        invalidateLeadsCaches(ref);
        final home = await ref.read(leadsHomeProvider.future);
        final planoFromHome = home.planoFeatures;
        if (planoFromHome != null) {
          ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
        }
      }
      final pagina = await LeadRepository(ref.read(apiClientProvider))
          .listarPagina(
            status: _status,
            q: _query,
            page: reset ? 0 : _page,
          );
      if (!mounted) return;
      setState(() {
        _leads.addAll(pagina.content);
        _hasNext = pagina.hasNext;
        _page = (pagina.page ?? 0) + 1;
        _total = pagina.totalElements ?? _leads.length;
        _loading = false;
        _loadingMore = false;
        if (reset) _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _novoLead() async {
    AnalyticsService.instance.track(
      ProductEvents.leadCreatedOrOpened,
      props: {'feature': 'leads', 'action': 'novo'},
    );
    await context.push('/leads/novo');
    if (mounted) _load(reset: true);
  }

  Future<void> _abrirKanban() async {
    await context.push('/leads/kanban');
    if (mounted) _load(reset: true);
  }

  Future<void> _abrirLead(Lead lead) async {
    AnalyticsService.instance.track(
      ProductEvents.leadCreatedOrOpened,
      props: {'feature': 'leads', 'action': 'abrir', 'lead_id': lead.id},
    );
    await context.push('/leads/${lead.id}', extra: lead);
    if (mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final plano = ref.watch(planoFeaturesProvider).valueOrNull;
    final limiteLeads = plano?.limiteLeads;
    final showLeadsLimitBanner = leadShowsLimitBanner(
      _total,
      limiteLeads: limiteLeads,
    );
    final count = _total;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Funil de Leads',
      child: FeatureGate(
        featureName: 'Leads',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'leads',
        child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          safePopOrGo(context, '/dashboard/personal');
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Funil de Leads',
          subtitle: leadListSubtitle(
            count: count,
            freshness: FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, '/dashboard/personal');
          },
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o funil',
              onTap: () => showLeadsListHelpSheet(context),
            ),
            ShellHeaderIconButton(
              icon: 'route',
              tooltip: 'Visão Kanban',
              onTap: _abrirKanban,
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLeadsLimitBanner)
              Material(
                color: primary.withValues(alpha: 0.1),
                child: InkWell(
                  onTap: () => context.push('/assinatura', extra: 'Pro'),
                  child: Padding(
                    padding: const EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            leadLimitLabel(_total, limiteLeads!),
                            style: FocuxHubTypography.body(
                              color: chrome.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          'Pro →',
                          style: FocuxHubTypography.body(
                            color: primary,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  onSubmitted: (_) => _searchFocus.unfocus(),
                  onTapOutside: (_) => _searchFocus.unfocus(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar lead',
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
                    suffixIcon:
                        _query.trim().isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _searchDebounce?.cancel();
                                _searchCtrl.clear();
                                setState(() => _query = '');
                                _load(reset: true);
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: mute,
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
                  for (final status in leadListChipStatuses)
                    FxToggleChip(
                      label: leadStatusLabel(status),
                      selected: _status == status,
                      isDark: chrome.isDark,
                      onTap: () {
                        setState(() {
                          _status = _status == status ? null : status;
                        });
                        _load(reset: true);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(isDark: chrome.isDark, primary: primary),
            ),
            if (!_loading && _erro == null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: 'Novo lead',
                    onPressed: _novoLead,
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

  Widget _buildBody({
    required bool isDark,
    required Color primary,
  }) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
        child: SkeletonList(count: 6),
      );
    }
    if (_erro != null) {
      return FxErrorState(
        chromeOnDark: isDark,
        primary: primary,
        message: _erro!,
        onRetry: () => _load(reset: true),
      );
    }
    if (_leads.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return FxContentWidthLimiter(
        child: RefreshIndicator(
          color: primary,
          onRefresh: () => _load(reset: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (filtered)
                FxEmptyState(
                  icon: 'search',
                  title: 'Nenhum lead encontrado',
                  subtitle: 'Ajuste a busca para ver outros prospects.',
                  action: FxEmptyAction(
                    label: 'Limpar busca',
                    onTap: () {
                      _searchDebounce?.cancel();
                      _searchCtrl.clear();
                      setState(() => _query = '');
                      _load(reset: true);
                    },
                  ),
                )
              else
                FxEmptyState(
                  icon: 'users',
                  title:
                      _status == null
                          ? 'Nenhum lead cadastrado'
                          : 'Nenhum lead neste status',
                  subtitle:
                      _status == null
                          ? 'Cadastre o primeiro lead para começar a acompanhar o funil.'
                          : 'Troque o filtro ou cadastre um prospect neste estágio.',
                ),
            ],
          ),
        ),
      );
    }

    final visible = _leads;
    final showMore = _hasNext;
    return FxContentWidthLimiter(
      child: RefreshIndicator(
      color: primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: visible.length + (showMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (showMore && i == visible.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : () => _load(reset: false),
            );
          }
          final lead = visible[i];
          return FxSatelliteListTile(
            title: lead.nome,
            subtitle: Text(
              leadCardSubtitle(
                objetivo: lead.objetivo,
                origem: lead.origem,
              ),
            ),
            trailing: Text(
              leadStatusLabel(lead.status),
              style: FocuxHubTypography.bodyMuted(
                color:
                    leadStatusDanger(lead.status)
                        ? EagleTokens.bad
                        : fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: leadStatusDanger(lead.status) ? EagleTokens.bad : null,
            onTap: () => _abrirLead(lead),
          );
        },
      ),
      ),
    );
  }
}
