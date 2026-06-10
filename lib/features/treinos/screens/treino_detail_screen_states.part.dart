part of 'treino_detail_screen.dart';

class _DetailErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _DetailErrorState({
    required this.isDark,
    required this.primary,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(
                    alpha: isDark ? 0.16 : 0.09,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: EagleTokens.bad,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Falha ao carregar treino',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: mute,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Voltar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ink,
                      side: BorderSide(color: line),
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FxLiquidPrimaryButton(
                      label: 'Tentar novamente',
                      icon: Icons.refresh_rounded,
                      onPressed: onRetry,
                    ),
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

class _EmptyExercisesState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onAdd;

  const _EmptyExercisesState({
    required this.isDark,
    required this.primary,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: primary.withValues(alpha: isDark ? 0.12 : 0.08),
              ),
            ),
            child: Icon(Icons.fitness_center_rounded, color: primary, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'Nenhum exercício ainda',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione exercícios da biblioteca curada para montar este treino.',
            textAlign: TextAlign.center,
            style: AppTypography.inter(
              color: mute,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 260,
            child: FxLiquidPrimaryButton(
              label: 'Adicionar exercício',
              icon: Icons.add_rounded,
              onPressed: onAdd,
              expand: true,
            ),
          ),
        ],
      ),
    );
  }
}

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
                          ? const FxLoading(
                            size: 22,
                            strokeWidth: 2,
                            color: Colors.white,
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
