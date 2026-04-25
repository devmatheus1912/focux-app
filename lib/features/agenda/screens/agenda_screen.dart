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
  int _hojeIdx = 0;
  int _selectedIdx = 0;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _hojeIdx = now.weekday - 1; // 0 = Monday, 6 = Sunday
    _selectedIdx = _hojeIdx;
    _weekStart = now.subtract(Duration(days: _hojeIdx));
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await AgendaRepository(ref.read(apiClientProvider)).proximos();
      setState(() { _ags = r; _loading = false; });
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s, bool isDark) {
    if (s == 'PRESENTE' || s == 'CONCLUIDO') return isDark ? const Color(0xFF6FE296) : EagleTokens.good;
    if (s == 'FALTA' || s == 'CANCELADO') return isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad;
    return isDark ? EagleTokens.brandAccent : EagleTokens.brand; // AGENDADO
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = isDark ? EagleTokens.brandAccent : EagleTokens.brand;

    final diasSemanaStr = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    // Map events to their weekday index (0-6)
    final eventosMap = <int, List<Agendamento>>{};
    for (var i = 0; i < 7; i++) eventosMap[i] = [];
    
    for (final ag in _ags) {
      // we only consider events in the current week view to match the UI
      final diff = ag.inicio.difference(_weekStart).inDays;
      if (diff >= 0 && diff < 7) {
        eventosMap[ag.inicio.weekday - 1]?.add(ag);
      }
    }

    final dailyEvents = eventosMap[_selectedIdx] ?? [];
    final selectedDate = _weekStart.add(Duration(days: _selectedIdx));

    final monthNames = ['', 'jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    
    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandDeep]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark) BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))
          ],
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (context.canPop()) ...[
                        InkWell(
                          onTap: () => context.pop(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_back_ios_new, size: 24, color: ink),
                          ),
                        ),
                      ],
                      Text('Agenda', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: isDark ? null : Border.all(color: line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chevron_left, size: 16, color: mute),
                        const SizedBox(width: 4),
                        Text(
                          '${_weekStart.day}–${_weekStart.add(const Duration(days: 6)).day} ${monthNames[_weekStart.month]}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: mute),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Day tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(7, (i) {
                  final isSelected = i == _selectedIdx;
                  final dayDate = _weekStart.add(Duration(days: i));
                  final count = (eventosMap[i] ?? []).length;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIdx = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      constraints: const BoxConstraints(minWidth: 46),
                      decoration: BoxDecoration(
                        color: isSelected ? brand : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected ? null : Border.all(color: isDark ? Colors.transparent : line),
                        boxShadow: isSelected && !isDark ? [BoxShadow(color: brand.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))] : null,
                      ),
                      child: Column(
                        children: [
                          Text(diasSemanaStr[i], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : mute)),
                          const SizedBox(height: 2),
                          Text('${dayDate.day}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : ink, height: 1.2)),
                          if (count > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 16, height: 16,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white.withValues(alpha: 0.3) : brand,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text('$count', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 16),

            // Today's info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text.rich(TextSpan(
                children: [
                  TextSpan(text: '${diasSemanaStr[_selectedIdx]} · ${selectedDate.day} ${monthNames[selectedDate.month]} · ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: ink, letterSpacing: -0.2)),
                  TextSpan(text: '${dailyEvents.length} atendimentos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: brand, letterSpacing: -0.2)),
                ],
              )),
            ),

            // Events List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: dailyEvents.length + 1, // +1 for the Add Slot button
                      itemBuilder: (_, i) {
                        if (i == dailyEvents.length) {
                          // Add slot button
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const _NovoAgendamentoScreen()));
                              _load();
                            },
                            child: Container(
                              height: 52,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: mute.withValues(alpha: 0.3), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 18, color: mute),
                                  const SizedBox(width: 6),
                                  Text('Novo agendamento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mute)),
                                ],
                              ),
                            ),
                          );
                        }

                        final e = dailyEvents[i];
                        final sColor = _statusColor(e.status, isDark);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: isDark ? null : Border.all(color: line),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 52,
                                child: Column(
                                  children: [
                                    Text('${e.inicio.hour.toString().padLeft(2, '0')}:${e.inicio.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: brand, fontFamily: 'monospace')),
                                    Container(
                                      width: 2, height: 20,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: brand.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 40, height: 40,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(color: isDark ? EagleTokens.brandDeep : EagleTokens.brand, shape: BoxShape.circle),
                                alignment: Alignment.center,
                                child: Text(e.alunoNome.isNotEmpty ? e.alunoNome[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.titulo ?? e.alunoNome, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink), overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(width: 5, height: 5, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
                                        const SizedBox(width: 5),
                                        Text(e.status, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: sColor)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 34, height: 34,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.06) : EagleTokens.brandSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                alignment: Alignment.center,
                                child: Icon(Icons.chevron_right, size: 18, color: brand),
                              ),
                            ],
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
