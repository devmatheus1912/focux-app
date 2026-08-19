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
  bool _videoBusy = false;

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
    if (_saving || _videoBusy) return;
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

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(widget.isDark);

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

    return PopScope(
      canPop: !_saving && !_videoBusy,
      child: TreinoHomeSheetSurface(
        isDark: widget.isDark,
        maxHeight: MediaQuery.sizeOf(context).height * 0.82,
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
            TreinoSheetChromeHeader(
              icon: Icons.edit_note_rounded,
              title: 'Editar prescrição',
              subtitle: widget.item.exercicio.nomeDisplay,
              isDark: widget.isDark,
            ),
            SizedBox(height: TokensStrip.s4),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    pair(
                      TreinoPrescriptionField(
                        label: 'Séries',
                        isDark: widget.isDark,
                        controller: _seriesCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                      ),
                      TreinoPrescriptionField(
                        label: 'Repetições',
                        isDark: widget.isDark,
                        controller: _repCtrl,
                        hint: '10-12',
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\-xX/ ]'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: TokensStrip.s4),
                    pair(
                      TreinoPrescriptionField(
                        label: 'Descanso (s)',
                        isDark: widget.isDark,
                        controller: _descansoCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                      TreinoPrescriptionField(
                        label: 'Carga (kg)',
                        isDark: widget.isDark,
                        controller: _cargaCtrl,
                        hint: 'Opcional',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+[.,]?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: TokensStrip.s4),
                    TreinoTipoSeriePicker(
                      value: _tipoSerie,
                      isDark: widget.isDark,
                      enabled: !_saving && !_videoBusy,
                      onChanged: (value) => setState(() => _tipoSerie = value),
                    ),
                    if (_tipoSerie == 'SUPERSET') ...[
                      SizedBox(height: TokensStrip.s4),
                      TreinoPrescriptionField(
                        label: 'Grupo superset',
                        isDark: widget.isDark,
                        controller: _supersetCtrl,
                        hint: 'Mesmo número = juntos',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                      ),
                    ],
                    if (_tipoSerie == 'DROPSET') ...[
                      SizedBox(height: TokensStrip.s2),
                      Text(
                        'Anote a queda de carga nas observações.',
                        style: FocuxHubTypography.bodyMuted(
                          color: dashboardReadableCaption(
                            context,
                            isDark: widget.isDark,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SizedBox(height: TokensStrip.s4),
                    TreinoPrescriptionField(
                      label: 'Observações',
                      isDark: widget.isDark,
                      controller: _obsCtrl,
                      hint: 'Cadência, pausa, execução…',
                      textInputAction: TextInputAction.done,
                      minLines: 1,
                      maxLines: 3,
                    ),
                    SizedBox(height: TokensStrip.s4),
                    TreinoPrescriptionVideoBlock(
                      treinoId: widget.treinoId,
                      exercicio: widget.item.exercicio,
                      isDark: widget.isDark,
                      busy: _saving,
                      onBusyChanged: (busy) {
                        if (mounted) setState(() => _videoBusy = busy);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: chrome.line.withValues(alpha: 0.8)),
            SizedBox(height: TokensStrip.s4),
            FxLiquidPrimaryButton(
              label: 'Salvar prescrição',
              loading: _saving,
              onPressed:
                  _saving || _videoBusy
                      ? null
                      : () {
                        HapticFeedback.mediumImpact();
                        _save();
                      },
            ),
          ],
        ),
      ),
    );
  }
}
