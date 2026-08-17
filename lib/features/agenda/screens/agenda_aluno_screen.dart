import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/agenda_repository.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/theme/tokens_strip.dart';

class AgendaAlunoScreen extends ConsumerStatefulWidget {
  const AgendaAlunoScreen({super.key});
  @override
  ConsumerState<AgendaAlunoScreen> createState() => _AgendaAlunoScreenState();
}

class _AgendaAlunoScreenState extends ConsumerState<AgendaAlunoScreen> {
  List<Agendamento> _ags = [];
  bool _loading = true;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final r =
          await AgendaRepository(
            ref.read(apiClientProvider),
          ).meusAgendamentos();
      if (mounted) {
        setState(() {
          _ags = r;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = e;
        });
      }
    }
  }

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
          await AgendaRepository(ref.read(apiClientProvider)).icalTokenAluno();
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
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _confirmar(Agendamento ag) async {
    try {
      await AgendaRepository(
        ref.read(apiClientProvider),
      ).confirmarPresenca(ag.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Presença confirmada!');
        _load();
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Minha Agenda',
      child: FxShellScaffold(
        useMesh: true,
        extendBody: true,
        appBar: FxShellAppBar(
          title: 'Minha Agenda',
          subtitle: 'Seus próximos compromissos',
          actions: [
            IconButton(
              tooltip: 'Exportar iCal',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: _copyIcalLink,
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: SkeletonList(count: 4),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: friendlyError(_erro!),
                  onRetry: _load,
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child:
                      _ags.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 72),
                              FxEmptyState(
                                icon: 'calendar',
                                title: 'Nenhum agendamento',
                                subtitle:
                                    'Quando seu personal marcar uma sessão, ela aparece aqui.',
                              ),
                            ],
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            itemCount: _ags.length,
                            itemBuilder:
                                (_, i) =>
                                    _AgCard(ag: _ags[i], onConfirmar: _confirmar),
                          ),
                ),
      ),
    );
  }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: fxListCardDecoration(context, accent: cor),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ag.titulo ?? 'Sessão de treino',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusChip(status: ag.status, cor: cor),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: TokensStrip.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}',
                    style: const TextStyle(
                      color: TokensStrip.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: TokensStrip.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_hm(inicio)} – ${_hm(fim)}',
                    style: const TextStyle(
                      color: TokensStrip.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (ag.status == 'AGENDADO') ...[
                const SizedBox(height: 12),
                FxLiquidPrimaryButton(
                  label: 'Confirmar presença',
                  onPressed: () => onConfirmar(ag),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Color _statusColor(BuildContext context, String s) {
    switch (s) {
      case 'AGENDADO':
        return Theme.of(context).colorScheme.primary;
      case 'CONFIRMADO':
        return EagleTokens.good;
      case 'CONCLUIDO':
        return Theme.of(context).colorScheme.primary;
      case 'CANCELADO':
        return TokensStrip.textSecondary;
      default:
        return TokensStrip.textSecondary;
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
    label: Text(
      _label[status] ?? status,
      style: TextStyle(color: cor, fontSize: 11),
    ),
    backgroundColor: cor.withValues(alpha: 0.12),
    padding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
  );
}
