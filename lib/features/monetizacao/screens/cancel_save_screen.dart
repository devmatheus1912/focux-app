import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/cancel_save_repository.dart';

final _repoProvider = Provider(
  (ref) => CancelSaveRepository(ref.read(apiClientProvider)),
);

class CancelSaveScreen extends ConsumerStatefulWidget {
  const CancelSaveScreen({super.key});

  @override
  ConsumerState<CancelSaveScreen> createState() => _CancelSaveScreenState();
}

class _CancelSaveScreenState extends ConsumerState<CancelSaveScreen> {
  static const _motivos = <_Motivo>[
    _Motivo('MUITO_CARO', 'Está caro demais agora', Icons.attach_money),
    _Motivo('NAO_USO', 'Não estou usando o suficiente', Icons.timelapse),
    _Motivo(
      'FALTA_FUNCIONALIDADE',
      'Faltou uma funcionalidade que preciso',
      Icons.extension_outlined,
    ),
    _Motivo(
      'MUDANDO_FERRAMENTA',
      'Vou usar outra ferramenta',
      Icons.swap_horiz,
    ),
    _Motivo('OUTRO', 'Outro motivo', Icons.help_outline),
  ];

  String? _motivoSelecionado;
  CancelSaveOferta? _oferta;
  bool _carregandoOferta = false;
  bool _enviando = false;
  String? _feedback;

  Future<void> _selecionarMotivo(String motivo) async {
    setState(() {
      _motivoSelecionado = motivo;
      _carregandoOferta = true;
      _oferta = null;
    });
    try {
      final oferta = await ref.read(_repoProvider).oferta(motivo);
      if (!mounted) return;
      setState(() {
        _oferta = oferta;
        _carregandoOferta = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoOferta = false);
    }
  }

  Future<void> _responder(bool aceitar) async {
    if (_motivoSelecionado == null || _oferta == null) return;
    setState(() => _enviando = true);
    try {
      final resposta = await ref.read(_repoProvider).responder(
            motivo: _motivoSelecionado!,
            ofertaApresentada: _oferta!.tipo,
            aceitar: aceitar,
            feedback: _feedback,
          );
      if (!mounted) return;
      _showResultado(resposta);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _showResultado(CancelSaveResposta r) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          r.aceita ? Icons.celebration : Icons.exit_to_app,
          color: r.aceita ? Colors.green : Theme.of(ctx).colorScheme.outline,
          size: 48,
        ),
        title: Text(r.aceita ? 'Tudo certo!' : 'Cancelamento confirmado'),
        content: Text(r.mensagem),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antes de cancelar...')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Que pena que você quer ir embora.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Conta pra gente o motivo: a próxima tela tem uma alternativa que pode resolver.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          for (final m in _motivos)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _motivoSelecionado == m.codigo
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: _motivoSelecionado == m.codigo ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: Icon(m.icone),
                title: Text(m.label),
                trailing: _motivoSelecionado == m.codigo
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => _selecionarMotivo(m.codigo),
              ),
            ),
          const SizedBox(height: 16),
          if (_carregandoOferta)
            const Center(child: CircularProgressIndicator())
          else if (_oferta != null)
            _OfertaCard(
              oferta: _oferta!,
              enviando: _enviando,
              onAceitar: () => _responder(true),
              onRecusar: () => _responder(false),
              onFeedback: (txt) => _feedback = txt,
            ),
        ],
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    required this.oferta,
    required this.onAceitar,
    required this.onRecusar,
    required this.onFeedback,
    required this.enviando,
  });
  final CancelSaveOferta oferta;
  final VoidCallback onAceitar;
  final VoidCallback onRecusar;
  final ValueChanged<String> onFeedback;
  final bool enviando;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(.3),
        ),
      ),
      color: theme.colorScheme.primary.withOpacity(.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_offer_outlined,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(oferta.titulo,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(oferta.descricao,
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Quer deixar um feedback? (opcional)',
                border: OutlineInputBorder(),
              ),
              onChanged: onFeedback,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: enviando ? null : onAceitar,
                    icon: const Icon(Icons.check),
                    label: Text(oferta.ctaLabel.replaceAll('_', ' ')),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: enviando ? null : onRecusar,
                  child: const Text('Cancelar mesmo assim'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Motivo {
  const _Motivo(this.codigo, this.label, this.icone);
  final String codigo;
  final String label;
  final IconData icone;
}
