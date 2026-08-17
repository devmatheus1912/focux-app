import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lead_repository.dart';
import '../providers/leads_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen> {
  List<Lead> _leads = [];
  bool _loading = true;
  String? _erro;
  String? _filtroStatus;

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
      var leads = home.leads;
      if (_filtroStatus != null && _filtroStatus!.isNotEmpty) {
        final status = _filtroStatus!.toUpperCase();
        leads = leads.where((l) => l.status == status).toList();
      }
      if (mounted) {
        setState(() {
          _leads = leads;
          _loading = false;
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
    await context.push('/leads/novo');
    _load(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    final leadLeads = _leads.where((lead) => lead.status == 'LEAD').toList();
    final testeLeads = _leads.where((lead) => lead.status == 'TESTE').toList();
    final ativoLeads = _leads.where((lead) => lead.status == 'ATIVO').toList();
    Future<void> openLead(Lead lead) async {
      await context.push('/leads/${lead.id}', extra: lead);
      _load(force: true);
    }

    final plano = ref.watch(planoFeaturesProvider).valueOrNull;
    final showLeadsLimitBanner =
        plano?.plano == SubscriptionPlan.FREE && _leads.length >= 4;

    return fxScreenA11yScope(
      label: 'Funil de Leads',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Funil de Leads',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.view_column,
                color:
                    isDark
                        ? EagleTokens.darkInkMute
                        : TokensStrip.textSecondary,
              ),
              tooltip: 'Visão Kanban',
              onPressed: () async {
                await context.push('/leads/kanban');
                _load(force: true);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color:
                    isDark
                        ? EagleTokens.darkInkMute
                        : TokensStrip.textSecondary,
              ),
              onPressed: () => _load(force: true),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, primaryDeep]),
            borderRadius: BorderRadius.circular(TokensStrip.rXl),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _novoLead,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.person_add, color: Colors.white),
            label: const Text(
              'Novo Lead',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLeadsLimitBanner)
              Material(
                color: primary.withValues(alpha: 0.1),
                child: InkWell(
                  onTap: () => context.push('/assinatura', extra: 'Premium'),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _leads.length >= 5
                                ? 'Limite de 5 leads atingido no Free.'
                                : '${_leads.length}/5 leads no plano Free.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          'Premium →',
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
            Expanded(
              child:
                  _loading
                      ? const SkeletonList(count: 6)
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: () => _load(force: true),
                      )
                      : _leads.isEmpty
                      ? FxEmptyState(
                        icon: 'users',
                        title: 'Nenhum lead cadastrado',
                        subtitle:
                            'Cadastre o primeiro lead para começar a acompanhar o funil.',
                        action: FxEmptyAction(
                          label: 'Novo lead',
                          onTap: _novoLead,
                        ),
                      )
                      : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          16,
                          16,
                          96,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _KanbanColumn(
                              title: 'LEAD',
                              color: primary,
                              leads: leadLeads,
                              isDark: isDark,
                              onTap: openLead,
                            ),
                            const SizedBox(width: 12),
                            _KanbanColumn(
                              title: 'TESTE',
                              color: EagleTokens.warn,
                              leads: testeLeads,
                              isDark: isDark,
                              onTap: openLead,
                            ),
                            const SizedBox(width: 12),
                            _KanbanColumn(
                              title: 'ATIVO',
                              color: EagleTokens.good,
                              leads: ativoLeads,
                              isDark: isDark,
                              onTap: openLead,
                            ),
                          ],
                        ),
                      ),
            ),
          ],
        ),
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

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.leads,
    required this.isDark,
    required this.onTap,
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
          ...leads.map(
            (lead) => _KanbanCard(
              lead: lead,
              color: color,
              isDark: isDark,
              onTap: () => onTap(lead),
            ),
          ),
          Container(
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ink,
          ),
        ),
        subtitle: Text(
          lead.objetivo ?? lead.origem ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: mute),
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (lead.telefone != null && lead.telefone!.isNotEmpty)
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
