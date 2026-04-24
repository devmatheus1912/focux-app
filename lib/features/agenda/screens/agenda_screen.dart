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
    } catch (e) { debugPrint('[Focux] Error: $e'); setState(() => _loading = false); }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const _NovoAgendamentoScreen()));
            _load();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_ags.length} PRÓXIMOS',
                        style: TextStyle(fontSize: 12, color: mute, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Agenda',
                        style: TextStyle(fontSize: 32, color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.calendar_view_week, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
                    tooltip: 'Visão semanal',
                    onPressed: () => context.push('/agenda/semanal'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: EagleTokens.brand))
                  : _ags.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 64, height: 64, decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.calendar_today, color: EagleTokens.brand, size: 28)),
                          const SizedBox(height: 14),
                          Text('Nenhum agendamento', style: TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Agende sessões com seus alunos.', style: TextStyle(color: mute, fontSize: 14)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: _ags.length,
                          itemBuilder: (_, i) {
                            final ag = _ags[i];
                            final inicio = ag.inicio;
                            final badge = _dateBadge(inicio);
                            return Dismissible(
                              key: Key('ag_${ag.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(color: EagleTokens.bad, borderRadius: BorderRadius.circular(14)),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(Icons.delete, color: Colors.white)),
                              onDismissed: (_) async {
                                await AgendaRepository(ref.read(apiClientProvider)).excluir(ag.id);
                                setState(() => _ags.removeAt(i));
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft),
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: EagleTokens.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                      Text('${inicio.day}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: ink)),
                                      Text(_monthAbbr(inicio.month), style: TextStyle(fontSize: 10, color: mute)),
                                    ]),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Row(children: [
                                      Expanded(child: Text(ag.titulo ?? ag.alunoNome, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: ink))),
                                      if (badge != null) badge,
                                    ]),
                                    const SizedBox(height: 4),
                                    Text('${ag.alunoNome} · ${_hm(inicio)} – ${_hm(ag.fim)}', style: TextStyle(fontSize: 12, color: mute)),
                                  ])),
                                  const SizedBox(width: 8),
                                  _statusChip(ag.status),
                                ]),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

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
