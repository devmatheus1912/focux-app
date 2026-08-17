part of 'agenda_screen.dart';

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
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.lineStrong;
    final enabled = _canSave && !_saving;

    return fxScreenA11yScope(
      label: 'Novo agendamento',
      child: FxShellScaffold(
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
                                () => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: FxLoading.sectionShimmer(
                                    context,
                                    height: 72,
                                    showHeader: false,
                                  ),
                                ),
                            error:
                                (e, _) => FxErrorState(
                                  chromeOnDark: chrome.isDark,
                                  primary: primary,
                                  message: friendlyError(
                                    e,
                                    fallback:
                                        'Não foi possível carregar alunos.',
                                  ),
                                  onRetry: () => ref.invalidate(alunosProvider),
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
              Icon(Icons.keyboard_arrow_down_rounded, color: chrome.mute),
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
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s5,
                      18,
                      20,
                      12,
                    ),
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
                              style: AppTypography.mono(
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
                              prefixIcon: Icon(
                                Icons.search,
                                size: 19,
                                color: chrome.mute,
                              ),
                              filled: true,
                              fillColor: chrome.cardFill,
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: chrome.lineStrong,
                                ),
                              ),
                              enabledBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: chrome.lineStrong,
                                ),
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
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s5,
                        0,
                        20,
                        28,
                      ),
                      itemCount: alunos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final aluno = alunos[index];
                        final selected = aluno.id == widget.selectedId;
                        return Semantics(
                          button: true,
                          selected: selected,
                          label:
                              'Aluno ${aluno.nome}${selected ? ', selecionado' : ''}',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                            if ((aluno.objetivo ?? '')
                                                .isNotEmpty)
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
                                    selected
                                        ? Colors.white
                                        : TokensStrip.textSecondary,
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
                          style: AppTypography.mono(
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
