import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_contador.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

/// Folha "Editar hábito": nome, vezes por semana e descrição. "Para quem"
/// fica travado (trocar mexeria nas marcações) e aparece como texto.
/// Devolve true quando salvou.
Future<bool> showHabitoEditarSheet(
  BuildContext context, {
  required Habito habito,
  required HabitoRepository repo,
}) async {
  final nomeCtrl = TextEditingController(text: habito.titulo);
  final descricaoCtrl = TextEditingController(text: habito.descricao ?? '');
  var vezes = habito.metaSemanal.clamp(1, 7);
  final mudou = ValueNotifier(0);
  nomeCtrl.addListener(() => mudou.value++);
  var salvou = false;
  try {
    await showFxFormSheet(
      context,
      title: 'Editar hábito',
      icon: FxIcons.editar,
      confirmLabel: 'Salvar',
      ouvir: mudou,
      podeConfirmar: () => nomeCtrl.text.trim().isNotEmpty,
      aoConfirmar: () async {
        try {
          await repo.editar(
            habito.id,
            titulo: nomeCtrl.text.trim(),
            descricao: descricaoCtrl.text.trim(),
            metaSemanal: vezes,
          );
          salvou = true;
          return null;
        } catch (e) {
          return friendlyError(e);
        }
      },
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final chrome = ShellChrome.of(ctx);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                habitoParaQuemTravado(habito.alunoId),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s3),
              AlunoInsetFormField(
                controller: nomeCtrl,
                label: 'Nome',
                icon: FxIcons.titulo,
              ),
              FxContador(
                rotulo: 'Quantas vezes por semana',
                valor: vezes,
                valorTexto: '${vezes}x',
                min: 1,
                max: 7,
                onChanged: (v) => setSheet(() => vezes = v),
              ),
              AlunoInsetFormField(
                controller: descricaoCtrl,
                label: 'Descrição (opcional)',
                icon: FxIcons.notas,
                maxLines: 2,
                showDivider: false,
              ),
            ],
          );
        },
      ),
    );
  } finally {
    nomeCtrl.dispose();
    descricaoCtrl.dispose();
    mudou.dispose();
  }
  return salvou;
}
