import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../../../core/widgets/fx_loading.dart';

class EngajamentoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EngajamentoScreen({super.key, required this.alunoId, required this.alunoNome});

  @override
  ConsumerState<EngajamentoScreen> createState() => _EngajamentoScreenState();
}

class _EngajamentoScreenState extends ConsumerState<EngajamentoScreen> {
  int _dias = 30;
  List<EventoEngajamento> _eventos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final eventos = await repo.engajamento(widget.alunoId, dias: _dias);
      if (mounted) setState(() { _eventos = eventos; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = e.toString(); _loading = false; });
    }
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'CHECKIN_CONCLUIDO': return Icons.fitness_center;
      case 'TREINO_INICIADO': return Icons.play_arrow;
      default: return Icons.circle;
    }
  }

  String _formatarDataHora(String dataHora) {
    try {
      final dt = DateTime.parse(dataHora).toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd/$mm $hh:$min';
    } catch (e) { debugPrint('[Focux] Error: $e');
      return dataHora.length >= 16 ? dataHora.substring(0, 16) : dataHora;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Engajamento — ${widget.alunoNome}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<int>(
              value: _dias,
              underline: const SizedBox(),
              items: [30, 60, 90]
                  .map((d) => DropdownMenuItem(value: d, child: Text('$d dias')))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _dias = v);
                  _load();
                }
              },
            ),
          ),
        ],
      ),
      body: _loading
          ? const FxLoading()
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : _eventos.isEmpty
                  ? const Center(child: Text('Nenhum evento registrado'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _eventos.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final e = _eventos[i];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Icon(
                              _iconForTipo(e.tipo),
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(e.descricao),
                          subtitle: Text(e.tipo),
                          trailing: Text(
                            _formatarDataHora(e.dataHora),
                            style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute),
                          ),
                        );
                      },
                    ),
    );
  }
}
