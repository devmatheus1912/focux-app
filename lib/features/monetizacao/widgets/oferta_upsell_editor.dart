import 'package:flutter/material.dart';

import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/upsell_repository.dart';
import '../utils/oferta_upsell_display.dart';

class OfertaUpsellDraft {
  const OfertaUpsellDraft({
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.tipoGatilho,
    required this.ativo,
  });

  final String titulo;
  final String descricao;
  final double valor;
  final String tipoGatilho;
  final bool ativo;
}

Future<({OfertaUpsellDraft? draft, bool submitted})> showOfertaUpsellEditor(
  BuildContext context, {
  OfertaUpsell? existing,
}) async {
  final tituloCtrl = TextEditingController(text: existing?.titulo ?? '');
  final descricaoCtrl = TextEditingController(text: existing?.descricao ?? '');
  final valorCtrl = TextEditingController(
    text: existing == null ? '' : existing.valor.wire,
  );
  var tipoGatilho = existing?.tipoGatilho ?? 'MANUAL';
  var ativo = existing?.ativo ?? true;
  OfertaUpsellDraft? draft;

  try {
    final ok = await showFxFormSheet(
      context,
      title: existing == null ? 'Nova oferta' : 'Editar oferta',
      subtitle: 'Dispara no gatilho que você escolher.',
      icon: Icons.local_offer_outlined,
      confirmLabel: existing == null ? 'Criar oferta' : 'Salvar oferta',
      child: StatefulBuilder(
        builder:
            (ctx, setDialogState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AlunoInsetFormField(
                  controller: tituloCtrl,
                  label: 'Título',
                  icon: Icons.title_outlined,
                ),
                AlunoInsetFormField(
                  controller: descricaoCtrl,
                  label: 'Descrição',
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
                AlunoInsetFormField(
                  controller: valorCtrl,
                  label: 'Valor (R\$)',
                  icon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                FxInsetPickerRow(
                  icon: Icons.bolt_outlined,
                  label: 'Gatilho',
                  value: ofertaGatilhoLabel(tipoGatilho),
                  onTap: () async {
                    final picked = await showFxInsetPickerSheet<String>(
                      ctx,
                      title: 'Gatilho',
                      selected: tipoGatilho,
                      items: [
                        for (final value in ofertaGatilhoValues)
                          FxInsetPickerSheetItem(
                            value: value,
                            label: ofertaGatilhoLabel(value),
                          ),
                      ],
                    );
                    if (picked == null) return;
                    setDialogState(() => tipoGatilho = picked);
                  },
                ),
                if (existing != null)
                  FxInsetPickerRow(
                    icon: Icons.toggle_on_outlined,
                    label: 'Status',
                    value: ofertaStatusLabel(ativo: ativo),
                    showDivider: false,
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<bool>(
                        ctx,
                        title: 'Status',
                        selected: ativo,
                        items: [
                          FxInsetPickerSheetItem(
                            value: true,
                            label: ofertaStatusLabel(ativo: true),
                          ),
                          FxInsetPickerSheetItem(
                            value: false,
                            label: ofertaStatusLabel(ativo: false),
                          ),
                        ],
                      );
                      if (picked == null) return;
                      setDialogState(() => ativo = picked);
                    },
                  ),
              ],
            ),
      ),
    );
    if (ok != true) return (draft: null, submitted: false);
    final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
    final titulo = tituloCtrl.text.trim();
    if (titulo.isEmpty || valor == null || valor <= 0) {
      return (draft: null, submitted: true);
    }
    draft = OfertaUpsellDraft(
      titulo: titulo,
      descricao: descricaoCtrl.text.trim(),
      valor: valor,
      tipoGatilho: tipoGatilho,
      ativo: ativo,
    );
  } finally {
    tituloCtrl.dispose();
    descricaoCtrl.dispose();
    valorCtrl.dispose();
  }
  return (draft: draft, submitted: true);
}
