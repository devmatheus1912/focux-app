import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../data/workout_builder_preset.dart';
import '../providers/treinos_provider.dart';

class AddExercicioToTreinoScreen extends ConsumerStatefulWidget {
  final int treinoId;
  const AddExercicioToTreinoScreen({super.key, required this.treinoId});

  @override
  ConsumerState<AddExercicioToTreinoScreen> createState() =>
      _AddExercicioToTreinoScreenState();
}

class _AddExercicioToTreinoScreenState
    extends ConsumerState<AddExercicioToTreinoScreen> {
  Exercicio? _selecionado;
  final _seriesCtrl = TextEditingController(text: '3');
  final _repCtrl = TextEditingController(text: '10-12');
  final _descansoCtrl = TextEditingController(text: '60');
  final _cargaCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();
  final _grupoSupersetCtrl = TextEditingController(text: '1');
  String _presetId = 'hypertrophy';
  String _tipoSerie = 'NORMAL';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _seriesCtrl.dispose();
    _repCtrl.dispose();
    _descansoCtrl.dispose();
    _cargaCtrl.dispose();
    _observacoesCtrl.dispose();
    _grupoSupersetCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String id) {
    final preset = workoutBuilderPresetById(id);
    setState(() {
      _presetId = id;
      _seriesCtrl.text = preset.series.toString();
      _repCtrl.text = preset.repeticoes;
      _descansoCtrl.text = preset.descansoSegundos.toString();
      _tipoSerie = preset.tipoSerie;
      _observacoesCtrl.text = preset.observacoes;
      if (preset.grupoSuperset != null) {
        _grupoSupersetCtrl.text = preset.grupoSuperset.toString();
      }
    });
  }

  Future<void> _submit() async {
    if (_selecionado == null) {
      setState(() { _error = 'Selecione um exercício.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(treinoRepositoryProvider).adicionarExercicio(
        widget.treinoId,
        _selecionado!.id,
        series: int.tryParse(_seriesCtrl.text) ?? 3,
        repeticoes: _repCtrl.text,
        descanso: int.tryParse(_descansoCtrl.text) ?? 60,
        cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
        observacoes: _observacoesCtrl.text,
        tipoSerie: _tipoSerie,
        grupoSuperset: _tipoSerie == 'SUPERSET'
            ? int.tryParse(_grupoSupersetCtrl.text)
            : null,
      );
      if (mounted) context.pop(true);
    } catch (e) {

      if (mounted) setState(() { _error = 'Erro ao adicionar exercício.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(exerciciosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVO ITEM',
                        style: TextStyle(fontSize: 12, color: mute, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adicionar Exercício',
                        style: TextStyle(fontSize: 28, color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mute),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: exerciciosAsync.when(
                loading: () => Center(child: CircularProgressIndicator(color: primary)),
                error: (e, _) => Center(child: Text('Erro: $e', style: TextStyle(color: EagleTokens.bad))),
                data: (exercicios) => SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Exercicio>(
                              value: _selecionado,
                              decoration: InputDecoration(
                                labelText: 'Exercício',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              items: exercicios.map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.nome, style: TextStyle(color: ink)),
                                  )).toList(),
                              onChanged: (v) => setState(() => _selecionado = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 56, // Match Dropdown height
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: primary),
                              tooltip: 'Criar novo exercício',
                              onPressed: () async {
                                final criado = await context.push<bool>('/exercicios/novo');
                                if (criado == true) {
                                  ref.invalidate(exerciciosProvider);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_selecionado != null) ...[
                        const SizedBox(height: 14),
                        _SelectedExerciseTrustPanel(
                          exercicio: _selecionado!,
                          primary: primary,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 20),
                      _PresetSelector(
                        selectedId: _presetId,
                        primary: primary,
                        isDark: isDark,
                        onSelected: _applyPreset,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _seriesCtrl,
                              decoration: InputDecoration(
                                labelText: 'Séries',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: ink),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _repCtrl,
                              decoration: InputDecoration(
                                labelText: 'Repetições',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              style: TextStyle(color: ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _descansoCtrl,
                              decoration: InputDecoration(
                                labelText: 'Descanso (segundos)',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: ink),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cargaCtrl,
                              decoration: InputDecoration(
                                labelText: 'Carga alvo (kg)',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(color: ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SerieTypeSelector(
                        value: _tipoSerie,
                        primary: primary,
                        isDark: isDark,
                        onChanged: (value) => setState(() => _tipoSerie = value),
                      ),
                      if (_tipoSerie == 'SUPERSET') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _grupoSupersetCtrl,
                          decoration: InputDecoration(
                            labelText: 'Grupo do superset',
                            helperText: 'Use o mesmo numero em exercicios que devem ficar juntos.',
                            filled: true,
                            fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: ink),
                        ),
                      ],
                      if (_tipoSerie == 'DROPSET') ...[
                        const SizedBox(height: 12),
                        _ModeHint(
                          icon: Icons.trending_down_rounded,
                          text: 'Drop set: registre reducoes de carga nas observacoes ou no acompanhamento por serie.',
                          color: EagleTokens.warn,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _observacoesCtrl,
                        decoration: InputDecoration(
                          labelText: 'Observacoes de execucao',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
                        ),
                        minLines: 2,
                        maxLines: 4,
                        style: TextStyle(color: ink),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: EagleTokens.bad.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!, style: const TextStyle(color: EagleTokens.bad, fontSize: 13))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: primary.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                              : const Text('Adicionar ao Treino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  final String selectedId;
  final Color primary;
  final bool isDark;
  final ValueChanged<String> onSelected;

  const _PresetSelector({
    required this.selectedId,
    required this.primary,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = workoutBuilderPresetById(selectedId);
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Presets de prescricao',
                style: TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: workoutBuilderPresets.map((preset) {
              final isSelected = preset.id == selectedId;
              return ChoiceChip(
                selected: isSelected,
                label: Text(preset.label),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : primary,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: primary,
                backgroundColor: primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: primary.withValues(alpha: isSelected ? 0 : 0.24),
                ),
                onSelected: (_) => onSelected(preset.id),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text(
            selected.summary,
            style: TextStyle(
              color: mute,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedExerciseTrustPanel extends StatelessWidget {
  final Exercicio exercicio;
  final Color primary;
  final bool isDark;

  const _SelectedExerciseTrustPanel({
    required this.exercicio,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final color = _trustColor(exercicio, primary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_trustIcon(exercicio), color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercicio.mediaTrustLabel,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  exercicio.mediaTrustDescription,
                  style: TextStyle(
                    color: mute,
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _trustColor(Exercicio exercicio, Color primary) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' => exercicio.isPersonalUpload ? primary : EagleTokens.good,
    'NO_VIDEO' => EagleTokens.bad,
    _ => EagleTokens.warn,
  };
}

IconData _trustIcon(Exercicio exercicio) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' => exercicio.isPersonalUpload
        ? Icons.workspace_premium_rounded
        : Icons.verified_rounded,
    'NO_VIDEO' => Icons.videocam_off_outlined,
    _ => Icons.rate_review_outlined,
  };
}

class _SerieTypeSelector extends StatelessWidget {
  final String value;
  final Color primary;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _SerieTypeSelector({
    required this.value,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final options = const [
      ('NORMAL', Icons.fitness_center_rounded, 'Normal'),
      ('SUPERSET', Icons.link_rounded, 'Superset'),
      ('DROPSET', Icons.trending_down_rounded, 'Drop set'),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tipo de serie',
            style: TextStyle(color: mute, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final selected = value == option.$1;
              return ChoiceChip(
                selected: selected,
                avatar: Icon(
                  option.$2,
                  size: 16,
                  color: selected ? Colors.white : primary,
                ),
                label: Text(option.$3),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : primary,
                  fontWeight: FontWeight.w800,
                ),
                selectedColor: primary,
                backgroundColor: primary.withValues(alpha: 0.08),
                side: BorderSide(color: primary.withValues(alpha: selected ? 0 : 0.25)),
                onSelected: (_) => onChanged(option.$1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModeHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isDark;

  const _ModeHint({
    required this.icon,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
