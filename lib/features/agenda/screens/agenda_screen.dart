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
import '../../../core/theme/app_typography.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';

part 'agenda_screen_widgets.part.dart';
part 'agenda_screen_novo.part.dart';

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
      if (mounted) {
        setState(() => _loading = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Color _statusColor(String s, bool isDark, Color primary) {
    if (s == 'PRESENTE' || s == 'CONCLUIDO') {
      return EagleTokens.semanticGood(isDark: isDark);
    }
    if (s == 'FALTA') return EagleTokens.semanticBad(isDark: isDark);
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

  /// Combina `Env.apiUrl` (https://host[/api]) com um path relativo (/api/...) sem
  /// duplicar segmentos. Aceita também URL já absoluta vinda do backend.
  String _resolveAbsoluteApiUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    var base = Env.apiUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    if (base.endsWith('/api') && path.startsWith('/api/')) {
      base = base.substring(0, base.length - 4);
    }
    return '$base$path';
  }

  Future<void> _copyIcalLink() async {
    try {
      final info =
          await AgendaRepository(ref.read(apiClientProvider)).icalToken();
      final fullUrl = _resolveAbsoluteApiUrl(info.url);
      await Clipboard.setData(ClipboardData(text: fullUrl));
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Link iCal copiado — cole no Google Calendar ou Apple Calendar.',
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro ao gerar link iCal: $e');
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
              FeedbackHelper.showSuccess(context, 'Agendamento excluído.');
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

    return FxShellScaffold(
      useMesh: true,
      extendBody: true,
      safeArea: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 16, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
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
                        Flexible(
                          child: Text(
                            'Agenda',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Exportar iCal',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          Icons.calendar_month_outlined,
                          color: mute,
                          size: 22,
                        ),
                        onPressed: _copyIcalLink,
                      ),
                      const ShellThemeToggle(size: 36),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
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
                                const SizedBox(width: 4),
                                Text(
                                  '${_weekStart.day}–${_weekStart.add(const Duration(days: 6)).day} ${monthNames[_weekStart.month]}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: ink,
                                  ),
                                ),
                                const SizedBox(width: 4),
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
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rCard,
                          ),
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
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          0,
                          16,
                          100,
                        ),
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
                                    borderRadius: BorderRadius.circular(
                                      TokensStrip.rCard,
                                    ),
                                    color: primary,
                                    boxShadow: [
                                      if (!isDark)
                                        BoxShadow(
                                          color: primary.withValues(
                                            alpha: 0.18,
                                          ),
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
                              borderRadius: BorderRadius.circular(
                                TokensStrip.rCard,
                              ),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: fxListCardDecoration(
                                  context,
                                  accent: sColor,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 52,
                                      child: Column(
                                        children: [
                                          Text(
                                            '${e.inicio.hour.toString().padLeft(2, '0')}:${e.inicio.minute.toString().padLeft(2, '0')}',
                                            style: AppTypography.mono(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: primary,
                                            ),
                                          ),
                                          Container(
                                            width: 2,
                                            height: 20,
                                            margin: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primary.withValues(
                                                alpha: 0.3,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(2),
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
                                                : primary.withValues(
                                                  alpha: 0.1,
                                                ),
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
