import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_confirm_sheet.dart';
import 'fx_home_sheet.dart';
import 'fx_settings_group.dart';
import 'fx_settings_tile.dart';
import 'fx_sheet_frame.dart';

/// Uma ação da folha. [valor] é o que a folha devolve ao ser tocada.
class FxActionItem<T> {
  const FxActionItem({
    required this.valor,
    required this.rotulo,
    required this.icone,
    this.descricao,
    this.perigo = false,
  });

  final T valor;
  final String rotulo;
  final IconData icone;
  final String? descricao;

  /// Linha em vermelho, para ação séria mas reversível (ex.: bloquear acesso).
  final bool perigo;
}

/// Ações do mesmo tipo, com um título pequeno ("Montar", "Usar", "Guardar").
class FxActionGroup<T> {
  const FxActionGroup(this.titulo, this.itens);

  final String? titulo;
  final List<FxActionItem<T>> itens;
}

/// Folha de ações em grupos. A ação destrutiva vai por último, em **linha de
/// texto vermelha** e com confirmação: nunca um botão cheio.
Future<T?> showFxGroupedActionSheet<T>(
  BuildContext context, {
  required String titulo,
  required List<FxActionGroup<T>> grupos,
  String? subtitulo,
  IconData icone = Icons.more_horiz_rounded,
  FxActionItem<T>? destrutiva,
  String? confirmarTitulo,
  String? confirmarMensagem,
  bool confirmar = true,
}) {
  return showFxHomeSheet<T>(
    context,
    builder: (ctx) => FxGroupedActionSheet<T>(
      titulo: titulo,
      subtitulo: subtitulo,
      icone: icone,
      grupos: grupos,
      destrutiva: destrutiva,
      confirmarTitulo: confirmarTitulo,
      confirmarMensagem: confirmarMensagem,
      confirmar: confirmar,
    ),
  );
}

class FxGroupedActionSheet<T> extends StatelessWidget {
  const FxGroupedActionSheet({
    super.key,
    required this.titulo,
    required this.grupos,
    this.subtitulo,
    this.icone = Icons.more_horiz_rounded,
    this.destrutiva,
    this.confirmarTitulo,
    this.confirmarMensagem,
    this.confirmar = true,
  });

  final String titulo;
  final String? subtitulo;
  final IconData icone;
  final List<FxActionGroup<T>> grupos;
  final FxActionItem<T>? destrutiva;
  final String? confirmarTitulo;
  final String? confirmarMensagem;

  /// Com `false`, a ação vale já ao tocar (quando há "Desfazer" depois).
  final bool confirmar;

  Future<void> _destrutiva(BuildContext context) async {
    final item = destrutiva!;
    if (!confirmar) {
      Navigator.of(context).pop(item.valor);
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: confirmarTitulo ?? item.rotulo,
      subtitle: subtitulo,
      message: confirmarMensagem ?? '',
      confirmLabel: item.rotulo,
      destructive: true,
    );
    if (ok && context.mounted) Navigator.of(context).pop(item.valor);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return FxSheetFrame(
      title: titulo,
      subtitle: subtitulo,
      leading: Icon(icone, color: primary, size: FxSettingsLayout.iconSize),
      maxHeightFactor: 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, g) in grupos.indexed) ...[
            if (i > 0) const SizedBox(height: TokensStrip.s3),
            if (g.titulo != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, TokensStrip.s1),
                child: Semantics(
                  header: true,
                  child: Text(
                    g.titulo!,
                    style: FocuxHubTypography.chip(chrome.mute),
                  ),
                ),
              ),
            FxSettingsGroup(
              children: [
                for (final (j, a) in g.itens.indexed)
                  FxSettingsTile(
                    icon: a.icone,
                    label: a.rotulo,
                    subtitle: a.descricao,
                    value: '',
                    picker: true,
                    danger: a.perigo,
                    showDivider: j < g.itens.length - 1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(a.valor);
                    },
                  ),
              ],
            ),
          ],
          if (destrutiva != null) ...[
            const SizedBox(height: TokensStrip.s3),
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  icon: destrutiva!.icone,
                  label: destrutiva!.rotulo,
                  value: '',
                  danger: true,
                  showDivider: false,
                  onTap: () => _destrutiva(context),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
