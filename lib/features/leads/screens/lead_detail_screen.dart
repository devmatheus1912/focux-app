import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
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
  'LEAD': EagleTokens.primary,
  'TESTE': EagleTokens.warning,
  'ATIVO': EagleTokens.success,
  'INADIMPLENTE': EagleTokens.danger,
  'CANCELADO': EagleTokens.textSecondary,
};

const _tiposInteracao = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
const _tipoIcons = {
  'WHATSAPP': Icons.chat,
  'LIGACAO': Icons.phone,
  'EMAIL': Icons.email,
  'PRESENCIAL': Icons.handshake,
  'OUTRO': Icons.note,
};

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  late Lead _lead;
  List<LeadInteracao> _interacoes = [];
  bool _loadingInteracoes = true;

  @override
  void initState() {
    super.initState();
    _lead = widget.lead;
    _carregarInteracoes();
  }

  Future<void> _carregarInteracoes() async {
    setState(() => _loadingInteracoes = true);
    try {
      final repo = LeadRepository(ref.read(apiClientProvider));
      final lista = await repo.listarInteracoes(_lead.id);
      if (mounted) setState(() { _interacoes = lista; _loadingInteracoes = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingInteracoes = false);
    }
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
          const SnackBar(content: Text('Lead convertido!')),
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

  Future<void> _definirFollowUp() async {
    final now = DateTime.now();
    DateTime? inicial;
    if (_lead.proximoContato != null) {
      try {
        inicial = DateTime.parse(_lead.proximoContato!);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Selecione a data de follow-up',
    );
    if (picked == null) return;
    final dataStr =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    try {
      final updated = await LeadRepository(ref.read(apiClientProvider))
          .atualizarProximoContato(_lead.id, dataStr);
      setState(() => _lead = updated);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Follow-up definido para $dataStr')),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _novaInteracao() async {
    String tipo = 'WHATSAPP';
    final descCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Nova Interação',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _tiposInteracao
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Row(children: [
                          Icon(_tipoIcons[t] ?? Icons.note, size: 18),
                          const SizedBox(width: 8),
                          Text(t),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) { if (v != null) setS(() => tipo = v); },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição *',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Salvar'),
                onPressed: () async {
                  final desc = descCtrl.text.trim();
                  if (desc.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Informe a descrição')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await LeadRepository(ref.read(apiClientProvider))
                        .adicionarInteracao(_lead.id, tipo, desc);
                    await _carregarInteracoes();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Interação registrada!')),
                    );
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Erro: $e')));
                  }
                },
              ),
            ),
          ]),
        ),
      ),
    );
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[_lead.status] ?? EagleTokens.textSecondary;
    final podeConverter =
        _lead.status != 'CONVERTIDO' && _lead.status != 'ATIVO';

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
                            color: _statusColors[s] ?? EagleTokens.textSecondary),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novaInteracao,
        icon: const Icon(Icons.add_comment),
        label: const Text('Nova Interação'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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

          // Próximo Contato / Follow-up
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                const Icon(Icons.event, color: const Color(0xFF6D28D9)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Próximo Contato',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: EagleTokens.textSecondary,
                            )),
                    const SizedBox(height: 2),
                    Text(
                      _lead.proximoContato ?? 'Não definido',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _lead.proximoContato != null
                            ? const Color(0xFF6D28D9)
                            : EagleTokens.textSecondary,
                      ),
                    ),
                  ]),
                ),
                TextButton.icon(
                  onPressed: _definirFollowUp,
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Definir follow-up'),
                ),
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
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: EagleTokens.textSecondary)),
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
                  style: OutlinedButton.styleFrom(foregroundColor: EagleTokens.success),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          if (podeConverter) ...[
            FilledButton.tonal(
              onPressed: _converter,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add),
                  SizedBox(width: 8),
                  Text('Converter em Aluno'),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          OutlinedButton.icon(
            onPressed: _arquivar,
            icon: const Icon(Icons.archive),
            label: const Text('Arquivar Lead'),
            style: OutlinedButton.styleFrom(foregroundColor: EagleTokens.textSecondary),
          ),

          // Interações
          const SizedBox(height: 24),
          Row(children: [
            const Icon(Icons.timeline, size: 20),
            const SizedBox(width: 8),
            Text('Interações',
                style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            if (!_loadingInteracoes)
              Text('${_interacoes.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: EagleTokens.textSecondary)),
          ]),
          const SizedBox(height: 8),

          if (_loadingInteracoes)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ))
          else if (_interacoes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma interação registrada.',
                    style: TextStyle(color: EagleTokens.textSecondary)),
              ),
            )
          else
            ..._interacoes.reversed.map((i) => _InteracaoTile(interacao: i)),
        ]),
      ),
    );
  }
}

class _InteracaoTile extends StatelessWidget {
  final LeadInteracao interacao;
  const _InteracaoTile({required this.interacao});

  @override
  Widget build(BuildContext context) {
    final icon = _tipoIcons[interacao.tipo] ?? Icons.note;
    final dataStr = interacao.dataInteracao != null
        ? (interacao.dataInteracao!.length >= 10
            ? interacao.dataInteracao!.substring(0, 10)
            : interacao.dataInteracao!)
        : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18,
                color: Theme.of(context).colorScheme.primary),
          ),
          Container(
            width: 2,
            height: 24,
            color: Theme.of(context).dividerColor,
          ),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(interacao.tipo,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                if (dataStr.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(dataStr,
                      style: const TextStyle(
                          fontSize: 11, color: EagleTokens.textSecondary)),
                ],
              ]),
              const SizedBox(height: 2),
              Text(interacao.descricao, style: const TextStyle(fontSize: 13)),
            ]),
          ),
        ),
      ],
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
      Text(label, style: const TextStyle(color: EagleTokens.textSecondary)),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}
