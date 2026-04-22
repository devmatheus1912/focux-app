import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/broadcast_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => BroadcastRepository(ref.read(apiClientProvider)),
);

final _broadcastHistoricoProvider = FutureProvider<List<Broadcast>>((ref) {
  return ref.read(_broadcastRepositoryProvider).listar();
});

// ---------------------------------------------------------------------------
// Tela principal de broadcasts
// ---------------------------------------------------------------------------

/// Tela de Central de Mensageria — envia notificações push em massa para alunos.
class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  String _publicoAlvo = 'TODOS';
  bool _enviando = false;

  static const List<Map<String, String>> _opcoesPublico = [
    {'valor': 'TODOS', 'label': 'Todos os alunos'},
    {'valor': 'ONLINE', 'label': 'Online'},
    {'valor': 'PRESENCIAL', 'label': 'Presencial'},
    {'valor': 'HIBRIDO', 'label': 'Híbrido'},
  ];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    try {
      final repo = ref.read(_broadcastRepositoryProvider);
      final resultado = await repo.enviar(
        titulo: _tituloCtrl.text.trim(),
        mensagem: _mensagemCtrl.text.trim(),
        tipoConsultoriaAlvo: _publicoAlvo == 'TODOS' ? null : _publicoAlvo,
      );

      // Limpa o formulário e atualiza o histórico
      _tituloCtrl.clear();
      _mensagemCtrl.clear();
      setState(() => _publicoAlvo = 'TODOS');
      ref.invalidate(_broadcastHistoricoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Broadcast enviado para ${resultado.totalEnviados} aluno(s)!',
            ),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historicoAsync = ref.watch(_broadcastHistoricoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Central de Mensageria')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Formulário de envio
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Novo Broadcast',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Título
                      TextFormField(
                        controller: _tituloCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          hintText: 'Ex.: Treino cancelado hoje',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 100,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
                      ),
                      const SizedBox(height: 12),

                      // Mensagem
                      TextFormField(
                        controller: _mensagemCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mensagem *',
                          hintText: 'Digite sua mensagem para os alunos...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 4,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Informe a mensagem' : null,
                      ),
                      const SizedBox(height: 12),

                      // Público-alvo
                      DropdownButtonFormField<String>(
                        value: _publicoAlvo,
                        decoration: const InputDecoration(
                          labelText: 'Público-alvo',
                          border: OutlineInputBorder(),
                        ),
                        items: _opcoesPublico
                            .map((opcao) => DropdownMenuItem<String>(
                                  value: opcao['valor'],
                                  child: Text(opcao['label']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _publicoAlvo = v ?? 'TODOS'),
                      ),
                      const SizedBox(height: 20),

                      // Botão enviar
                      FilledButton.icon(
                        onPressed: _enviando ? null : _enviar,
                        icon: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          _enviando ? 'Enviando...' : 'Enviar notificação',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Histórico
            Text(
              'Histórico de Broadcasts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            historicoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro ao carregar histórico: $e'),
              data: (lista) {
                if (lista.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Nenhum broadcast enviado ainda.',
                        style: TextStyle(color: EagleTokens.inkMute),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final broadcast = lista[index];
                    return _BroadcastCard(broadcast: broadcast);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card do histórico
// ---------------------------------------------------------------------------

class _BroadcastCard extends StatelessWidget {
  final Broadcast broadcast;

  const _BroadcastCard({required this.broadcast});

  @override
  Widget build(BuildContext context) {
    final dataFormatada = _formatarData(broadcast.enviadoEm);
    final publico = broadcast.tipoConsultoriaAlvo != null
        ? broadcast.tipoConsultoriaAlvo!
        : 'Todos';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    broadcast.titulo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(
                    '${broadcast.totalEnviados} enviado(s)',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              broadcast.mensagem,
              style: const TextStyle(color: EagleTokens.inkMute),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 14, color: EagleTokens.inkMute),
                const SizedBox(width: 4),
                Text(
                  publico,
                  style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute),
                ),
                const Spacer(),
                const Icon(Icons.schedule, size: 14, color: EagleTokens.inkMute),
                const SizedBox(width: 4),
                Text(
                  dataFormatada,
                  style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${dt.year} $hora:$min';
  }
}
