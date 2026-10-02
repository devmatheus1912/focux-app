import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/offline_queued_ack.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/queued_offline_exit.dart';
import '../../alunos/data/aluno_contact_utils.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/agenda_novo_args.dart';
import '../data/agenda_repository.dart';
import '../providers/agenda_provider.dart';
import '../utils/agenda_month.dart';
import '../utils/agenda_schedule.dart';
import '../utils/agenda_slots.dart';
import '../widgets/agenda_form_sheets.dart';
import '../widgets/agenda_help_sheet.dart';
import '../widgets/agenda_slot_picker_sheet.dart';

class NovoAgendamentoScreen extends ConsumerStatefulWidget {
  const NovoAgendamentoScreen({super.key, this.seedDay, this.args});

  final DateTime? seedDay;
  final AgendaNovoArgs? args;

  @override
  ConsumerState<NovoAgendamentoScreen> createState() =>
      _NovoAgendamentoScreenState();
}

class _NovoAgendamentoScreenState extends ConsumerState<NovoAgendamentoScreen> {
  static var _ultimaDuracao = agendaDuracaoPadraoMin;

  final _titulo = TextEditingController();
  final _meses = <DateTime, List<Agendamento>>{};
  late final AgendaNovoArgs _args;
  int? _alunoId;
  Aluno? _alunoSelecionado;
  DateTime? _inicio;
  late int _duracao;
  bool _saving = false;

  DateTime? get _fim => _inicio?.add(Duration(minutes: _duracao));

  bool get _canSave => _alunoId != null && _inicio != null;

