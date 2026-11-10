import 'package:flutter/material.dart';

import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/data/aluno_repository.dart';

/// Escolha de vários alunos para inscrever na aula. Devolve nulo se fechar
/// sem confirmar. [limite]: vagas da aula (não deixa passar delas).
Future<Set<int>?> showGrupoAulaAlunosSheet(
  BuildContext context, {
  required List<Aluno> alunos,
  required Set<int> selecionados,
  required int limite,
}) {
  final escolha = {...selecionados};
  return showFxHomeSheet<Set<int>>(
    context,
    builder: (sheetContext) {
      final chrome = ShellChrome.of(sheetContext);
      return FxHomeSheetSurface(
        isDark: chrome.isDark,
        maxHeight:
            MediaQuery.sizeOf(sheetContext).height *
            FxHomeSheetChrome.maxHeightFactor,
        expand: true,
        child: StatefulBuilder(
          builder:
              (ctx, setSheet) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxHomeSheetHandle(isDark: chrome.isDark),
                  const SizedBox(height: TokensStrip.s4),
                  FxHomeSheetHeader(
                    isDark: chrome.isDark,
                    title: 'Inscrever alunos',
                    subtitle: '${escolha.length} de $limite vagas',
                    leading: Icon(
                      FxIcons.grupo,
                      color: Theme.of(ctx).colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final (i, a) in alunos.indexed)
                          FxSettingsTile(
                            icon: FxIcons.pessoa,
                            label: fxTitleCaseName(a.nome),
                            value: '',
                            mute: chrome.mute,
                            line: chrome.line,
                            showDivider: i < alunos.length - 1,
                            accessory: Checkbox.adaptive(
                              value: escolha.contains(a.id),
                              onChanged:
                                  (v) => setSheet(() {
                                    if (v == true && escolha.length < limite) {
                                      escolha.add(a.id);
                                    } else {
                                      escolha.remove(a.id);
                                    }
                                  }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  FxLiquidPrimaryButton(
                    label:
                        escolha.isEmpty
                            ? 'Sem alunos'
                            : 'Inscrever ${escolha.length}',
                    onPressed:
                        () => FxHomeSheetChrome.dismissAndPop(
                          sheetContext,
                          escolha,
                        ),
                  ),
                ],
              ),
        ),
      );
    },
  );
}
