import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';

class AgendaAlunoScreen extends ConsumerStatefulWidget {
  const AgendaAlunoScreen({super.key});
  @override
  ConsumerState<AgendaAlunoScreen> createState() => _AgendaAlunoScreenState();
}

class _AgendaAlunoScreenState extends ConsumerState<AgendaAlunoScreen> {
  List<Agendamento> _ags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AgendaRepository(ref.read(apiClientProvider)).meusAgendamentos();
      if (mounted) setState(() { _ags = r; _loading = false; });
    } catch (e) { debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmar(Agendamento ag) async {
    try {
      await AgendaRepository(ref.read(apiClientProvider)).confirmarPresenca(ag.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Presença confirmada!');
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Minha Agenda')),
    body: RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? const FxLoading()
          : _ags.isEmpty
              ? ListView(children: const [
                  Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Nenhum agendamento encontrado.')),
                  ),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ags.length,
                  itemBuilder: (_, i) => _AgCard(ag: _ags[i], onConfirmar: _confirmar),
                ),
    ),
  );
}

class _AgCard extends StatelessWidget {
  final Agendamento ag;
  final void Function(Agendamento) onConfirmar;
  const _AgCard({required this.ag, required this.onConfirmar});

  @override
  Widget build(BuildContext context) {
    final inicio = ag.inicio;
    final fim = ag.fim;
    final cor = _statusColor(context, ag.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(
                ag.titulo ?? 'Sessão de treino',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            _StatusChip(status: ag.status, cor: cor),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: EagleTokens.inkMute),
            const SizedBox(width: 4),
            Text(
              '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}',
              style: const TextStyle(color: EagleTokens.inkMute, fontSize: 13),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 14, color: EagleTokens.inkMute),
            const SizedBox(width: 4),
            Text(
              '${_hm(inicio)} – ${_hm(fim)}',
              style: const TextStyle(color: EagleTokens.inkMute, fontSize: 13),
            ),
          ]),
          if (ag.status == 'AGENDADO') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => onConfirmar(ag),
                child: const Text('Confirmar presença'),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Color _statusColor(BuildContext context, String s) {
    switch (s) {
      case 'AGENDADO': return Theme.of(context).colorScheme.primary;
      case 'CONFIRMADO': return EagleTokens.good;
      case 'CONCLUIDO': return Theme.of(context).colorScheme.primary;
      case 'CANCELADO': return EagleTokens.inkMute;
      default: return EagleTokens.inkMute;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final Color cor;
  const _StatusChip({required this.status, required this.cor});

  static const _label = {
    'AGENDADO': 'Agendado',
    'CONFIRMADO': 'Confirmado',
    'CONCLUIDO': 'Concluído',
    'CANCELADO': 'Cancelado',
  };

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(_label[status] ?? status,
        style: TextStyle(color: cor, fontSize: 11)),
    backgroundColor: cor.withValues(alpha: 0.12),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
  );
}
