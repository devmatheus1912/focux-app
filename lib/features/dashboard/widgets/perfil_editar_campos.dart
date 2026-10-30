import 'package:flutter/material.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../alunos/utils/add_aluno_display.dart';
import '../../alunos/utils/aluno360_medida_plausivel.dart';

const generosDoAluno = [
  (valor: 'MASCULINO', rotulo: 'Masculino'),
  (valor: 'FEMININO', rotulo: 'Feminino'),
  (valor: 'OUTRO', rotulo: 'Outro'),
];

String rotuloDoGenero(String valor) => generosDoAluno
    .where((g) => g.valor == valor.trim().toUpperCase())
    .map((g) => g.rotulo)
    .firstOrNull ?? valor;

String rotuloDaConsultoria(String valor) {
  final i = addAlunoTiposConsultoria.indexOf(valor.trim().toUpperCase());
  return i < 0 ? valor : addAlunoTiposConsultoriaLabel[i];
}

/// Faixa de quem é adulto: valor impossível para antes de salvar.
String? validarPeso(String? texto) {
  final v = _numero(texto);
  if (texto == null || texto.trim().isEmpty) return null;
  return v == null || !medidaPlausivel(MedidaTipo.pesoKg, v)
      ? 'Entre 20 e 300 kg.'
      : null;
}

String? validarCm(String? texto) {
  final v = _numero(texto);
  if (texto == null || texto.trim().isEmpty) return null;
  return v == null || v < 10 || v > 250 ? 'Entre 10 e 250.' : null;
}

String numeroSemZero(double v) => formatBrDecimal(v).replaceFirst(RegExp(r',0$'), '');

double? _numero(String? texto) =>
    double.tryParse((texto ?? '').trim().replaceAll(',', '.'));

/// Linha com rótulo e valor: abre uma escolha ou só mostra (com [acao] opcional).
class CampoDeEscolha extends StatelessWidget {
  const CampoDeEscolha({
    super.key,
    required this.rotulo,
    required this.valor,
    required this.icone,
    this.onTap,
    this.acao,
  });

  final String rotulo;
  final String valor;
  final IconData icone;
  final VoidCallback? onTap;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Semantics(
      button: onTap != null,
      label: '$rotulo, ${valor.isEmpty ? 'não informado' : valor}',
      excludeSemantics: acao == null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FxSettingsLayout.groupPadH,
              vertical: TokensStrip.s1,
            ),
            child: Row(
              children: [
                Icon(icone, size: 20, color: chrome.mute),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(rotulo, style: FxSettingsLayout.footer(color: chrome.mute)),
                      Text(
                        valor.isEmpty ? 'Não informado' : valor,
                        style: FxSettingsLayout.rowLabel(
                          color: valor.isEmpty ? chrome.mute : chrome.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fim(chrome) case final fim?) fim,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _fim(ShellPalette chrome) =>
      acao ?? (onTap == null ? null : Icon(Icons.chevron_right_rounded, color: chrome.mute));
}

class MedidaCampo extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String sufixo;
  final String? Function(String?)? validator;

  const MedidaCampo({
    super.key,
    required this.controller,
    required this.label,
    required this.sufixo,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: TextFormField(
        controller: controller,
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
        decoration: FxInputDeco.build(context, label).copyWith(suffixText: sufixo, errorMaxLines: 2),
      ),
    );
  }
}

const objetivosDoAluno = addAlunoObjetivosRapidos;
