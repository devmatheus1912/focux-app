import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../utils/prescricao_atalhos.dart';
import 'prescription_editor_copy.dart';

/// Folhas do "Outro" da prescrição. As válidas e os grupos de série
/// (aquecimento, ajuste, back-off) usam as mesmas: nada para aprender duas vezes.

/// Repetições livres ("20", "6-8", "30s"). Devolve o texto ou `null` se fechou.
Future<String?> escolherRepeticoes(
  BuildContext context, {
  required String atual,
  required List<String> atalhos,
  String? dica,
}) async {
  final texto = await showFxHomeSheet<String>(
    context,
    builder: (_) => _FolhaRepeticoes(atual: atual, atalhos: atalhos, dica: dica),
  );
  final limpo = texto?.trim() ?? '';
  return limpo.isEmpty ? null : limpo;
}

/// Dona do campo: o controller só some com a folha, depois da animação de
/// fechar (descartar antes quebrava o campo ainda na tela).
class _FolhaRepeticoes extends StatefulWidget {
  const _FolhaRepeticoes({required this.atual, required this.atalhos, this.dica});

  final String atual;
  final List<String> atalhos;
  final String? dica;

  @override
  State<_FolhaRepeticoes> createState() => _FolhaRepeticoesState();
}

class _FolhaRepeticoesState extends State<_FolhaRepeticoes> {
  late final _draft = TextEditingController(text: widget.atual);

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _aplicar() => Navigator.pop(context, _draft.text);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = BrandPalette.softened(primary);
    final chrome = ShellChrome.of(context);
    return FxHomeSheetSurface(
      isDark: isDark,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          const SizedBox(height: 6),
          FxHomeSheetHeader(
            isDark: isDark,
            title: prescriptionRepsLabel,
            subtitle: prescriptionRepsSubtitle,
            leading: Icon(FxIcons.treino, color: brand, size: FxSettingsLayout.iconSize),
          ),
          const SizedBox(height: TokensStrip.s3),
          FxSettingsGroup(
            accent: primary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextFormField(
                  controller: _draft,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) => _aplicar(),
                  style: FxSettingsLayout.rowLabel(color: chrome.ink),
                  decoration: InputDecoration(
                    filled: false,
                    hintText: widget.dica,
                    hintStyle: FxSettingsLayout.rowValue(color: chrome.mute),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          FxQuickChips<String>(
            itens: widget.atalhos,
            selecionado: _draft.text.trim(),
            onSelecionar: (v) {
              _draft.text = v;
              HapticFeedback.selectionClick();
              setState(() {});
            },
          ),
          const SizedBox(height: TokensStrip.s4),
          FilledButton(onPressed: _aplicar, child: const Text(prescriptionAplicar)),
        ],
      ),
    );
  }
}

/// Descanso em segundos, da lista completa ([opcoesDescansoSeg]).
Future<int?> escolherDescanso(BuildContext context, {required int atual}) =>
    showFxInsetPickerSheet<int>(
      context,
      title: prescriptionDescanso,
      headerIcon: FxIcons.cronometro,
      selected: atual,
      items: [
        for (final s in opcoesDescansoSeg)
          FxInsetPickerSheetItem(value: s, label: s == 0 ? 'Sem descanso' : '$s s'),
      ],
    );