  bool get _dirty =>
      _alunoId != null || _inicio != null || _titulo.text.trim().isNotEmpty;

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: agendaNovoDiscardTitle(),
        message: agendaNovoDiscardMessage(),
        confirmLabel: 'Descartar',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/agenda');
  }

  @override
  void initState() {
    super.initState();
    _titulo.addListener(() {
      if (mounted) setState(() {});
    });
    _args = widget.args ?? AgendaNovoArgs.fromSeed(widget.seedDay);
    _duracao = _args.duracaoMin ?? _ultimaDuracao;
    final ags = _args.agendamentos;
    if (ags != null) _meses[agendaMonthOf(_args.day)] = ags;
    final inicio = _args.inicio;
    if (inicio != null &&
        agendaSlotFitsDay(inicio, _duracao) &&
        agendaSlotLocalError(inicio, _duracao, ags ?? const []) == null) {
      _inicio = inicio;
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<List<Agendamento>> _loadMonth(DateTime month) async {
    final cached = _meses[month];
    if (cached != null) return cached;
    final items = await ref
        .read(agendaRepositoryProvider)
        .listarMes(month.year, month.month);
    _meses[month] = items;
    return items;
  }

  Future<void> _pickHorario({String? aviso}) async {
    final day = _inicio ?? _args.day;
    final pick = await showAgendaSlotPicker(
      context,
      title: 'Início do atendimento',
      day: day,
      inicio: _inicio ?? _args.inicio,
      duracaoMin: _duracao,
      agendamentos: _meses[agendaMonthOf(day)],
      loadMonth: _loadMonth,
      aviso: aviso,
    );
    if (pick == null || !mounted) return;
    setState(() {
      _inicio = pick.inicio;
      _duracao = pick.duracaoMin;
      _ultimaDuracao = pick.duracaoMin;
    });
  }

  /// Horário recusado (local ou servidor): reabre a grade com o motivo. Do
  /// servidor, o mês é buscado de novo para mostrar quem ocupou.
  Future<void> _repick(String message, {bool refresh = false}) async {
    final inicio = _inicio;
    if (refresh) {
      invalidateAgendaCaches(ref);
      if (inicio != null) _meses.remove(agendaMonthOf(inicio));
    }
    await _pickHorario(aviso: message);
  }

  Future<void> _showAlunoSheet(List<Aluno> alunos) async {
    final aluno = await showFxHomeSheet<Aluno>(
      context,
      builder: (_) => AgendaAlunoSheet(alunos: alunos, selectedId: _alunoId),
    );
    if (aluno == null || !mounted) return;
    setState(() {
      _alunoId = aluno.id;
      _alunoSelecionado = aluno;
    });
  }

  Future<void> _salvar() async {
    FxKeyboardDismissScope.dismiss();
    if (!_canSave) {
      FeedbackHelper.showError(
        context,
        'Selecione aluno e horário para agendar.',
      );
      return;
    }
    final alunoId = _alunoId;
    if (alunoId == null) {
      FeedbackHelper.showWarn(context, 'Selecione um aluno.');
      return;
    }
    final inicio = _inicio!;
    final fim = _fim!;
    final localError = agendaSlotLocalError(
      inicio,
      _duracao,
      _meses[agendaMonthOf(inicio)] ?? const [],
    );
    if (localError != null) {
      await _repick(localError);
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: agendaNovoConfirmTitle(),
      message: agendaNovoConfirmMessage(
        alunoNome: _alunoSelecionado?.nome ?? '',
        inicio: inicio,
        fim: fim,
      ),
      confirmLabel: agendaNovoTileLabel(),
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(agendaRepositoryProvider)
          .criar(
            alunoId,
            inicio,
            fim,
            _titulo.text.isEmpty ? null : _titulo.text,
          );
      invalidateAgendaCaches(ref);
      AnalyticsService.instance.track(ProductEvents.agendaCreated);
      if (mounted) safePopOrGo(context, '/agenda');
    } on OfflineQueuedException {
      if (mounted) leaveWithQueuedNotice(context, '/agenda');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final slotError = agendaSlotErrorMessage(e);
      if (slotError != null) {
        await _repick(slotError, refresh: true);
      } else {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao agendar. Tente novamente.'),
        );
      }
      return;
    }
    if (mounted) setState(() => _saving = false);
  }

  String _horarioLabel() {
    final inicio = _inicio;
    final fim = _fim;
    if (inicio == null || fim == null) return 'Selecionar';
    return '${agendaDayShortLabel(inicio)} · ${agendaHm(inicio)}–${agendaHm(fim)}';
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);

    return fxScreenA11yScope(
      label: 'Novo agendamento',
      child: FxFormPopGuard(
        dirty: _dirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Novo agendamento',
            subtitle: 'AGENDA',
            leadingWidth: 92,
            leading: TextButton(
              onPressed: _cancel,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Cancelar'),
            ),
          ),
          bottomNavigationBar: FxFormStickyBar(
            child: FxLiquidPrimaryButton(
              label: agendaNovoTileLabel(),
              loading: _saving,
              loadingLabel: 'Agendando…',
              onPressed: _saving ? null : _salvar,
            ),
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              24,
            ),
            children: [
              alunosAsync.maybeWhen(
                error:
                    (e, _) => Padding(
                      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                      child: FxErrorState(
                        chromeOnDark: ShellChrome.of(context).isDark,
                        primary: Theme.of(context).colorScheme.primary,
                        message: friendlyError(
                          e,
                          fallback: 'Não foi possível carregar alunos.',
                        ),
                        onRetry: () => ref.invalidate(alunosProvider),
                      ),
                    ),
                orElse: () => const SizedBox.shrink(),
              ),
              FxSettingsGroup(
                header: 'Atendimento',
                children: [
                  FxSettingsTile(
                    fxIcon: 'users',
                    label: 'Aluno',
                    subtitle:
                        _alunoSelecionado == null
                            ? 'Selecione quem será atendido'
                            : maskEmailForList(_alunoSelecionado!.email),
                    value:
                        alunosAsync.isLoading
                            ? 'Carregando…'
                            : (_alunoSelecionado?.nome ?? 'Selecionar'),
                    picker: true,
                    onTap: () {
                      final alunos = alunosAsync.value;
                      if (alunos == null) {
                        ref.invalidate(alunosProvider);
                        return;
                      }
                      _showAlunoSheet(alunos);
                    },
                  ),
                  AlunoInsetFormField(
                    controller: _titulo,
                    label: 'Título (opcional)',
                    icon: Icons.title_outlined,
                    hint: 'Avaliação, retorno, foco da sessão…',
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(agendaTituloMax),
                    ],
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
              FxSettingsGroup(
                header: 'Horário',
                helpTooltip: 'Como usar a agenda',
                onHelpTap: () => showAgendaHelpSheet(context),
                children: [
                  FxSettingsTile(
                    fxIcon: 'calendar',
                    label: 'Quando',
                    subtitle:
                        _inicio == null
                            ? 'Dia, horário e duração'
                            : agendaDuracaoLabel(_duracao),
                    value: _horarioLabel(),
                    picker: true,
                    showDivider: false,
                    onTap: _pickHorario,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
