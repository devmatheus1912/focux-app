import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/data/aluno_repository.dart';
import '../constants/treinos_layout.dart';
import '../utils/treino_atribuicao_prazo.dart';
import 'treino_home_sheet.dart';

/// Resultado do sheet de escolher aluno (+ prazo soft opcional).
class TreinoAtribuicaoResult {
  const TreinoAtribuicaoResult({required this.alunoId, this.dataFim});

  final int alunoId;
  final DateTime? dataFim;
}

/// Sheet único de atribuição — substitui as duas cópias privadas legadas.
class TreinoAssignSheet extends StatefulWidget {
  const TreinoAssignSheet({
    super.key,
    required this.alunos,
    required this.isDark,
    this.includePrazo = false,
    this.title = 'Atribuir treino',
    this.subtitleWhenEmpty = 'Cadastre um aluno antes.',
    this.subtitleWhenReady = 'Escolha quem recebe este plano.',
    this.confirmLabel = 'Atribuir',
  });

  final List<Aluno> alunos;
  final bool isDark;
  final bool includePrazo;
  final String title;
  final String subtitleWhenEmpty;
  final String subtitleWhenReady;
  final String confirmLabel;

  @override
  State<TreinoAssignSheet> createState() => _TreinoAssignSheetState();
}

class _TreinoAssignSheetState extends State<TreinoAssignSheet> {
  int? selectedAlunoId;
  _PrazoPreset _prazo = _PrazoPreset.none;
  DateTime? _customDate;

  @override
  void initState() {
    super.initState();
    selectedAlunoId = widget.alunos.isEmpty ? null : widget.alunos.first.id;
  }

  DateTime? get _resolvedPrazo {
    if (!widget.includePrazo) return null;
    final today = TreinoAtribuicaoPrazo.dateOnly(DateTime.now());
    return switch (_prazo) {
      _PrazoPreset.none => null,
      _PrazoPreset.d7 => today.add(const Duration(days: 7)),
      _PrazoPreset.d14 => today.add(const Duration(days: 14)),
      _PrazoPreset.d30 => today.add(const Duration(days: 30)),
      _PrazoPreset.custom => _customDate,
    };
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initial = _customDate ?? now.add(const Duration(days: 14));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Prazo do treino',
      cancelText: 'Cancelar',
      confirmText: 'Ok',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _prazo = _PrazoPreset.custom;
      _customDate = TreinoAtribuicaoPrazo.dateOnly(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final mute = fxScreenMute(context);

    return TreinoHomeSheetSurface(
      isDark: isDark,
      maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: widget.title,
            subtitle:
                widget.alunos.isEmpty
                    ? widget.subtitleWhenEmpty
                    : widget.subtitleWhenReady,
            leading: Icon(
              Icons.person_add_alt_1_rounded,
              color: soft,
              size: FxSettingsLayout.iconSize,
            ),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          if (widget.alunos.isEmpty)
            FxSettingsGroup(
              accent: primary,
              caption: 'Cadastre um aluno antes de atribuir este treino.',
              children: [
                FxSettingsTile(
                  icon: Icons.person_outline_rounded,
                  accent: soft,
                  label: 'Nenhum aluno cadastrado',
                  value: '',
                  showDivider: false,
                ),
              ],
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.includePrazo ? 220 : 280,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FxSettingsGroup(
                  accent: primary,
                  edgeToEdgeRows: true,
                  children: FxInsetPickerOption.list(
                    accent: soft,
                    items: [
                      for (var i = 0; i < widget.alunos.length; i++)
                        FxInsetPickerOptionSpec(
                          label: widget.alunos[i].nome,
                          subtitle:
                              widget.alunos[i].objetivo?.trim().isNotEmpty ==
                                      true
                                  ? widget.alunos[i].objetivo!.trim()
                                  : 'Objetivo não definido',
                          icon: Icons.person_outline_rounded,
                          selected: selectedAlunoId == widget.alunos[i].id,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(
                              () => selectedAlunoId = widget.alunos[i].id,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.includePrazo && widget.alunos.isNotEmpty) ...[
            const SizedBox(height: FxSettingsLayout.groupGap),
            Text(
              'Prazo (opcional)',
              style: FxSettingsLayout.sectionHeader(color: mute),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _PrazoPreset.values)
                  if (preset != _PrazoPreset.custom)
                    _PrazoChip(
                      label: preset.label,
                      selected: _prazo == preset,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _prazo = preset;
                          _customDate = null;
                        });
                      },
                    ),
                _PrazoChip(
                  label:
                      _customDate == null
                          ? 'Data…'
                          : TreinoAtribuicaoPrazo.chipLabel(_customDate)!
                              .replaceFirst('Até ', ''),
                  selected: _prazo == _PrazoPreset.custom,
                  onTap: _pickCustomDate,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Só orientação — o aluno ainda pode treinar depois do prazo.',
              style: FxSettingsLayout.subhead(color: mute),
            ),
          ],
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxLiquidPrimaryButton(
            label: widget.confirmLabel,
            onPressed:
                selectedAlunoId == null
                    ? null
                    : () => Navigator.pop(
                      context,
                      TreinoAtribuicaoResult(
                        alunoId: selectedAlunoId!,
                        dataFim: _resolvedPrazo,
                      ),
                    ),
          ),
          const SizedBox(height: FxSettingsLayout.footerAfterGroup),
          Center(
            child: Semantics(
              button: true,
              label: 'Cancelar',
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: mute,
                  minimumSize: const Size(
                    TreinosLayout.touchTarget,
                    TreinosLayout.touchTarget,
                  ),
                  textStyle: FxSettingsLayout.footer(color: mute),
                ),
                child: const Text('Cancelar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _PrazoPreset { none, d7, d14, d30, custom }

extension on _PrazoPreset {
  String get label => switch (this) {
    _PrazoPreset.none => 'Sem prazo',
    _PrazoPreset.d7 => '7 dias',
    _PrazoPreset.d14 => '14 dias',
    _PrazoPreset.d30 => '30 dias',
    _PrazoPreset.custom => 'Data…',
  };
}

class _PrazoChip extends StatelessWidget {
  const _PrazoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected
                    ? BrandPalette.soft(primary, dark: isDark)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? primary.withValues(alpha: 0.35)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color:
                  selected
                      ? primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
