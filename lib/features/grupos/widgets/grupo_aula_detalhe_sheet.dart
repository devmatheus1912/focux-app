import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/grupo_aula_repository.dart';
import '../utils/grupo_aula_display.dart';

/// O que o personal escolheu no detalhe da aula.
enum GrupoAulaAcao { inscrever, editar, cancelar }

/// Detalhe da aula para o personal: quando, onde, quem está inscrito e o que
/// fazer com a turma. Aula cancelada só mostra.
Future<GrupoAulaAcao?> showGrupoAulaDetalheSheet(
  BuildContext context, {
  required GrupoAula aula,
  required Future<List<GrupoAulaInscrito>> inscritos,
}) {
  return showFxHomeSheet<GrupoAulaAcao>(
    context,
    builder: (sheetContext) {
      final chrome = ShellChrome.of(sheetContext);
      final primary = Theme.of(sheetContext).colorScheme.primary;
      final descricao = (aula.descricao ?? '').trim();
      void escolher(GrupoAulaAcao a) =>
          FxHomeSheetChrome.dismissAndPop(sheetContext, a);
      return FxHomeSheetSurface(
        isDark: chrome.isDark,
        maxHeight:
            MediaQuery.sizeOf(sheetContext).height *
            FxHomeSheetChrome.maxHeightFactor,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: chrome.isDark),
              FxHomeSheetHeader(
                isDark: chrome.isDark,
                leading: Icon(FxIcons.grupo, color: primary, size: 18),
                title: aula.titulo,
                subtitle: grupoAulaLinha(
                  inicio: aula.inicio,
                  fim: aula.fim,
                  localAula: aula.localAula,
                ),
              ),
              if (descricao.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    0,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3,
                  ),
                  child: Text(
                    descricao,
                    style: FocuxHubTypography.body(color: chrome.ink),
                  ),
                ),
              FutureBuilder<List<GrupoAulaInscrito>>(
                future: inscritos,
                builder: (ctx, snap) {
                  final lista = snap.data ?? const <GrupoAulaInscrito>[];
                  final titulo =
                      '${aula.inscritos} de ${aula.capacidadeMax} vagas preenchidas';
                  return FxSettingsGroup(
                    header: 'Inscritos',
                    caption: titulo,
                    children: [
                      if (snap.connectionState != ConnectionState.done)
                        FxSettingsTile(
                          icon: FxIcons.grupo,
                          label: 'Carregando…',
                          value: '',
                          mute: chrome.mute,
                          line: chrome.line,
                          showDivider: false,
                        )
                      else if (snap.hasError)
                        FxSettingsTile(
                          icon: FxIcons.alerta,
                          label: 'Não deu para carregar os inscritos',
                          value: '',
                          mute: chrome.mute,
                          line: chrome.line,
                          showDivider: false,
                        )
                      else if (lista.isEmpty)
                        FxSettingsTile(
                          icon: FxIcons.grupo,
                          label: 'Ninguém inscrito ainda',
                          value: '',
                          mute: chrome.mute,
                          line: chrome.line,
                          showDivider: false,
                        )
                      else
                        for (final (i, a) in lista.indexed)
                          FxSettingsTile(
                            icon: FxIcons.pessoa,
                            label: fxTitleCaseName(a.nome),
                            value: '',
                            mute: chrome.mute,
                            line: chrome.line,
                            showDivider: i < lista.length - 1,
                          ),
                    ],
                  );
                },
              ),
              if (!aula.cancelada) ...[
                const SizedBox(height: FxSettingsLayout.groupGap),
                FxSettingsGroup(
                  children: [
                    FxSettingsTile(
                      icon: FxIcons.adicionarPessoa,
                      label: 'Inscrever alunos',
                      value: '',
                      mute: chrome.mute,
                      line: chrome.line,
                      onTap: () => escolher(GrupoAulaAcao.inscrever),
                    ),
                    FxSettingsTile(
                      icon: FxIcons.editar,
                      label: 'Editar aula',
                      subtitle: 'Mudar horário ou local avisa os inscritos',
                      value: '',
                      mute: chrome.mute,
                      line: chrome.line,
                      onTap: () => escolher(GrupoAulaAcao.editar),
                    ),
                    FxSettingsTile(
                      icon: FxIcons.excluir,
                      label: 'Cancelar aula',
                      value: '',
                      accent: EagleTokens.bad,
                      mute: chrome.mute,
                      line: chrome.line,
                      showDivider: false,
                      onTap: () => escolher(GrupoAulaAcao.cancelar),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: TokensStrip.s4),
            ],
          ),
        ),
      );
    },
  );
}
