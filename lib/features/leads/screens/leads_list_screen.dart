import 'package:flutter/material.dart';
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
  'LEAD': Colors.blue,
  'TESTE': Colors.orange,
  'ATIVO': Colors.green,
  'INADIMPLENTE': Colors.red,
  'CANCELADO': Colors.grey,
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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Funil de Leads'),
      actions: [
        IconButton(
          icon: const Icon(Icons.view_column),
          tooltip: 'Visão Kanban',
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsKanbanScreen()));
            _load();
          },
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLeadScreen()));
        _load();
      },
      icon: const Icon(Icons.person_add),
      label: const Text('Novo Lead'),
    ),
    body: Column(children: [
      _FiltroBar(
        selecionado: _filtroStatus,
        onChanged: (s) { setState(() => _filtroStatus = s); _load(); },
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _leads.isEmpty
                ? Center(child: Text(
                    _filtroStatus != null
                        ? 'Nenhum lead com status "${_statusLabels[_filtroStatus]}".'
                        : 'Nenhum lead cadastrado.',
                  ))
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
          selectedColor: (_statusColors[e.key] ?? Colors.grey).withValues(alpha: 0.2),
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
    final color = _statusColors[lead.status] ?? Colors.grey;
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
