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
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
  List<Lead> _leads = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (force) invalidateLeadsCaches(ref);
      final home = await ref.read(leadsHomeProvider.future);
      final planoFromHome = home.planoFeatures;
      if (planoFromHome != null) {
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      }
      if (mounted) {
        setState(() {
          _leads = home.leads;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _novoLead() async {
    AnalyticsService.instance.track(
      ProductEvents.leadCreatedOrOpened,
      props: {'feature': 'leads', 'action': 'novo'},
    );
    await context.push('/leads/novo');
    if (mounted) _load(force: true);
  }

  Future<void> _abrirKanban() async {
    await context.push('/leads/kanban');
    if (mounted) _load(force: true);
  }

  Future<void> _abrirLead(Lead lead) async {
    AnalyticsService.instance.track(
      ProductEvents.leadCreatedOrOpened,
      props: {'feature': 'leads', 'action': 'abrir', 'lead_id': lead.id},
    );
    await context.push('/leads/${lead.id}', extra: lead);
    if (mounted) _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final plano = ref.watch(planoFeaturesProvider).valueOrNull;
    final showLeadsLimitBanner =
        plano?.plano == SubscriptionPlan.FREE && _leads.length >= 4;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Funil de Leads',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Funil de Leads',
          subtitle: leadListSubtitle(freshnessLabel),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            ShellHeaderIconButton(
              icon: 'route',
              tooltip: 'Visão Kanban',
              onTap: _abrirKanban,
            ),
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Novo lead',
              onTap: _novoLead,
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
                            leadFreeLimitLabel(_leads.length),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          'Pro →',
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: _buildBody(isDark: isDark, primary: primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required bool isDark, required Color primary}) {
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
        onRetry: () => _load(force: true),
      );
    }
    if (_leads.isEmpty) {
      return FxContentWidthLimiter(
        child: RefreshIndicator(
          onRefresh: () => _load(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              FxEmptyState(
                icon: 'users',
                title: 'Nenhum lead cadastrado',
                subtitle:
                    'Cadastre o primeiro lead para começar a acompanhar o funil.',
                action: FxEmptyAction(label: 'Novo lead', onTap: _novoLead),
              ),
            ],
          ),
        ),
      );
    }

    final leadLeads = _leads.where((lead) => lead.status == 'LEAD').toList();
    final testeLeads = _leads.where((lead) => lead.status == 'TESTE').toList();
    final ativoLeads = _leads.where((lead) => lead.status == 'ATIVO').toList();

    return RefreshIndicator(
      onRefresh: () => _load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KanbanColumn(
                  title: leadStatusLabel('LEAD'),
                  color: primary,
                  leads: leadLeads,
                  isDark: isDark,
                  onTap: _abrirLead,
                  onAdd: _novoLead,
                ),
                const SizedBox(width: 12),
                _KanbanColumn(
                  title: leadStatusLabel('TESTE'),
                  color: EagleTokens.warn,
                  leads: testeLeads,
                  isDark: isDark,
                  onTap: _abrirLead,
                  onAdd: _novoLead,
                ),
                const SizedBox(width: 12),
                _KanbanColumn(
                  title: leadStatusLabel('ATIVO'),
                  color: EagleTokens.good,
                  leads: ativoLeads,
                  isDark: isDark,
                  onTap: _abrirLead,
                  onAdd: _novoLead,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Lead> leads;
  final bool isDark;
  final ValueChanged<Lead> onTap;
  final VoidCallback onAdd;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.leads,
    required this.isDark,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final border = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${leads.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final lead in leads)
            _KanbanCard(
              lead: lead,
              color: color,
              isDark: isDark,
              onTap: () => onTap(lead),
            ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '+ Adicionar',
                    style: TextStyle(
                      fontSize: 13,
                      color: mute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  final Lead lead;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _KanbanCard({
    required this.lead,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final telefone = lead.telefone?.trim();

    return fxListTileCardShell(
      context: context,
      margin: const EdgeInsets.only(bottom: 8),
      accent: color,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
        title: Text(
          lead.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.bodyMuted(
            color: ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          leadCardSubtitle(objetivo: lead.objetivo, origem: lead.origem),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.bodyMuted(color: mute),
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (telefone != null && telefone.isNotEmpty)
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: EagleTokens.good,
              ),
            Icon(Icons.chevron_right_rounded, size: 18, color: mute),
          ],
        ),
      ),
    );
  }
}
