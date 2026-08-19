part of 'treino_detail_screen.dart';

class _EditPrescriptionSheet extends StatefulWidget {
  const _EditPrescriptionSheet({
    required this.treinoId,
    required this.item,
    required this.isDark,
    required this.repo,
  });

  final int treinoId;
  final TreinoExercicioItem item;
  final bool isDark;
  final TreinoRepository repo;

  @override
  State<_EditPrescriptionSheet> createState() => _EditPrescriptionSheetState();
}

class _EditPrescriptionSheetState extends State<_EditPrescriptionSheet> {
  late final TextEditingController _seriesCtrl;
  late final TextEditingController _repCtrl;
  late final TextEditingController _descansoCtrl;
  late final TextEditingController _cargaCtrl;
  late final TextEditingController _obsCtrl;
  late final TextEditingController _supersetCtrl;
  late String _tipoSerie;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _seriesCtrl = TextEditingController(text: '${item.series}');
    _repCtrl = TextEditingController(text: item.repeticoes);
    _descansoCtrl = TextEditingController(
      text: '${item.descansoSegundos ?? 60}',
    );
    _cargaCtrl = TextEditingController(
      text:
          item.cargaKg != null && item.cargaKg! > 0
              ? item.cargaKg!.toString()
              : '',
    );
    _obsCtrl = TextEditingController(text: item.observacoes ?? '');
    _supersetCtrl = TextEditingController(text: '${item.grupoSuperset ?? 1}');
    _tipoSerie = item.tipoSerie;
  }

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repCtrl.dispose();
    _descansoCtrl.dispose();
    _cargaCtrl.dispose();
    _obsCtrl.dispose();
    _supersetCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repo.atualizarExercicioPrescricao(
        widget.treinoId,
        widget.item.id,
        series: int.tryParse(_seriesCtrl.text) ?? widget.item.series,
        repeticoes: _repCtrl.text.trim(),
        descansoSegundos: int.tryParse(_descansoCtrl.text) ?? 60,
        cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
        observacoes: _obsCtrl.text,
        tipoSerie: _tipoSerie,
        grupoSuperset:
            _tipoSerie == 'SUPERSET' ? int.tryParse(_supersetCtrl.text) : null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    String? hint,
  }) {
    return FxInputDeco.build(
      context,
      label,
      hint: hint,
    ).copyWith(floatingLabelBehavior: FloatingLabelBehavior.always);
  }

  Widget _tipoSerieChips({
    required Color primary,
    required Color mute,
    required bool isDark,
  }) {
    const options = <(String, String)>[
      ('NORMAL', 'Normal'),
      ('SUPERSET', 'Superset'),
      ('DROPSET', 'Drop set'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de série',
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: TokensStrip.s2),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            for (final option in options)
              Semantics(
                button: true,
                selected: _tipoSerie == option.$1,
                label: option.$2,
                child: ChoiceChip(
                  selected: _tipoSerie == option.$1,
                  showCheckmark: false,
                  label: Text(option.$2),
                  labelStyle: FocuxHubTypography.cardTitle(
                    color: _tipoSerie == option.$1 ? Colors.white : primary,
                  ),
                  selectedColor: primary,
                  backgroundColor: BrandPalette.soft(primary, dark: isDark),
                  side: BorderSide(
                    color: primary.withValues(
                      alpha: _tipoSerie == option.$1 ? 0 : 0.22,
                    ),
                  ),
                  onSelected:
                      _saving
                          ? null
                          : (_) => setState(() => _tipoSerie = option.$1),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(widget.isDark);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    Widget pair(Widget left, Widget right) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          SizedBox(width: TokensStrip.s3),
          Expanded(child: right),
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 12 + bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: chrome.bottomSheet(radius: 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: chrome.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: TokensStrip.s4),
                _TreinoSheetChromeHeader(
                  icon: Icons.edit_note_rounded,
                  title: 'Editar prescrição',
                  subtitle: widget.item.exercicio.nomeDisplay,
                  isDark: widget.isDark,
                ),
                SizedBox(height: TokensStrip.s4),
                pair(
                  TextField(
                    controller: _seriesCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: FocuxHubTypography.body(color: chrome.ink),
                    decoration: _decoration(context, label: 'Séries'),
                  ),
                  TextField(
                    controller: _repCtrl,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\-xX/ ]')),
                    ],
                    style: FocuxHubTypography.body(color: chrome.ink),
                    decoration: _decoration(
                      context,
                      label: 'Repetições',
                      hint: '10-12',
                    ),
                  ),
                ),
                SizedBox(height: TokensStrip.s3),
                pair(
                  TextField(
                    controller: _descansoCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    style: FocuxHubTypography.body(color: chrome.ink),
                    decoration: _decoration(context, label: 'Descanso (s)'),
                  ),
                  TextField(
                    controller: _cargaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+[.,]?\d{0,2}'),
                      ),
                    ],
                    style: FocuxHubTypography.body(color: chrome.ink),
                    decoration: _decoration(
                      context,
                      label: 'Carga (kg)',
                      hint: 'Opcional',
                    ),
                  ),
                ),
                SizedBox(height: TokensStrip.s4),
                _tipoSerieChips(
                  primary: primary,
                  mute: chrome.mute,
                  isDark: widget.isDark,
                ),
                if (_tipoSerie == 'SUPERSET') ...[
                  SizedBox(height: TokensStrip.s3),
                  TextField(
                    controller: _supersetCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    style: FocuxHubTypography.body(color: chrome.ink),
                    decoration: _decoration(
                      context,
                      label: 'Grupo superset',
                      hint: 'Mesmo número = juntos',
                    ),
                  ),
                ],
                if (_tipoSerie == 'DROPSET') ...[
                  SizedBox(height: TokensStrip.s2),
                  Text(
                    'Anote a queda de carga nas observações.',
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                SizedBox(height: TokensStrip.s3),
                TextField(
                  controller: _obsCtrl,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  style: FocuxHubTypography.body(color: chrome.ink),
                  decoration: _decoration(
                    context,
                    label: 'Observações',
                    hint: 'Cadência, pausa, execução…',
                  ),
                ),
                SizedBox(height: TokensStrip.s4),
                FilledButton(
                  onPressed:
                      _saving
                          ? null
                          : () {
                            HapticFeedback.mediumImpact();
                            _save();
                          },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      TreinosLayout.touchTarget,
                    ),
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child:
                      _saving
                          ? const FxLoading(
                            size: 22,
                            strokeWidth: 2,
                            color: Colors.white,
                          )
                          : const Text(
                            'Salvar prescrição',
                            style: TextStyle(fontWeight: FontWeight.w800),
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
