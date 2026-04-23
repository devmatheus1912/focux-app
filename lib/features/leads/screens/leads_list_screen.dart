import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import 'lead_detail_screen.dart';
import 'add_lead_screen.dart';
import 'leads_kanban_screen.dart';

const _statusLabels = {
  'LEAD': 'Lead',
  'TESTE': 'Teste',
  'ATIVO': 'Ativo',
  'INADIMPLENTE': 'Inadimplente',
  'CANCELADO': 'Cancelado',
};

const _statusColors = {
  'LEAD': EagleTokens.brand,
  'TESTE': EagleTokens.warn,
  'ATIVO': EagleTokens.good,
  'INADIMPLENTE': EagleTokens.bad,
  'CANCELADO': EagleTokens.inkMute,
};

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
      if (mounted) setState(() { _leads = leads; _loading = false; });
    } catch (e) { debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        title: Text('Funil de Leads', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        actions: [
          IconButton(
            icon: Icon(Icons.view_column, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
            tooltip: 'Visão Kanban',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsKanbanScreen()));
              _load();
            },
          ),
          IconButton(icon: Icon(Icons.refresh, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute), onPressed: _load),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLeadScreen()));
            _load();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text('Novo Lead', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
      body: Column(children: [
        _FiltroBar(
          selecionado: _filtroStatus,
          onChanged: (s) { setState(() => _filtroStatus = s); _load(); },
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: EagleTokens.brand))
              : _leads.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 56, height: 56, decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.person_search, color: EagleTokens.brand, size: 28)),
                      const SizedBox(height: 12),
                      Text(_filtroStatus != null ? 'Nenhum lead "${_statusLabels[_filtroStatus]}"' : 'Nenhum lead cadastrado', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 14)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                      itemCount: _leads.length,
                      itemBuilder: (_, i) => _LeadCard(
                        lead: _leads[i],
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => LeadDetailScreen(lead: _leads[i]),
                          ));
                          _load();
                        },
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _FiltroBar extends StatelessWidget {
  final String? selecionado;
  final ValueChanged<String?> onChanged;
  const _FiltroBar({required this.selecionado, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(children: [
      FilterChip(
        label: const Text('Todos'),
        selected: selecionado == null,
        onSelected: (_) => onChanged(null),
      ),
      const SizedBox(width: 8),
      ..._statusLabels.entries.map((e) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilterChip(
          label: Text(e.value),
          selected: selecionado == e.key,
          selectedColor: (_statusColors[e.key] ?? EagleTokens.inkMute).withValues(alpha: 0.2),
          onSelected: (_) => onChanged(selecionado == e.key ? null : e.key),
        ),
      )),
    ]),
  );
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;
  const _LeadCard({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[lead.status] ?? EagleTokens.inkMute;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(lead.nome[0].toUpperCase(),
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(lead.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (lead.telefone != null) lead.telefone!,
          if (lead.origem != null) lead.origem!,
          'desde ${lead.criadoEm}',
        ].join(' · ')),
        trailing: Chip(
          label: Text(_statusLabels[lead.status] ?? lead.status,
              style: const TextStyle(fontSize: 11)),
          backgroundColor: color.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: color),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
