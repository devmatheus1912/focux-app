import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';

const _statusOpcoes = ['LEAD', 'TESTE', 'ATIVO', 'INADIMPLENTE', 'CANCELADO'];
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

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  late Lead _lead;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
  }

  Future<void> _ligar() async {
    if (_lead.telefone == null) return;
    final uri = Uri.parse('tel:${_lead.telefone}');
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    if (_lead.telefone == null) return;
    final tel = _lead.telefone!.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/55$tel');
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _mudarStatus(String novoStatus) async {
    try {
      final updated = await LeadRepository(ref.read(apiClientProvider))
          .atualizar(_lead.id, {'status': novoStatus});
      setState(() => _lead = updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status atualizado para ${_statusLabels[novoStatus]}')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _converter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Converter em Aluno?'),
        content: Text('${_lead.nome} será criado como aluno na sua lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Converter')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await LeadRepository(ref.read(apiClientProvider)).converter(_lead.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead convertido em aluno com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _arquivar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arquivar lead?'),
        content: const Text('O lead será marcado como Cancelado.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Arquivar')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await LeadRepository(ref.read(apiClientProvider)).arquivar(_lead.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[_lead.status] ?? Colors.grey;
    return Scaffold(
      appBar: AppBar(
        title: Text(_lead.nome),
        actions: [
          PopupMenuButton<String>(
            onSelected: _mudarStatus,
            itemBuilder: (_) => _statusOpcoes
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(children: [
                        Icon(Icons.circle, size: 10,
                            color: _statusColors[s] ?? Colors.grey),
                        const SizedBox(width: 8),
                        Text(_statusLabels[s] ?? s),
                      ]),
                    ))
                .toList(),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Status chip
          Center(
            child: Chip(
              label: Text(_statusLabels[_lead.status] ?? _lead.status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              backgroundColor: color.withValues(alpha: 0.12),
              avatar: Icon(Icons.circle, size: 10, color: color),
            ),
          ),
          const SizedBox(height: 16),

          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _InfoRow(label: 'Nome', value: _lead.nome),
                if (_lead.telefone != null)
                  _InfoRow(label: 'Telefone', value: _lead.telefone!),
                if (_lead.origem != null)
                  _InfoRow(label: 'Origem', value: _lead.origem!),
                if (_lead.objetivo != null)
                  _InfoRow(label: 'Objetivo', value: _lead.objetivo!),
                _InfoRow(label: 'Cadastrado em', value: _lead.criadoEm),
                if (_lead.convertidoEm != null)
                  _InfoRow(label: 'Convertido em', value: _lead.convertidoEm!),
              ]),
            ),
          ),

          if (_lead.observacoes != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Observações',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(_lead.observacoes!),
                ]),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),

          // Ações rápidas
          if (_lead.telefone != null) ...[
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _ligar,
                  icon: const Icon(Icons.phone),
                  label: const Text('Ligar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _whatsapp,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          FilledButton.icon(
            onPressed: _converter,
            icon: const Icon(Icons.person_add),
            label: const Text('Converter em Aluno'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _arquivar,
            icon: const Icon(Icons.archive),
            label: const Text('Arquivar Lead'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
          ),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}
