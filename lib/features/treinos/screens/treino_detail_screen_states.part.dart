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

  InputDecoration _decoration(String label, Color primary) {
    final radius = BorderRadius.circular(14);
    return InputDecoration(
      labelText: label,
      border: FxInputDeco.outlineBorder(borderRadius: radius),
      enabledBorder: FxInputDeco.outlineBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: primary.withValues(alpha: 0.22)),
      ),
      focusedBorder: FxInputDeco.outlineBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute =
        widget.isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: fxListCardDecoration(context, accent: primary),
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
                      color: mute.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Editar prescrição',
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.item.exercicio.nomeDisplay,
                  style: AppTypography.inter(
                    color: mute,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _seriesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Séries', primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _repCtrl,
                        decoration: _decoration('Repetições', primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _descansoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _decoration('Descanso (s)', primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cargaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _decoration('Carga (kg)', primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipoSerie,
                  decoration: _decoration('Tipo de série', primary),
                  items: const [
                    DropdownMenuItem(value: 'NORMAL', child: Text('Normal')),
                    DropdownMenuItem(
                      value: 'SUPERSET',
                      child: Text('Superset'),
                    ),
                    DropdownMenuItem(value: 'DROPSET', child: Text('Drop set')),
                  ],
                  onChanged:
                      _saving
                          ? null
                          : (value) {
                            if (value == null) return;
                            setState(() => _tipoSerie = value);
                          },
                ),
                if (_tipoSerie == 'SUPERSET') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _supersetCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _decoration('Grupo superset', primary),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _obsCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _decoration('Observações', primary),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: primary,
                  ),
                  child:
                      _saving
                          ? FxLoading(
                            size: 22,
                            strokeWidth: 2,
                            color: heroTealInk(),
                          )
                          : const Text('Salvar prescrição'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
