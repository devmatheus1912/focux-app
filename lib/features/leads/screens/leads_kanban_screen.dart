import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';

const _kCols = ['LEAD', 'TESTE', 'ATIVO', 'CANCELADO'];
const _kLabels = {
  'LEAD': 'Lead',
  'TESTE': 'Teste',
  'ATIVO': 'Ativo',
  'CANCELADO': 'Cancelado',
};
const _kColors = {
  'LEAD': EagleTokens.brand,
  'TESTE': EagleTokens.warn,
  'ATIVO': EagleTokens.good,
  'CANCELADO': EagleTokens.inkMute,
};

class LeadsKanbanScreen extends ConsumerStatefulWidget {
  const LeadsKanbanScreen({super.key});
  @override
  ConsumerState<LeadsKanbanScreen> createState() => _LeadsKanbanScreenState();
}

class _LeadsKanbanScreenState extends ConsumerState<LeadsKanbanScreen> {
  Map<String, List<Lead>> _cols = {for (final c in _kCols) c: []};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final leads = await LeadRepository(ref.read(apiClientProvider)).listar();
      final Map<String, List<Lead>> cols = {for (final c in _kCols) c: []};
      for (final l in leads) {
        final col = _kCols.contains(l.status) ? l.status : 'LEAD';
        cols[col]!.add(l);
      }
      if (mounted) setState(() { _cols = cols; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moverPara(Lead lead, String novoStatus) async {
    if (lead.status == novoStatus) return;
    try {
      await LeadRepository(ref.read(apiClientProvider))
          .atualizar(lead.id, {'status': novoStatus});
      setState(() {
        _cols[lead.status]?.remove(lead);
        _cols[novoStatus]?.add(lead);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao mover: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      title: const Text('Funil Kanban'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _kCols
                .map((col) => Expanded(child: _KanbanColumn(
                      status: col,
                      leads: _cols[col] ?? [],
                      onAccept: (lead) => _moverPara(lead, col),
                    )))
                .toList(),
          ),
  );
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final List<Lead> leads;
  final void Function(Lead) onAccept;

  const _KanbanColumn({
    required this.status,
    required this.leads,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final color = _kColors[status] ?? EagleTokens.inkMute;
    return DragTarget<Lead>(
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidates, rejected) => Container(
        color: candidates.isNotEmpty
            ? color.withValues(alpha: 0.08)
            : Colors.transparent,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Chip(
              label: Text(
                '${_kLabels[status]} (${leads.length})',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              backgroundColor: color.withValues(alpha: 0.12),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: leads.map((l) => _DraggableLeadCard(lead: l)).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _DraggableLeadCard extends StatelessWidget {
  final Lead lead;
  const _DraggableLeadCard({required this.lead});

  @override
  Widget build(BuildContext context) {
    final color = _kColors[lead.status] ?? EagleTokens.inkMute;
    final initial = lead.nome.isNotEmpty ? lead.nome[0].toUpperCase() : '?';

    return LongPressDraggable<Lead>(
      data: lead,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 140,
          child: _CardContent(lead: lead, color: color, initial: initial, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _CardContent(lead: lead, color: color, initial: initial),
      ),
      child: _CardContent(lead: lead, color: color, initial: initial),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Lead lead;
  final Color color;
  final String initial;
  final bool dragging;

  const _CardContent({
    required this.lead,
    required this.color,
    required this.initial,
    this.dragging = false,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 6),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lead.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (lead.telefone != null)
              Text(lead.telefone!, style: const TextStyle(color: EagleTokens.inkMute, fontSize: 11),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    ),
  );
}
