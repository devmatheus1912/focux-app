import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import 'lead_detail_screen.dart';
import 'add_lead_screen.dart';
import 'leads_kanban_screen.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class LeadsListScreen extends ConsumerStatefulWidget {
  const LeadsListScreen({super.key});

  @override
  ConsumerState<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends ConsumerState<LeadsListScreen> {
  List<Lead> _leads = [];
  bool _loading = true;
  String? _filtroStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = LeadRepository(ref.read(apiClientProvider));
      final leads = await repo.listar(status: _filtroStatus);
      if (mounted) {
        setState(() {
          _leads = leads;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
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
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
      );
      _load();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Funil de Leads',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.view_column,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            tooltip: 'Visão Kanban',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeadsKanbanScreen()),
              );
              _load();
            },
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            onPressed: _load,
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
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddLeadScreen()),
            );
            _load();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text(
            'Novo Lead',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      body:
          _loading
              ? Center(child: FxLoading(color: primary))
              : _leads.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_search,
                        color: primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhum lead cadastrado',
                      style: TextStyle(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final border = isDark ? EagleTokens.darkLine : EagleTokens.line;

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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: fxListCardDecoration(context, accent: color),
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
