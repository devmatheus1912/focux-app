part of 'agenda_screen.dart';

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

  @override
  void initState() {
    super.initState();
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
    final aluno = await showFxHomeSheet<Aluno>(
      context,
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
    final enabled = _canSave && !_saving;

    return fxScreenA11yScope(
      label: 'Novo agendamento',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Novo agendamento',
          subtitle: 'AGENDA',
          onBack: () => safePopOrGo(context, '/agenda'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s3),
              child: Center(
                child: Semantics(
                  button: true,
                  enabled: enabled,
                  label:
                      _saving
                          ? 'Agendando atendimento'
                          : agendaNovoSalvarTooltip(),
                  child: ShellHeaderIconButton(
                    icon: 'circle-check',
                    tooltip: agendaNovoSalvarTooltip(),
                    onTap: _saving ? () {} : _salvar,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            8,
            FxSettingsLayout.pageInset,
            32,
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
                    final alunos = alunosAsync.valueOrNull;
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
            const SizedBox(height: TokensStrip.s3),
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  fxIcon: 'circle-check',
                  label: agendaNovoTileLabel(),
                  value: _saving ? 'Agendando…' : 'Confirmar',
                  showDivider: false,
                  onTap: _saving ? () {} : _salvar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
