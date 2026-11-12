import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/money/fx_money_input.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../data/upsell_repository.dart';
import '../utils/oferta_upsell_display.dart';

/// Rascunho da oferta: com [pacoteId], título e valor vêm do plano.
class OfertaUpsellDraft {
  const OfertaUpsellDraft({
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.tipoGatilho,
    required this.ativo,
    this.pacoteId,
  });

  final String titulo;
  final String descricao;
  final FxMoney? valor;
  final String tipoGatilho;
  final bool ativo;
  final int? pacoteId;
}

/// Folha da oferta: qual plano (ou "Outro valor"), quando mostrar ao aluno
/// e uma mensagem curta. [salvar] envia com a folha aberta (texto = erro).
Future<bool> showOfertaUpsellEditor(
  BuildContext context, {
  required List<Pacote> planos,
  required Future<String?> Function(OfertaUpsellDraft draft) salvar,
  OfertaUpsell? existing,
}) async {
  int? pacoteId =
      existing?.pacoteId ??
      (existing == null && planos.isNotEmpty ? planos.first.id : null);
  final tituloCtrl = TextEditingController(
    text: existing != null && existing.pacoteId == null ? existing.titulo : '',
  );
  final valorCtrl = TextEditingController(
    text:
        existing != null && existing.pacoteId == null
            ? existing.valor.format()
            : '',
  );
  final mensagemCtrl = TextEditingController(text: existing?.descricao ?? '');
  var tipoGatilho = existing?.tipoGatilho ?? 'MANUAL';
  var ativo = existing?.ativo ?? true;
  final mudou = ValueNotifier(0);
  tituloCtrl.addListener(() => mudou.value++);
  valorCtrl.addListener(() => mudou.value++);

  bool valido() =>
      pacoteId != null ||
      (tituloCtrl.text.trim().isNotEmpty &&
          fxMoneyDoCampo(valorCtrl.text) != null);

  try {
    return await showFxFormSheet(
      context,
      title: existing == null ? 'Nova oferta' : 'Editar oferta',
      subtitle: 'Um plano para quem já é aluno: upgrade, renovação ou extra.',
      icon: FxIcons.oferta,
      confirmLabel: existing == null ? 'Criar oferta' : 'Salvar',
      ouvir: mudou,
      podeConfirmar: valido,
      aoConfirmar: () {
        final plano = planos.where((p) => p.id == pacoteId).firstOrNull;
        return salvar(
          OfertaUpsellDraft(
            titulo: plano?.titulo ?? tituloCtrl.text.trim(),
            descricao: mensagemCtrl.text.trim(),
            valor: plano == null ? fxMoneyDoCampo(valorCtrl.text) : null,
            tipoGatilho: tipoGatilho,
            ativo: ativo,
            pacoteId: plano?.id,
          ),
        );
      },
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          final chrome = ShellChrome.of(ctx);
          Widget rotulo(String t) => Padding(
            padding: const EdgeInsets.only(
              top: TokensStrip.s3,
              bottom: TokensStrip.s2,
            ),
            child: Text(t, style: FocuxHubTypography.chip(chrome.mute)),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              rotulo('Plano'),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final p in planos)
                    FxToggleChip(
                      label: '${p.titulo} · ${p.valor.format()}',
                      selected: pacoteId == p.id,
                      isDark: chrome.isDark,
                      filledWhenSelected: true,
                      onTap:
                          () => setSheet(() {
                            pacoteId = p.id;
                            mudou.value++;
                          }),
                    ),
                  FxToggleChip(
                    label: 'Outro valor',
                    selected: pacoteId == null,
                    isDark: chrome.isDark,
                    filledWhenSelected: true,
                    onTap:
                        () => setSheet(() {
                          pacoteId = null;
                          mudou.value++;
                        }),
                  ),
                ],
              ),
              if (pacoteId == null) ...[
                const SizedBox(height: TokensStrip.s2),
                AlunoInsetFormField(
                  controller: tituloCtrl,
                  label: 'Nome da oferta',
                  icon: FxIcons.titulo,
                ),
                AlunoInsetFormField(
                  controller: valorCtrl,
                  label: 'Valor',
                  hint: 'R\$ 0,00',
                  icon: FxIcons.pagamento,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [FxMoneyInputFormatter()],
                ),
              ],
              rotulo('Quando mostrar ao aluno'),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final g in ofertaGatilhoValues)
                    FxToggleChip(
                      label: ofertaGatilhoLabel(g),
                      selected: tipoGatilho == g,
                      isDark: chrome.isDark,
                      filledWhenSelected: true,
                      onTap: () => setSheet(() => tipoGatilho = g),
                    ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              AlunoInsetFormField(
                controller: mensagemCtrl,
                label: 'Mensagem curta (opcional)',
                icon: FxIcons.notas,
                maxLines: 2,
                showDivider: existing != null,
              ),
              if (existing != null)
                FxSettingsTile(
                  icon: FxIcons.pausar,
                  label: 'Oferta ativa',
                  subtitle: 'Pausada, o aluno não recebe.',
                  value: '',
                  showDivider: false,
                  accessory: Switch.adaptive(
                    activeTrackColor: Theme.of(ctx).colorScheme.primary,
                    value: ativo,
                    onChanged: (v) => setSheet(() => ativo = v),
                  ),
                ),
            ],
          );
        },
      ),
    );
  } finally {
    tituloCtrl.dispose();
    valorCtrl.dispose();
    mensagemCtrl.dispose();
    mudou.dispose();
  }
}
