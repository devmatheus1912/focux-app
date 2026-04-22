import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';

class AgendaSemanalScreen extends ConsumerStatefulWidget {
  const AgendaSemanalScreen({super.key});

  @override
  ConsumerState<AgendaSemanalScreen> createState() => _AgendaSemanalScreenState();
}

class _AgendaSemanalScreenState extends ConsumerState<AgendaSemanalScreen> {
  List<Agendamento> _agendamentos = [];
  bool _loading = true;
  late DateTime _semanaBase;

  static const List<String> _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _semanaBase = _segundaDaSemana(DateTime.now());
    _carregar();
  }

  DateTime _segundaDaSemana(DateTime ref) {
    final diaSemana = ref.weekday; // 1=Seg, 7=Dom
    return DateTime(ref.year, ref.month, ref.day).subtract(Duration(days: diaSemana - 1));
  }

  String _dataParam(DateTime segunda) {
    return '${segunda.year}-${segunda.month.toString().padLeft(2, '0')}-${segunda.day.toString().padLeft(2, '0')}';
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final repo = AgendaRepository(ref.read(apiClientProvider));
      final lista = await repo.listarSemana(_dataParam(_semanaBase));
      if (mounted) setState(() { _agendamentos = lista; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _semanaAnterior() {
    setState(() => _semanaBase = _semanaBase.subtract(const Duration(days: 7)));
    _carregar();
  }

  void _proximaSemana() {
    setState(() => _semanaBase = _semanaBase.add(const Duration(days: 7)));
    _carregar();
  }

  List<Agendamento> _agsDoDia(int diaIndex) {
    final dia = _semanaBase.add(Duration(days: diaIndex));
    return _agendamentos.where((ag) =>
      ag.inicio.year == dia.year &&
      ag.inicio.month == dia.month &&
      ag.inicio.day == dia.day
    ).toList()..sort((a, b) => a.inicio.compareTo(b.inicio));
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _cabecalhoDia(int diaIndex) {
    final dia = _semanaBase.add(Duration(days: diaIndex));
    return '${dia.day}/${dia.month}';
  }

  Color _corStatus(String? s) {
    switch (s) {
      case 'PRESENTE': return EagleTokens.good;
      case 'FALTA': return EagleTokens.bad;
      case 'CANCELADO': return EagleTokens.inkMute;
      default: return EagleTokens.brand;
    }
  }

  Future<void> _abrirDialogStatus(Agendamento ag) async {
    String statusSelecionado = ag.statusAtendimento ?? 'PRESENTE';
    final obsController = TextEditingController(text: ag.observacoesPosAtendimento ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(ag.titulo ?? ag.alunoNome),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${ag.alunoNome} • ${_hm(ag.inicio)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),
              const Text('Status de atendimento'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: statusSelecionado,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const ['PRESENTE', 'FALTA', 'CANCELADO']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => statusSelecionado = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: obsController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final repo = AgendaRepository(ref.read(apiClientProvider));
                  await repo.registrarStatusAtendimento(
                      ag.id, statusSelecionado, obsController.text.isEmpty ? null : obsController.text);
                  await _carregar();
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erro ao registrar status.')));
                  }
                }
              },
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Agendamento ag) {
    final statusAte = ag.statusAtendimento;
    return GestureDetector(
      onTap: () => _abrirDialogStatus(ag),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ag.alunoNome,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${_hm(ag.inicio)} – ${_hm(ag.fim)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _corStatus(statusAte).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusAte ?? ag.status,
                  style: TextStyle(fontSize: 10, color: _corStatus(statusAte)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColuna(int diaIndex) {
    final ags = _agsDoDia(diaIndex);
    final dia = _semanaBase.add(Duration(days: diaIndex));
    final isHoje = dia.year == DateTime.now().year &&
        dia.month == DateTime.now().month &&
        dia.day == DateTime.now().day;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isHoje ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Text(_diasSemana[diaIndex],
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isHoje ? Theme.of(context).colorScheme.primary : null)),
                Text(_cabecalhoDia(diaIndex),
                    style: const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
          const Divider(height: 4),
          if (ags.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('–', style: TextStyle(fontSize: 12, color: Colors.black26),
                  textAlign: TextAlign.center),
            )
          else
            ...ags.map(_buildCard),
        ],
      ),
    );
  }

  String _tituloPeriodo() {
    final domingo = _semanaBase.add(const Duration(days: 6));
    return '${_semanaBase.day}/${_semanaBase.month} – ${domingo.day}/${domingo.month}/${domingo.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_tituloPeriodo()),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Semana anterior',
          onPressed: _semanaAnterior,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Próxima semana',
            onPressed: _proximaSemana,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width < 700
                    ? 700
                    : MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(7, (i) {
                      final coluna = _buildColuna(i);
                      if (i < 6) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            coluna,
                            const VerticalDivider(width: 1),
                          ],
                        );
                      }
                      return coluna;
                    }),
                  ),
                ),
              ),
            ),
    );
  }
}
