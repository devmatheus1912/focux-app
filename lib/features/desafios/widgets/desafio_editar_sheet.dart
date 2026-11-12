import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_calendario_sheet.dart';
import '../../../core/widgets/fx_contador.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

/// Folha "Editar desafio": nome, descrição, meta e data final. O que conta
/// fica travado (mudar invalidaria a contagem) e aparece como texto.
/// Devolve true quando salvou.
Future<bool> showDesafioEditarSheet(
  BuildContext context, {
  required Desafio desafio,
  required DesafioRepository repo,
}) async {
  final nomeCtrl = TextEditingController(text: desafio.titulo);
  final descricaoCtrl = TextEditingController(text: desafio.descricao ?? '');
  var meta = desafio.metaPontos;
  final hoje = DateUtils.dateOnly(DateTime.now());
  var fim = desafio.fim == null ? null : DateUtils.dateOnly(desafio.fim!);
  final mudou = ValueNotifier(0);
  nomeCtrl.addListener(() => mudou.value++);
  var salvou = false;
  try {
    await showFxFormSheet(
      context,
      title: 'Editar desafio',
      icon: FxIcons.editar,
      confirmLabel: 'Salvar',
      ouvir: mudou,
      podeConfirmar: () => nomeCtrl.text.trim().isNotEmpty,
      aoConfirmar: () async {
        try {
          await repo.editar(
            desafio.id,
            titulo: nomeCtrl.text.trim(),
            descricao: descricaoCtrl.text.trim(),
            metaPontos: meta,
            fim: fim,
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
                'Conta: ${desafioTipoLabel(desafio.tipo)}. Isso não muda depois de criado.',
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s3),
              AlunoInsetFormField(
                controller: nomeCtrl,
                label: 'Nome',
                icon: FxIcons.titulo,
              ),
              AlunoInsetFormField(
                controller: descricaoCtrl,
                label: 'Descrição (opcional)',
                icon: FxIcons.notas,
                maxLines: 2,
              ),
              const SizedBox(height: TokensStrip.s2),
              FxContador(
                rotulo: 'Meta',
                valor: meta,
                valorTexto: desafioUnidade(desafio.tipo, meta),
                min: 1,
                max: 365,
                onChanged: (v) => setSheet(() => meta = v),
              ),
              const SizedBox(height: TokensStrip.s2),
              FxSettingsTile(
                icon: FxIcons.calendario,
                label: 'Termina em',
                value: fim == null ? 'Escolher' : fxDateShort(fim!),
                showDivider: false,
                disclosure: true,
                onTap: () async {
                  final escolhida =
                      (await showFxCalendarioSheet(
                        ctx,
                        titulo: 'Termina em',
                        subtitulo: 'A data final não pode ficar antes de hoje.',
                        inicial:
                            fim != null && !fim!.isBefore(hoje) ? fim : hoje,
                        primeiro: hoje,
                        ultimo: hoje.add(const Duration(days: 365)),
                      ))?.data;
                  if (escolhida != null) setSheet(() => fim = escolhida);
                },
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
