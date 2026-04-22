import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});
  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  List<Agendamento> _ags = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await AgendaRepository(ref.read(apiClientProvider)).proximos();
      setState(() { _ags = r; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  // AG2 — retorna badge "HOJE", "AMANHÃ" ou null
  Widget? _dateBadge(DateTime inicio) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final day = DateTime(inicio.year, inicio.month, inicio.day);

    if (day == today) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text('HOJE',
              style: TextStyle(
                  color: EagleTokens.bad, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      );
    } else if (day == tomorrow) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text('AMANHÃ',
              style: TextStyle(
                  color: EagleTokens.warn, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Agenda'),
      actions: [
        // AG4 — navega para visão semanal
        IconButton(
          icon: const Icon(Icons.calendar_view_week),
          tooltip: 'Visão semanal',
          onPressed: () => context.push('/agenda/semanal'),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const _NovoAgendamentoScreen()));
        _load();
      },
      child: const Icon(Icons.add),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _ags.isEmpty
            ? const Center(child: Text('Nenhum agendamento próximo.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _ags.length,
                itemBuilder: (_, i) {
                  final ag = _ags[i];
                  final inicio = ag.inicio;
                  final badge = _dateBadge(inicio);
                  return Dismissible(
                    key: Key('ag_${ag.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(color: EagleTokens.bad,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      child: const Icon(Icons.delete, color: Colors.white)),
                    onDismissed: (_) async {
                      await AgendaRepository(ref.read(apiClientProvider)).excluir(ag.id);
                      setState(() => _ags.removeAt(i));
                    },
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text('${inicio.day}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text(_monthAbbr(inicio.month), style: const TextStyle(fontSize: 12)),
                        ]),
                        title: Row(
                          children: [
                            Expanded(child: Text(ag.titulo ?? ag.alunoNome)),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              badge,
                            ],
                          ],
                        ),
                        subtitle: Text('${ag.alunoNome} • ${_hm(inicio)} – ${_hm(ag.fim)}'),
                        trailing: _statusChip(ag.status),
                      ),
                    ),
                  );
                },
              ),
  );

  String _monthAbbr(int m) => ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'][m];
  String _hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Widget _statusChip(String s) => Chip(
    label: Text(s, style: const TextStyle(fontSize: 11)),
    backgroundColor: (s == 'AGENDADO' ? EagleTokens.brand : s == 'CONCLUIDO' ? EagleTokens.good : EagleTokens.inkMute)
        .withValues(alpha: 0.15),
  );
}

class _NovoAgendamentoScreen extends ConsumerStatefulWidget {
  const _NovoAgendamentoScreen();
  @override
  ConsumerState<_NovoAgendamentoScreen> createState() => _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends ConsumerState<_NovoAgendamentoScreen> {
  final _titulo = TextEditingController();
  final _alunoId = TextEditingController();
  DateTime? _inicio;
  DateTime? _fim;
  bool _saving = false;

  // AG1 — date picker livre: sem restrição de dia da semana, range amplo
  Future<void> _pickDateTime(bool isInicio) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isInicio) { _inicio = dt; } else { _fim = dt; }
    });
  }

  Future<void> _salvar() async {
    final alunoId = int.tryParse(_alunoId.text);
    if (alunoId == null || _inicio == null || _fim == null) return;
    setState(() => _saving = true);
    try {
      await AgendaRepository(ref.read(apiClientProvider))
          .criar(alunoId, _inicio!, _fim!, _titulo.text.isEmpty ? null : _titulo.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  String _fmtDt(DateTime? dt) => dt == null
      ? 'Selecionar'
      : '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo Agendamento')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      TextFormField(controller: _alunoId, decoration: const InputDecoration(labelText: 'ID do Aluno *'),
          keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      TextFormField(controller: _titulo, decoration: const InputDecoration(labelText: 'Título (opcional)')),
      const SizedBox(height: 16),
      ListTile(title: const Text('Início'), subtitle: Text(_fmtDt(_inicio)),
          trailing: const Icon(Icons.calendar_today), onTap: () => _pickDateTime(true)),
      ListTile(title: const Text('Fim'), subtitle: Text(_fmtDt(_fim)),
          trailing: const Icon(Icons.calendar_today), onTap: () => _pickDateTime(false)),
      const SizedBox(height: 16),
      FilledButton(onPressed: _saving ? null : _salvar, child: const Text('Agendar')),
    ])),
  );
}
