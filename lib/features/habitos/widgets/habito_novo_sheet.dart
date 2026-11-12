import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_contador.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

/// Folha "Novo hábito": modelo em chips, nome, quantas vezes por semana,
/// para quem e descrição. Cria com a folha aberta.
Future<bool> showHabitoNovoSheet({
  required BuildContext context,
  required HabitoRepository repo,
  required Future<List<Aluno>> Function() loadAlunos,
}) async {
  var modelos = <HabitoTemplate>[];
  var alunos = <Aluno>[];
  try {
    modelos =
        (await repo.templates()).where((t) => t.tipo != 'CUSTOM').toList();
  } catch (_) {
    // Sem modelos, a folha segue só com "Personalizado".
  }
  try {
    alunos = await loadAlunos();
  } catch (_) {}
  if (!context.mounted) return false;

  HabitoTemplate? modelo;
  var vezes = 7;
  int? alunoId;
  String? alunoNome;
  var paraUm = false;
  final nomeCtrl = TextEditingController();
  final descricaoCtrl = TextEditingController();
  final mudou = ValueNotifier(0);
  nomeCtrl.addListener(() => mudou.value++);
  var created = false;

  try {
    await showFxFormSheet(
      context,
      title: 'Novo hábito',
      subtitle: 'O que o aluno faz fora do treino e marca no app.',
      icon: FxIcons.adicionarTarefa,
      confirmLabel: 'Criar hábito',
      ouvir: mudou,
      podeConfirmar:
          () => nomeCtrl.text.trim().isNotEmpty && (!paraUm || alunoId != null),
      aoConfirmar: () async {
        try {
          await repo.criar(
            titulo: nomeCtrl.text.trim(),
            descricao:
                descricaoCtrl.text.trim().isEmpty
                    ? null
                    : descricaoCtrl.text.trim(),
            tipo: modelo?.tipo ?? 'CUSTOM',
            metaDiaria: modelo?.metaDiaria,
            metaSemanal: vezes,
            icone: modelo?.icone,
            alunoId: paraUm ? alunoId : null,
          );
          created = true;
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
              rotulo('Modelo'),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final m in modelos)
                    FxToggleChip(
                      label: m.titulo,
                      selected: modelo?.tipo == m.tipo,
                      isDark: chrome.isDark,
                      filledWhenSelected: true,
                      onTap:
                          () => setSheet(() {
                            modelo = m;
                            nomeCtrl.text = m.titulo;
                            descricaoCtrl.text = m.descricao ?? '';
                            vezes = m.metaSemanal.clamp(1, 7);
                          }),
                    ),
                  FxToggleChip(
                    label: 'Personalizado',
                    selected: modelo == null,
                    isDark: chrome.isDark,
                    filledWhenSelected: true,
                    onTap:
                        () => setSheet(() {
                          modelo = null;
                          nomeCtrl.clear();
                          descricaoCtrl.clear();
                        }),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
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
              rotulo('Para quem'),
              Wrap(
                spacing: TokensStrip.s2,
                children: [
                  FxToggleChip(
                    label: habitoAlunoTodosLabel,
                    selected: !paraUm,
                    isDark: chrome.isDark,
                    filledWhenSelected: true,
                    onTap:
                        () => setSheet(() {
                          paraUm = false;
                          mudou.value++;
                        }),
                  ),
                  FxToggleChip(
                    label: 'Um aluno',
                    selected: paraUm,
                    isDark: chrome.isDark,
                    filledWhenSelected: true,
                    onTap:
                        alunos.isEmpty
                            ? null
                            : () => setSheet(() {
                              paraUm = true;
                              mudou.value++;
                            }),
                  ),
                ],
              ),
              if (paraUm)
                FxInsetPickerRow(
                  icon: FxIcons.pessoa,
                  label: 'Aluno',
                  value: alunoNome ?? 'Escolher',
                  onTap: () async {
                    final picked = await showFxInsetPickerSheet<int>(
                      ctx,
                      title: 'Para qual aluno',
                      selected: alunoId,
                      items: [
                        for (final a in alunos)
                          FxInsetPickerSheetItem(
                            value: a.id,
                            label: habitoComplianceLabel(a.nome),
                          ),
                      ],
                    );
                    if (picked == null) return;
                    final aluno =
                        alunos.where((a) => a.id == picked).firstOrNull;
                    if (aluno == null) return;
                    setSheet(() {
                      alunoId = aluno.id;
                      alunoNome = habitoComplianceLabel(aluno.nome);
                    });
                    mudou.value++;
                  },
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
  return created;
}
