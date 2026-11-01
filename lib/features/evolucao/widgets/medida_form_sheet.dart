import 'package:flutter/material.dart';

import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../l10n/pt.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/evolucao_repository.dart';

typedef MedidaEditada = ({
  double? peso,
  double? cintura,
  double? quadril,
  double? braco,
});

enum AcaoDaMedida { editar, excluir }

/// Pergunta o que fazer com a medida. Editar só para quem a registrou.
Future<AcaoDaMedida?> escolherAcaoDaMedida(
  BuildContext context, {
  required bool podeEditar,
}) => showFxGroupedActionSheet<AcaoDaMedida>(
  context,
  titulo: ptS.evolucaoMedidaAcoes,
  grupos: [
    FxActionGroup<AcaoDaMedida>(null, [
      if (podeEditar)
        FxActionItem(
          valor: AcaoDaMedida.editar,
          rotulo: ptS.evolucaoMedidaEditar,
          icone: Icons.edit_outlined,
        ),
      FxActionItem(
        valor: AcaoDaMedida.excluir,
        rotulo: ptS.evolucaoMedidaExcluir,
        icone: Icons.delete_outline_rounded,
        perigo: true,
      ),
    ]),
  ],
);

/// Corrige uma medida. Nulo se a pessoa cancelar.
Future<MedidaEditada?> editarMedidaSheet(
  BuildContext context,
  MedidaCorporal medida,
) async {
  String texto(double? v) => v == null ? '' : formatBrDecimal(v);
  final peso = TextEditingController(text: texto(medida.peso));
  final cintura = TextEditingController(text: texto(medida.cintura));
  final quadril = TextEditingController(text: texto(medida.quadril));
  final braco = TextEditingController(text: texto(medida.braco));
  double? ler(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll('.', '').replaceAll(',', '.'));
  const teclado = TextInputType.numberWithOptions(decimal: true);
  try {
    final ok = await showFxFormSheet(
      context,
      title: ptS.evolucaoMedidaEditar,
      icon: Icons.edit_outlined,
      confirmLabel: ptS.evolucaoSalvar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AlunoInsetFormField(
            rotuloVisivel: true,
            controller: peso,
            label: ptS.evolucaoCampoPeso,
            icon: Icons.monitor_weight_outlined,
            keyboardType: teclado,
          ),
          AlunoInsetFormField(
            rotuloVisivel: true,
            controller: cintura,
            label: ptS.evolucaoCampoCintura,
            icon: Icons.straighten_outlined,
            keyboardType: teclado,
          ),
          AlunoInsetFormField(
            rotuloVisivel: true,
            controller: quadril,
            label: ptS.evolucaoCampoQuadril,
            icon: Icons.straighten_outlined,
            keyboardType: teclado,
          ),
          AlunoInsetFormField(
            rotuloVisivel: true,
            controller: braco,
            label: ptS.evolucaoCampoBraco,
            icon: Icons.straighten_outlined,
            keyboardType: teclado,
            showDivider: false,
          ),
        ],
      ),
    );
    if (!ok) return null;
    return (
      peso: ler(peso),
      cintura: ler(cintura),
      quadril: ler(quadril),
      braco: ler(braco),
    );
  } finally {
    peso.dispose();
    cintura.dispose();
    quadril.dispose();
    braco.dispose();
  }
}
