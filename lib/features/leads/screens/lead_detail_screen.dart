import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

const _statusOpcoes = ['LEAD', 'TESTE', 'ATIVO', 'INADIMPLENTE', 'CANCELADO'];
const _statusLabels = {
  'LEAD': 'Lead',
  'TESTE': 'Teste',
  'ATIVO': 'Ativo',
  'INADIMPLENTE': 'Inadimplente',
  'CANCELADO': 'Cancelado',
};
Color _statusColor(String status, Color fallback) {
  if (status == 'LEAD') return fallback;
  if (status == 'TESTE') return EagleTokens.warn;
  if (status == 'ATIVO') return EagleTokens.good;
  if (status == 'INADIMPLENTE') return EagleTokens.bad;
  return TokensStrip.textSecondary;
}

const _tiposInteracao = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
const _tipoIcons = {
  'WHATSAPP': Icons.chat,
  'LIGACAO': Icons.phone,
  'EMAIL': Icons.email,
  'PRESENCIAL': Icons.handshake,
  'OUTRO': Icons.note,
};

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead? lead;
  final int? leadId;

  const LeadDetailScreen({super.key, this.lead, this.leadId})
    : assert(lead != null || leadId != null);

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  Lead? _lead;
  List<LeadInteracao> _interacoes = [];
  bool _loadingLead = false;
  bool _loadingInteracoes = true;

  Lead get _activeLead {
    final lead = _lead;
    if (lead == null) {
      throw StateError('Lead ainda não carregado');
    }
    return lead;
  }

  @override
  void initState() {
    super.initState();
    if (widget.lead != null) {
      _lead = widget.lead;
      _carregarInteracoes();
    } else {
      _carregarLead();
    }
  }

  Future<void> _carregarLead() async {
    setState(() => _loadingLead = true);
    try {
      final lead = await LeadRepository(
        ref.read(apiClientProvider),
      ).buscar(widget.leadId!);
      if (mounted) {
        setState(() {
          _lead = lead;
          _loadingLead = false;
        });
        _carregarInteracoes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLead = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _carregarInteracoes() async {
    final lead = _lead;
    if (lead == null) return;
    setState(() => _loadingInteracoes = true);
    try {
      final repo = LeadRepository(ref.read(apiClientProvider));
      final lista = await repo.listarInteracoes(lead.id);
      if (mounted) {
        setState(() {
          _interacoes = lista;
          _loadingInteracoes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingInteracoes = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _ligar() async {
    if (_activeLead.telefone == null) return;
    final uri = Uri.parse('tel:${_activeLead.telefone}');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri);
    }
  }

  Future<void> _whatsapp() async {
    if (_activeLead.telefone == null) return;
    final tel = _activeLead.telefone!.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/55$tel');
    if (await canLaunchUrl(uri)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _mudarStatus(String novoStatus) async {
    try {
      final updated = await LeadRepository(
        ref.read(apiClientProvider),
      ).atualizar(_activeLead.id, {'status': novoStatus});
      setState(() => _lead = updated);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Status atualizado para ${_statusLabels[novoStatus]}',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _converter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Converter em Aluno?'),
            content: Text(
              '${_activeLead.nome} será criado como aluno na sua lista.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                expand: false,
                label: 'Converter',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await LeadRepository(
        ref.read(apiClientProvider),
      ).converter(_activeLead.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Lead convertido!');
        safePopOrGo(context, '/leads');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _arquivar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Arquivar lead?'),
            content: const Text('O lead será marcado como Cancelado.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FxLiquidPrimaryButton(
                expand: false,
                label: 'Arquivar',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await LeadRepository(
        ref.read(apiClientProvider),
      ).arquivar(_activeLead.id);
      if (mounted) safePopOrGo(context, '/leads');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _definirFollowUp() async {
    final now = DateTime.now();
    DateTime? inicial;
    if (_activeLead.proximoContato != null) {
      try {
        inicial = DateTime.parse(_activeLead.proximoContato!);
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
      final updated = await LeadRepository(
        ref.read(apiClientProvider),
      ).atualizarProximoContato(_activeLead.id, dataStr);
      setState(() => _lead = updated);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Follow-up definido para $dataStr');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _novaInteracao() async {
    String tipo = 'WHATSAPP';
    final descCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setS) => Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Nova Interação',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      DropdownButtonFormField<String>(
                        initialValue: tipo,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items:
                            _tiposInteracao
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _tipoIcons[t] ?? Icons.note,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(t),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v != null) setS(() => tipo = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          labelText: 'Descrição *',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      SizedBox(
                        width: double.infinity,
                        child: FxLiquidPrimaryButton(
                          icon: Icons.save,
                          label: 'Salvar',
                          onPressed: () async {
                            final desc = descCtrl.text.trim();
                            if (desc.isEmpty) {
                              FeedbackHelper.showError(
                                ctx,
                                'Informe a descrição',
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              await LeadRepository(
                                ref.read(apiClientProvider),
                              ).adicionarInteracao(_activeLead.id, tipo, desc);
                              await _carregarInteracoes();
                              if (mounted) {
                                FeedbackHelper.showSuccess(
                                  context,
                                  'Interação registrada!',
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                FeedbackHelper.showError(
                                  context,
                                  friendlyError(e),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
    descCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLead || _lead == null) {
      return fxScreenA11yScope(
        label: 'Lead',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Lead',
            onBack: () => safePopOrGo(context, '/leads'),
          ),
          body: const Center(child: FxLoading()),
        ),
      );
    }

    final lead = _lead!;
    final color = _statusColor(
      lead.status,
      Theme.of(context).colorScheme.primary,
    );
    final podeConverter = lead.status != 'CONVERTIDO' && lead.status != 'ATIVO';

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: lead.nome,
        onBack: () => safePopOrGo(context, '/leads'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _mudarStatus,
            itemBuilder:
                (_) =>
                    _statusOpcoes
                        .map(
                          (s) => PopupMenuItem(
                            value: s,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: _statusColor(
                                    s,
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_statusLabels[s] ?? s),
                              ],
                            ),
                          ),
                        )
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
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s4,
          TokensStrip.s4,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status chip
            Center(
              child: Chip(
                label: Text(
                  _statusLabels[lead.status] ?? lead.status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                backgroundColor: color.withValues(alpha: 0.12),
                avatar: Icon(Icons.circle, size: 10, color: color),
              ),
            ),
            const SizedBox(height: TokensStrip.s4),

            // Info card
            Container(
              decoration: fxListCardDecoration(context),
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s4),
                child: Column(
                  children: [
                    _InfoRow(label: 'Nome', value: lead.nome),
                    if (lead.telefone != null)
                      _InfoRow(label: 'Telefone', value: lead.telefone!),
                    if (lead.origem != null)
                      _InfoRow(label: 'Origem', value: lead.origem!),
                    if (lead.objetivo != null)
                      _InfoRow(label: 'Objetivo', value: lead.objetivo!),
                    _InfoRow(label: 'Cadastrado em', value: lead.criadoEm),
                    if (lead.convertidoEm != null)
                      _InfoRow(
                        label: 'Convertido em',
                        value: lead.convertidoEm!,
                      ),
                  ],
                ),
              ),
            ),

            // Próximo Contato / Follow-up
            const SizedBox(height: 12),
            Container(
              decoration: fxListCardDecoration(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s4,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: EagleTokens.purpleAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Próximo Contato',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: TokensStrip.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            lead.proximoContato ?? 'Não definido',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color:
                                  lead.proximoContato != null
                                      ? EagleTokens.purpleAccent
                                      : TokensStrip.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _definirFollowUp,
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Definir follow-up'),
                    ),
                  ],
                ),
              ),
            ),

            if (lead.observacoes != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: fxListCardDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Observações',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: TokensStrip.textSecondary),
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Text(lead.observacoes!),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: TokensStrip.s5),
            const Divider(),
            const SizedBox(height: 8),

            // Ações rápidas
            if (lead.telefone != null) ...[
              Row(
                children: [
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EagleTokens.good,
                      ),
                    ),
                  ),
                ],
              ),
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
              style: OutlinedButton.styleFrom(
                foregroundColor: TokensStrip.textSecondary,
              ),
            ),

            // Interações
            const SizedBox(height: TokensStrip.s5),
            Row(
              children: [
                const Icon(Icons.timeline, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Interações',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (!_loadingInteracoes)
                  Text(
                    '${_interacoes.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TokensStrip.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loadingInteracoes)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  child: FxLoading(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            else if (_interacoes.isEmpty)
              Container(
                decoration: fxListCardDecoration(context),
                child: const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: Text(
                    'Nenhuma interação registrada.',
                    style: TextStyle(color: TokensStrip.textSecondary),
                  ),
                ),
              )
            else
              ..._interacoes.reversed.map((i) => _InteracaoTile(interacao: i)),
          ],
        ),
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
    final dataStr =
        interacao.dataInteracao != null
            ? fxDateShort(DateTime.parse(interacao.dataInteracao!))
            : '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Container(
              width: 2,
              height: 24,
              color: Theme.of(context).dividerColor,
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      interacao.tipo,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (dataStr.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        dataStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: TokensStrip.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(interacao.descricao, style: const TextStyle(fontSize: 13)),
              ],
            ),
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
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: TokensStrip.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
