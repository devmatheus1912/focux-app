import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/money/fx_money_input.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/pacote_repository.dart';
import '../utils/pacote_display.dart';

/// Folha do plano (novo ou editar): nome, preço, duração e "O que inclui"
/// em chips, descrição e destaque. Salva com a folha aberta.
Future<bool> showPlanoSheet(
  BuildContext context, {
  required PacoteRepository repo,
  Pacote? plano,
}) async {
  final nomeCtrl = TextEditingController(text: plano?.titulo ?? '');
  final precoCtrl = TextEditingController(text: plano?.valor.format() ?? '');
  final descCtrl = TextEditingController(text: plano?.descricao ?? '');
  var meses = plano?.duracaoMeses ?? 1;
  var treino = plano?.incluiTreino ?? true;
  var consultoria = plano?.incluiConsultoria ?? false;
  var destaque = plano?.destaque ?? false;
  final mudou = ValueNotifier(0);
  nomeCtrl.addListener(() => mudou.value++);
  precoCtrl.addListener(() => mudou.value++);

  try {
    return await showFxFormSheet(
      context,
      title: plano == null ? 'Novo plano' : 'Editar plano',
      subtitle: 'Quem abrir seu link vê este plano na sua página.',
      icon: FxIcons.dinheiro,
      confirmLabel: 'Salvar',
      ouvir: mudou,
      podeConfirmar:
          () =>
              nomeCtrl.text.trim().isNotEmpty &&
              fxMoneyDoCampo(precoCtrl.text) != null,
      aoConfirmar: () async {
        try {
          final valor = fxMoneyDoCampo(precoCtrl.text)!.asReais;
          final desc = descCtrl.text.trim();
          if (plano == null) {
            await repo.criar(
              titulo: nomeCtrl.text.trim(),
              descricao: desc.isEmpty ? null : desc,
              valor: valor,
              duracaoMeses: meses,
              incluiTreino: treino,
              incluiConsultoria: consultoria,
              destaque: destaque,
            );
          } else {
            await repo.atualizar(
              plano.id,
              titulo: nomeCtrl.text.trim(),
              descricao: desc,
              valor: valor,
              duracaoMeses: meses,
              incluiTreino: treino,
              incluiConsultoria: consultoria,
              destaque: destaque,
            );
          }
          HapticFeedback.mediumImpact();
          return null;
        } catch (e) {
          return friendlyError(e);
        }
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
              AlunoInsetFormField(
                controller: nomeCtrl,
                label: 'Nome',
                icon: FxIcons.titulo,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(pacoteTituloMax),
                ],
              ),
              AlunoInsetFormField(
                controller: precoCtrl,
                label: 'Preço',
                hint: 'R\$ 0,00',
                icon: FxIcons.pagamento,
                keyboardType: TextInputType.number,
                inputFormatters: const [FxMoneyInputFormatter()],
              ),
              rotulo('Duração'),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final m in pacoteDuracaoMesesValues)
                    FxToggleChip(
                      label: pacoteDuracaoLabel(m),
                      selected: meses == m,
                      isDark: chrome.isDark,
                      filledWhenSelected: true,
                      onTap: () => setSheet(() => meses = m),
                    ),
                ],
              ),
              rotulo('O que inclui'),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  FxToggleChip(
                    label: 'Treino',
                    selected: treino,
                    isDark: chrome.isDark,
                    filledWhenSelected: true,
                    onTap: () => setSheet(() => treino = !treino),
                  ),
                  FxToggleChip(
                    label: 'Consultoria',
                    selected: consultoria,
                    isDark: chrome.isDark,
                    filledWhenSelected: true,
                    onTap: () => setSheet(() => consultoria = !consultoria),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              AlunoInsetFormField(
                controller: descCtrl,
                label: 'Descrição (opcional)',
                icon: FxIcons.notas,
                maxLines: 2,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(pacoteDescricaoMax),
                ],
              ),
              FxSettingsGroup(
                semMoldura: true,
                children: [
                  FxSettingsTile(
                    icon: FxIcons.estrela,
                    label: 'Mostrar em destaque na página',
                    value: '',
                    showDivider: false,
                    accessory: Switch.adaptive(
                      activeTrackColor: Theme.of(ctx).colorScheme.primary,
                      value: destaque,
                      onChanged: (v) => setSheet(() => destaque = v),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  } finally {
    nomeCtrl.dispose();
    precoCtrl.dispose();
    descCtrl.dispose();
    mudou.dispose();
  }
}
