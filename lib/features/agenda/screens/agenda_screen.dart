import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../features/alunos/data/aluno_repository.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';

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
      if (!mounted) return;
      setState(() {
        _ags = r;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String s, bool isDark, Color primary) {
    if (s == 'PRESENTE' || s == 'CONCLUIDO') {
      return isDark ? const Color(0xFF6FE296) : EagleTokens.good;
    }
    if (s == 'FALTA') return isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad;
    if (s == 'CANCELADO') {
      return isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    }
    return primary; // AGENDADO
  }

  String _statusText(String status) {
    switch (status) {
      case 'AGENDADO':
        return 'Agendado';
      case 'PRESENTE':
        return 'Presente';
      case 'CONCLUIDO':
        return 'Concluído';
      case 'FALTA':
        return 'Falta';
      case 'CANCELADO':
        return 'Cancelado';
      default:
        return status;
    }
  }

  void _changeWeek(int delta) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: delta * 7));
      _selectedIdx = 0;
    });
  }

  Future<void> _copyIcalLink() async {
    try {
      final info = await AgendaRepository(ref.read(apiClientProvider)).icalToken();
      final fullUrl = info.url.startsWith('http') ? info.url : '${Env.apiUrl}${info.url}';
      await Clipboard.setData(ClipboardData(text: fullUrl));
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Link iCal copiado — cole no Google Calendar ou Apple Calendar.')),
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSnackBar(context, SnackBar(content: Text('Erro ao gerar link iCal: $e')));
      }
    }
  }

  Future<void> _openAgendamentoDetails(Agendamento ag) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AgendaEventSheet(
            agendamento: ag,
            statusLabel: _statusText(ag.status),
            onDelete: () async {
              await AgendaRepository(
                ref.read(apiClientProvider),
              ).excluir(ag.id);
              if (!mounted) return;
              Navigator.pop(context);
              _load();
              FeedbackHelper.showSnackBar(
                context,
                const SnackBar(content: Text('Agendamento excluído.')),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final cardBg = chrome.cardFill;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;

    final diasSemanaStr = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    // Map events to their weekday index (0-6)
    final eventosMap = <int, List<Agendamento>>{};
    for (var i = 0; i < 7; i++) {
      eventosMap[i] = [];
    }

    for (final ag in _ags) {
      // we only consider events in the current week view to match the UI
      final diff = ag.inicio.difference(_weekStart).inDays;
      if (diff >= 0 && diff < 7) {
        eventosMap[ag.inicio.weekday - 1]?.add(ag);
      }
    }

    final dailyEvents = eventosMap[_selectedIdx] ?? [];
    final selectedDate = _weekStart.add(Duration(days: _selectedIdx));

    final monthNames = [
      '',
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap:
                            () => safePopOrGo(context, '/dashboard/personal'),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 24,
                            color: ink,
                          ),
                        ),
                      ),
                      Text(
                        'Agenda',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Exportar iCal',
                        icon: Icon(Icons.calendar_month_outlined, color: mute, size: 22),
                        onPressed: _copyIcalLink,
                      ),
                      const ShellThemeToggle(size: 36),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: chrome.headerAction(radius: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => _changeWeek(-1),
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 16,
                                  color: mute,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_weekStart.day}–${_weekStart.add(const Duration(days: 6)).day} ${monthNames[_weekStart.month]}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _changeWeek(1),
                              borderRadius: BorderRadius.circular(999),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: mute,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label:
                        '${diasSemanaStr[i]} ${dayDate.day}, $count atendimento${count == 1 ? '' : 's'}',
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIdx = i),
                      child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      constraints: const BoxConstraints(minWidth: 46),
                      decoration: BoxDecoration(
                        color: isSelected ? primary : cardBg,
                        borderRadius: BorderRadius.circular(TokensStrip.rCard),
                        border:
                            isSelected
                                ? null
                                : Border.all(color: chrome.lineStrong),
                        boxShadow:
                            isSelected && !isDark
                                ? [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                                : null,
                      ),
                      child: Column(
                        children: [
                          Text(
                            diasSemanaStr[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : mute,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${dayDate.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : ink,
                              height: 1.2,
                            ),
                          ),
                          if (count > 0) ...[
                            const SizedBox(height: 4),
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: TokensStrip.s4),

            // Today's info
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 0, 20, 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text:
                          '${diasSemanaStr[_selectedIdx]} · ${selectedDate.day} ${monthNames[selectedDate.month]} · ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    TextSpan(
                      text:
                          dailyEvents.length == 1
                              ? '1 atendimento'
                              : '${dailyEvents.length} atendimentos',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: primary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Events List
            Expanded(
              child:
                  _loading
                      ? const FxLoading()
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 100),
                        itemCount:
                            dailyEvents.length + (dailyEvents.isEmpty ? 2 : 1),
                        itemBuilder: (_, i) {
                          if (dailyEvents.isEmpty && i == 0) {
                            return _AgendaEmptyState(
                              selectedDate:
                                  '${diasSemanaStr[_selectedIdx]}, ${selectedDate.day} ${monthNames[selectedDate.month]}',
                            );
                          }

                          if (i == dailyEvents.length ||
                              (dailyEvents.isEmpty && i == 1)) {
                            // Add slot button
                            return Semantics(
                              button: true,
                              label: 'Novo agendamento',
                              child: GestureDetector(
                                onTap: () async {
                                  await context.push('/agenda/novo');
                                  if (!mounted) return;
                                  _load();
                                },
                                child: Container(
                                height: 56,
                                margin: const EdgeInsets.only(top: 10),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(TokensStrip.rCard),
                                  color: primary,
                                  boxShadow: [
                                    if (!isDark)
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.18),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.add_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Novo agendamento',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ),
                            );
                          }

                          final eventIndex = dailyEvents.isEmpty ? i - 1 : i;
                          final e = dailyEvents[eventIndex];
                          final sColor = _statusColor(
                            e.status,
                            isDark,
                            primary,
                          );

                          return Semantics(
                            button: true,
                            label:
                                'Atendimento ${e.titulo ?? e.alunoNome}, ${_statusText(e.status)}, ${_hm(e.inicio)}',
                            child: InkWell(
                              onTap: () => _openAgendamentoDetails(e),
                              borderRadius:
                                  BorderRadius.circular(TokensStrip.rCard),
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration:
                                  fxListCardDecoration(context, accent: sColor),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 52,
                                    child: Column(
                                      children: [
                                        Text(
                                          '${e.inicio.hour.toString().padLeft(2, '0')}:${e.inicio.minute.toString().padLeft(2, '0')}',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: primary,
                                          ),
                                        ),
                                        Container(
                                          width: 2,
                                          height: 20,
                                          margin: const EdgeInsets.only(top: 4),
                                          decoration: BoxDecoration(
                                            color: primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      e.alunoNome.isNotEmpty
                                          ? e.alunoNome[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.titulo ?? e.alunoNome,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: ink,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              width: 5,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: sColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _statusText(e.status),
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w600,
                                                color: sColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color:
                                          isDark
                                              ? Colors.white.withValues(
                                                alpha: 0.06,
                                              )
                                              : primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  String _hm(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

BoxDecoration _agendaSheetDecoration(BuildContext context) {
  final chrome = ShellChrome.of(context);
  return BoxDecoration(
    color: chrome.sheetFill,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    border: Border(
      top: BorderSide(color: chrome.lineStrong),
      left: BorderSide(color: chrome.lineStrong),
      right: BorderSide(color: chrome.lineStrong),
    ),
  );
}

Widget _agendaSheetHandle(BuildContext context) => Center(
  child: Container(
    width: 38,
    height: 4,
    decoration: BoxDecoration(
      color: ShellChrome.of(context).lineStrong,
      borderRadius: BorderRadius.circular(999),
    ),
  ),
);

class _AgendaEmptyState extends StatelessWidget {
  final String selectedDate;

  const _AgendaEmptyState({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      container: true,
      label: 'Dia livre, $selectedDate. Nenhum atendimento marcado.',
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: chrome.cardFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: chrome.lineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: chrome.isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.event_available_outlined,
                    size: 19,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dia livre',
                        style: AppTypography.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: chrome.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selectedDate,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: chrome.mute,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Nenhum atendimento marcado. Use este espaço para encaixar uma avaliação, retorno ou sessão avulsa.',
              style: AppTypography.inter(
                fontSize: 12,
                height: 1.35,
                color: chrome.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaEventSheet extends StatelessWidget {
  final Agendamento agendamento;
  final String statusLabel;
  final Future<void> Function() onDelete;

  const _AgendaEventSheet({
    required this.agendamento,
    required this.statusLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final title = _displayTitle(agendamento.titulo ?? 'Atendimento');
    final time =
        agendamento.fim.isAfter(agendamento.inicio)
            ? '${_hm(agendamento.inicio)}–${_hm(agendamento.fim)}'
            : _hm(agendamento.inicio);
    final date =
        '${agendamento.inicio.day.toString().padLeft(2, '0')}/${agendamento.inicio.month.toString().padLeft(2, '0')}/${agendamento.inicio.year}';

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Detalhes do atendimento, $title, ${agendamento.alunoNome}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 10, 20, 20),
        decoration: _agendaSheetDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _agendaSheetHandle(context),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: chrome.isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.event_note_outlined,
                    size: 20,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: chrome.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        agendamento.alunoNome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: chrome.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Fechar detalhes do atendimento',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: chrome.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _AgendaInfoTile(label: 'Data', value: date)),
                const SizedBox(width: 10),
                Expanded(child: _AgendaInfoTile(label: 'Horário', value: time)),
              ],
            ),
            const SizedBox(height: 10),
            _AgendaInfoTile(label: 'Status', value: statusLabel),
            const SizedBox(height: TokensStrip.s4),
            Semantics(
              button: true,
              label: 'Excluir agendamento',
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Excluir agendamento'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EagleTokens.bad,
                  side: const BorderSide(color: EagleTokens.badSoft),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hm(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String _displayTitle(String value) {
    if (value.trim().toLowerCase() == 'avaliacao') return 'Avaliação';
    return value;
  }
}

class _AgendaInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _AgendaInfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: chrome.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: chrome.mute,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: chrome.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class NovoAgendamentoScreen extends ConsumerStatefulWidget {
  const NovoAgendamentoScreen({super.key});
  @override
  ConsumerState<NovoAgendamentoScreen> createState() =>
      _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends ConsumerState<NovoAgendamentoScreen> {
  final _titulo = TextEditingController();
  int? _alunoId;
  Aluno? _alunoSelecionado;
  DateTime? _inicio;
  DateTime? _fim;
  bool _saving = false;

  bool get _canSave => _alunoId != null && _inicio != null && _fim != null;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isInicio) async {
    final base =
        isInicio
            ? (_inicio ?? DateTime.now().add(const Duration(hours: 1)))
            : (_fim ??
                (_inicio ?? DateTime.now().add(const Duration(hours: 1))).add(
                  const Duration(hours: 1),
                ));
    final dt = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _AgendaDateTimeSheet(
            title: isInicio ? 'Início' : 'Fim',
            initial: base,
          ),
    );
    if (dt == null || !mounted) return;
    setState(() {
      if (isInicio) {
        _inicio = dt;
        if (_fim == null || !_fim!.isAfter(dt)) {
          _fim = dt.add(const Duration(hours: 1));
        }
      } else {
        _fim = dt;
      }
    });
  }

  Future<void> _showAlunoSheet(List<Aluno> alunos) async {
    final aluno = await showModalBottomSheet<Aluno>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgendaAlunoSheet(alunos: alunos, selectedId: _alunoId),
    );
    if (aluno == null || !mounted) return;
    setState(() {
      _alunoId = aluno.id;
      _alunoSelecionado = aluno;
    });
  }

  Future<void> _salvar() async {
    if (!_canSave) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(
          content: Text('Selecione aluno, início e fim para agendar.'),
        ),
      );
      return;
    }
    final alunoId = _alunoId;
    if (alunoId == null) {
      FeedbackHelper.showSuccess(context, 'Selecione um aluno.');
      return;
    }
    final inicio = _inicio!;
    final fim = _fim!;
    if (!fim.isAfter(inicio)) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Fim deve ser após início.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AgendaRepository(
        ref.read(apiClientProvider),
      ).criar(alunoId, inicio, fim, _titulo.text.isEmpty ? null : _titulo.text);
      if (mounted) safePopOrGo(context, '/agenda');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text('Erro ao agendar. Tente novamente.')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  String _fmtDt(DateTime? dt) =>
      dt == null
          ? 'Selecionar'
          : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.lineStrong;
    final enabled = _canSave && !_saving;

    return FxShellScaffold(
      useMesh: true,
      safeArea: false,
      appBar: FxShellAppBar(
        title: 'Novo agendamento',
        subtitle: 'AGENDA',
        onBack: () => safePopOrGo(context, '/agenda'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
          child: Semantics(
            button: true,
            enabled: enabled,
            label: _saving ? 'Agendando atendimento' : 'Agendar atendimento',
            child: FxLiquidPrimaryButton(
              label: 'Agendar',
              loadingLabel: 'Agendando…',
              loading: _saving,
              onPressed: enabled ? _salvar : null,
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: chrome.panel(radius: TokensStrip.rCard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ref
                        .watch(alunosProvider)
                        .when(
                          loading:
                              () => const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: LinearProgressIndicator(),
                              ),
                          error:
                              (e, _) => Text(
                                'Não foi possível carregar alunos.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                          data:
                              (alunos) => _AgendaAlunoButton(
                                aluno: _alunoSelecionado,
                                onTap: () => _showAlunoSheet(alunos),
                                embedded: true,
                              ),
                        ),
                    Divider(height: 20, thickness: 1, color: line),
                    Semantics(
                      textField: true,
                      label: 'Título opcional do atendimento',
                      child: TextFormField(
                        controller: _titulo,
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        cursorColor: primary,
                        decoration: InputDecoration(
                          hintText: 'Título (opcional)',
                          filled: true,
                          fillColor: chrome.cardFill,
                          hintStyle: TextStyle(
                            color: mute.withValues(alpha: 0.72),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: line),
                          ),
                          enabledBorder: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: line),
                          ),
                          focusedBorder: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: primary.withValues(alpha: 0.68),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AgendaHorarioCard(
                      inicioLabel: _fmtDt(_inicio),
                      fimLabel: _fmtDt(_fim),
                      inicioPlaceholder: _inicio == null,
                      fimPlaceholder: _fim == null,
                      onInicio: () => _pickDateTime(true),
                      onFim: () => _pickDateTime(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ao confirmar início, o fim é sugerido com +1 hora. Você pode ajustar depois.',
                style: AppTypography.inter(
                  fontSize: 11.5,
                  height: 1.35,
                  color: mute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaAlunoButton extends StatelessWidget {
  final Aluno? aluno;
  final VoidCallback onTap;
  final bool embedded;

  const _AgendaAlunoButton({
    required this.aluno,
    required this.onTap,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final hint = aluno == null ? 'Selecione quem será atendido' : aluno!.nome;
    return Semantics(
      button: true,
      label: 'Aluno, $hint',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Container(
          padding: EdgeInsets.all(embedded ? 4 : 12),
          decoration:
              embedded
                  ? null
                  : fxListCardDecoration(
                    context,
                    accent: aluno != null ? primary : null,
                  ),
          child: Row(
            children: [
              _AgendaAlunoAvatar(aluno: aluno),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aluno?.nome ?? 'Aluno',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: aluno == null ? chrome.mute : chrome.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aluno?.email ?? 'Selecione quem será atendido',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 11,
                        color: chrome.mute,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: chrome.mute,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaHorarioCard extends StatelessWidget {
  final String inicioLabel;
  final String fimLabel;
  final bool inicioPlaceholder;
  final bool fimPlaceholder;
  final VoidCallback onInicio;
  final VoidCallback onFim;

  const _AgendaHorarioCard({
    required this.inicioLabel,
    required this.fimLabel,
    required this.inicioPlaceholder,
    required this.fimPlaceholder,
    required this.onInicio,
    required this.onFim,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        children: [
          _AgendaDateTimeRow(
            label: 'Início',
            value: inicioLabel,
            isPlaceholder: inicioPlaceholder,
            onTap: onInicio,
          ),
          Divider(height: 1, thickness: 1, color: chrome.lineStrong),
          _AgendaDateTimeRow(
            label: 'Fim',
            value: fimLabel,
            isPlaceholder: fimPlaceholder,
            onTap: onFim,
          ),
        ],
      ),
    );
  }
}

class _AgendaDateTimeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _AgendaDateTimeRow({
    required this.label,
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: '$label, $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: chrome.mute,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isPlaceholder ? chrome.mute : chrome.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.calendar_today_outlined, size: 20, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaAlunoAvatar extends StatelessWidget {
  final Aluno? aluno;

  const _AgendaAlunoAvatar({required this.aluno});

  @override
  Widget build(BuildContext context) {
    final foto = aluno?.fotoUrl;
    final hasPhoto = foto != null && foto.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 42,
        height: 42,
        color: EagleTokens.brandSoft,
        child:
            hasPhoto
                ? Image.network(foto, fit: BoxFit.cover)
                : Center(
                  child: Text(
                    _initials(aluno?.nome ?? ''),
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: TokensStrip.primaryHover,
                    ),
                  ),
                ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }
}

class _AgendaAlunoSheet extends StatefulWidget {
  final List<Aluno> alunos;
  final int? selectedId;

  const _AgendaAlunoSheet({required this.alunos, required this.selectedId});

  @override
  State<_AgendaAlunoSheet> createState() => _AgendaAlunoSheetState();
}

class _AgendaAlunoSheetState extends State<_AgendaAlunoSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final query = _search.text.trim().toLowerCase();
    final alunos =
        widget.alunos.where((aluno) {
          if (query.isEmpty) return true;
          return aluno.nome.toLowerCase().contains(query) ||
              aluno.email.toLowerCase().contains(query) ||
              (aluno.objetivo ?? '').toLowerCase().contains(query);
        }).toList();

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Selecionar aluno, ${alunos.length} de ${widget.alunos.length}',
      child: DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder:
            (context, controller) => Container(
              decoration: _agendaSheetDecoration(context),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _agendaSheetHandle(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 18, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Selecionar aluno',
                              style: AppTypography.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: chrome.ink,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${alunos.length}/${widget.alunos.length}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          textField: true,
                          label: 'Buscar por nome, e-mail ou objetivo',
                          child: TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nome, e-mail ou objetivo',
                              prefixIcon: Icon(Icons.search, size: 19, color: chrome.mute),
                              filled: true,
                              fillColor: chrome.cardFill,
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: chrome.lineStrong),
                              ),
                              enabledBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: chrome.lineStrong),
                              ),
                              focusedBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: primary),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 0, 20, 28),
                    itemCount: alunos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final aluno = alunos[index];
                      final selected = aluno.id == widget.selectedId;
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: 'Aluno ${aluno.nome}${selected ? ', selecionado' : ''}',
                        child: InkWell(
                          onTap: () => Navigator.pop(context, aluno),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? primary.withValues(
                                        alpha: chrome.isDark ? 0.18 : 0.10,
                                      )
                                      : chrome.cardFill,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected ? primary : chrome.lineStrong,
                              ),
                            ),
                            child: Row(
                              children: [
                                _AgendaAlunoAvatar(aluno: aluno),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aluno.nome,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: chrome.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        [
                                          if ((aluno.objetivo ?? '').isNotEmpty)
                                            aluno.objetivo!,
                                          aluno.email,
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          fontSize: 11,
                                          color: chrome.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.chevron_right_rounded,
                                  color: selected ? primary : chrome.mute,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

class _AgendaDateTimeSheet extends StatefulWidget {
  final String title;
  final DateTime initial;

  const _AgendaDateTimeSheet({required this.title, required this.initial});

  @override
  State<_AgendaDateTimeSheet> createState() => _AgendaDateTimeSheetState();
}

class _AgendaDateTimeSheetState extends State<_AgendaDateTimeSheet> {
  late DateTime _selectedDay;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      widget.initial.year,
      widget.initial.month,
      widget.initial.day,
    );
    _selectedTime = TimeOfDay(
      hour: widget.initial.hour,
      minute: widget.initial.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final days = List.generate(
      14,
      (i) => DateTime.now().add(Duration(days: i)),
    );
    final slots = <TimeOfDay>[
      for (var hour = 6; hour <= 22; hour++)
        for (final minute in const [0, 30])
          TimeOfDay(hour: hour, minute: minute),
    ];

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Selecionar ${widget.title.toLowerCase()}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 10, 20, 20),
        decoration: _agendaSheetDecoration(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _agendaSheetHandle(context),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: AppTypography.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: chrome.ink,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final day = days[index];
                  final selected = _sameDay(day, _selectedDay);
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: '${_weekLabel(day.weekday)} ${day.day}',
                    child: InkWell(
                      onTap: () => setState(() => _selectedDay = day),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 58,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? primary : chrome.cardFill,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected ? primary : chrome.lineStrong,
                          ),
                        ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _weekLabel(day.weekday),
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color:
                                  selected ? Colors.white : TokensStrip.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: AppTypography.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: selected ? Colors.white : chrome.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            SizedBox(
              height: 230,
              child: GridView.builder(
                itemCount: slots.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.8,
                ),
                itemBuilder: (_, index) {
                  final slot = slots[index];
                  final selected =
                      slot.hour == _selectedTime.hour &&
                      slot.minute == _selectedTime.minute;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: 'Horário ${_timeLabel(slot)}',
                    child: InkWell(
                      onTap: () => setState(() => _selectedTime = slot),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? primary : chrome.cardFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected ? primary : chrome.lineStrong,
                          ),
                        ),
                        child: Text(
                          _timeLabel(slot),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : chrome.ink,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Confirmar horário',
              child: FxLiquidPrimaryButton(
                label: 'Confirmar horário',
                onPressed: () {
                  Navigator.pop(
                    context,
                    DateTime(
                      _selectedDay.year,
                      _selectedDay.month,
                      _selectedDay.day,
                      _selectedTime.hour,
                      _selectedTime.minute,
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _weekLabel(int weekday) =>
      const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][weekday - 1];

  String _timeLabel(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
