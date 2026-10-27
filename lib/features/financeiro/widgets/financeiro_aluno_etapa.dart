import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../chat/utils/aluno_picker_list.dart';

/// Etapa "escolher aluno" dentro da própria folha da nova mensalidade: troca o
/// conteúdo em vez de abrir outra folha por cima.
class FinanceiroAlunoEtapa extends StatefulWidget {
  const FinanceiroAlunoEtapa({
    super.key,
    required this.alunos,
    required this.selecionadoId,
    required this.onPick,
    required this.onVoltar,
  });

  final List<Aluno> alunos;
  final int? selecionadoId;
  final ValueChanged<Aluno> onPick;
  final VoidCallback onVoltar;

  @override
  State<FinanceiroAlunoEtapa> createState() => _FinanceiroAlunoEtapaState();
}

class _FinanceiroAlunoEtapaState extends State<FinanceiroAlunoEtapa> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final filtrados = filterAlunoPickerAlunos(widget.alunos, _query);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FxHomeSheetHandle(isDark: isDark),
        const SizedBox(height: TokensStrip.s3),
        FxHomeSheetHeader(
          isDark: isDark,
          title: 'Aluno',
          subtitle: 'Quem recebe esta cobrança.',
          leading: IconButton(
            tooltip: 'Voltar',
            visualDensity: VisualDensity.compact,
            onPressed: widget.onVoltar,
            icon: Icon(Icons.arrow_back_rounded, color: chrome.brand, size: 20),
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        FxSheetSearchField(
          dica: 'Buscar aluno',
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: TokensStrip.s3),
        Flexible(
          child: SingleChildScrollView(
            child:
                filtrados.isEmpty
                    ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhum aluno encontrado.',
                        textAlign: TextAlign.center,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    )
                    : FxSettingsGroup(
                      accent: primary,
                      edgeToEdgeRows: true,
                      children: FxInsetPickerOption.list(
                        accent: BrandPalette.softened(primary),
                        items: [
                          for (final a in filtrados)
                            FxInsetPickerOptionSpec(
                              label: fxTitleCaseName(a.nome),
                              selected: a.id == widget.selecionadoId,
                              onTap: () => widget.onPick(a),
                            ),
                        ],
                      ),
                    ),
          ),
        ),
      ],
    );
  }
}
