import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
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
import '../../alunos/data/aluno_contact_utils.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../providers/agenda_provider.dart';
import '../utils/agenda_schedule.dart';
import '../widgets/agenda_form_sheets.dart';
import '../widgets/agenda_help_sheet.dart';

class NovoAgendamentoScreen extends ConsumerStatefulWidget {
  const NovoAgendamentoScreen({super.key, this.seedDay});

  final DateTime? seedDay;

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

  bool get _dirty =>
      _alunoId != null ||
      _inicio != null ||
      _fim != null ||
      _titulo.text.trim().isNotEmpty;

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
    final seed = widget.seedDay;
    if (seed != null && (seed.hour != 0 || seed.minute != 0)) {
      _inicio = seed;
      _fim = seed.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isInicio) async {
    final seed = widget.seedDay ?? DateTime.now();
    final base =
        isInicio
            ? (_inicio ?? agendaDefaultSlot(seed))
            : (_fim ??
                (_inicio ?? agendaDefaultSlot(seed)).add(
                  const Duration(hours: 1),
                ));
    final dt = await showFxHomeSheet<DateTime>(
      context,
      builder:
          (_) => AgendaDateTimeSheet(
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
        'Selecione aluno, início e fim para agendar.',
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
      FeedbackHelper.showWarn(context, 'Fim deve ser após início.');
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
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao agendar. Tente novamente.'),
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
              helpTooltip: 'Como o fim é sugerido',
              onHelpTap: () => showAgendaHelpSheet(context),
              children: [
                FxSettingsTile(
                  fxIcon: 'calendar',
                  label: 'Início',
                  value: _fmtDt(_inicio),
                  picker: true,
                  onTap: () => _pickDateTime(true),
                ),
                FxSettingsTile(
                  fxIcon: 'calendar',
                  label: 'Fim',
                  value: _fmtDt(_fim),
                  picker: true,
                  showDivider: false,
                  onTap: () => _pickDateTime(false),
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
