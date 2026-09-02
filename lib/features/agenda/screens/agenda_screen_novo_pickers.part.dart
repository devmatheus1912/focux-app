part of 'agenda_screen.dart';

class _AgendaAlunoAvatar extends StatelessWidget {
  final Aluno? aluno;

  const _AgendaAlunoAvatar({required this.aluno});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final foto = aluno?.fotoUrl;
    final hasPhoto = foto != null && foto.isNotEmpty;
    final initials = _initials(aluno?.nome ?? '');
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 42,
        height: 42,
        color: BrandPalette.soft(primary, dark: chrome.isDark),
        child:
            hasPhoto
                ? Image.network(
                  foto,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(primary, initials),
                )
                : _fallback(primary, initials),
      ),
    );
  }

  Widget _fallback(Color primary, String initials) {
    if (initials == '?') {
      return Icon(Icons.person_outline_rounded, color: primary, size: 20);
    }
    return Center(
      child: Text(
        initials,
        style: FocuxHubTypography.cardTitle(color: primary),
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
      child: FxHomeSheetSurface(
        isDark: chrome.isDark,
        expand: true,
        maxHeight:
            MediaQuery.sizeOf(context).height *
            FxHomeSheetChrome.expandHeightFactor,
        child: Column(
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: 'Selecionar aluno',
              subtitle: '${alunos.length} de ${widget.alunos.length}',
              leading: Icon(
                Icons.person_outline_rounded,
                color: primary,
                size: 18,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
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
                  fillColor:
                      chrome.isDark
                          ? EagleTokens.darkCardHi
                          : TokensStrip.pageBg,
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
            SizedBox(height: TokensStrip.s3),
            Expanded(
              child:
                  alunos.isEmpty
                      ? FxEmptyState(
                        icon: 'search',
                        title:
                            query.isEmpty
                                ? 'Nenhum aluno'
                                : 'Nada com essa busca',
                        subtitle:
                            query.isEmpty
                                ? 'Cadastre um aluno para marcar o atendimento.'
                                : 'Tente outro nome, e-mail ou objetivo.',
                      )
                      : ListView.separated(
                        padding: EdgeInsets.zero,
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
                                    color:
                                        selected ? primary : chrome.lineStrong,
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
                                            style: FocuxHubTypography.cardTitle(
                                              color: chrome.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            [
                                              if ((aluno.objetivo ?? '')
                                                  .isNotEmpty)
                                                aluno.objetivo!,
                                              maskEmailForList(aluno.email),
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FocuxHubTypography.bodyMuted(
                                              color: chrome.mute,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.chevron_right_rounded,
                                      color:
                                          selected ? primary : chrome.mute,
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
      child: FxHomeSheetSurface(
        isDark: chrome.isDark,
        expand: true,
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: widget.title,
              subtitle: 'Escolha o dia e o horário.',
              leading: Icon(Icons.schedule_outlined, color: primary, size: 18),
            ),
            SizedBox(height: TokensStrip.s3),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final day = days[index];
                  return AgendaDayChip(
                    weekdayLabel: agendaWeekdayShort(day.weekday),
                    dayNumber: day.day,
                    selected: agendaSameDay(day, _selectedDay),
                    isToday: agendaSameDay(day, DateTime.now()),
                    onTap: () => setState(() => _selectedDay = day),
                  );
                },
              ),
            ),
            SizedBox(height: TokensStrip.s4),
            Expanded(
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
                      child: Ink(
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? BrandPalette.soft(
                                    primary,
                                    dark: chrome.isDark,
                                  )
                                  : chrome.cardFill,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                selected
                                    ? primary.withValues(alpha: 0.42)
                                    : chrome.lineStrong,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _timeLabel(slot),
                            style: FocuxHubTypography.cardTitle(
                              color: selected ? primary : chrome.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Divider(height: 1, color: chrome.line.withValues(alpha: 0.8)),
            SizedBox(height: TokensStrip.s3),
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  fxIcon: 'circle-check',
                  label: agendaHorarioConfirmLabel(),
                  value: _timeLabel(_selectedTime),
                  showDivider: false,
                  onTap: () {
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
