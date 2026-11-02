import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../l10n/pt.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_series.dart';

typedef MedidaEditada = ({
  double? peso,
  double? cintura,
  double? quadril,
  double? braco,
});

typedef NovaMedida = ({
  String data,
  double? peso,
  double? cintura,
  double? quadril,
  double? braco,
  double? gordura,
  double? massa,
});

enum AcaoDaMedida { editar, excluir }

double? _ler(TextEditingController c) =>
    double.tryParse(c.text.trim().replaceAll('.', '').replaceAll(',', '.'));

const _teclado = TextInputType.numberWithOptions(decimal: true);

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

class _Campos extends StatelessWidget {
  const _Campos({
    required this.peso,
    required this.cintura,
    required this.quadril,
    required this.braco,
    this.gordura,
    this.massa,
    this.referencia = const {},
  });

  final TextEditingController peso;
  final TextEditingController cintura;
  final TextEditingController quadril;
  final TextEditingController braco;
  final TextEditingController? gordura;
  final TextEditingController? massa;

  /// Último valor de cada campo, para o personal comparar ao digitar.
  final Map<EvolucaoMetrica, String> referencia;

  Widget _campo(
    TextEditingController c,
    String rotulo,
    IconData icone, {
    EvolucaoMetrica? metrica,
    bool divisor = true,
  }) => AlunoInsetFormField(
    rotuloVisivel: true,
    controller: c,
    label:
        referencia[metrica] == null
            ? rotulo
            : '$rotulo · ${ptS.evolucaoUltimaReferencia(referencia[metrica]!)}',
    icon: icone,
    keyboardType: _teclado,
    showDivider: divisor,
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _campo(peso, ptS.evolucaoCampoPeso, Icons.monitor_weight_outlined, metrica: EvolucaoMetrica.peso),
      _campo(cintura, ptS.evolucaoCampoCintura, Icons.straighten_outlined, metrica: EvolucaoMetrica.cintura),
      _campo(quadril, ptS.evolucaoCampoQuadril, Icons.straighten_outlined, metrica: EvolucaoMetrica.quadril),
      _campo(
        braco,
        ptS.evolucaoCampoBraco,
        Icons.straighten_outlined,
        metrica: EvolucaoMetrica.braco,
        divisor: gordura != null,
      ),
      if (gordura case final g?)
        _campo(g, ptS.evolucaoCampoGordura, Icons.pie_chart_outline_outlined),
      if (massa case final m?)
        _campo(m, ptS.evolucaoCampoMassa, Icons.fitness_center_outlined, divisor: false),
    ],
  );
}

enum _DiaDaMedida { hoje, ontem }

class _EscolhaDaData extends StatelessWidget {
  const _EscolhaDaData({required this.dia, required this.onEscolher});

  final _DiaDaMedida dia;
  final ValueChanged<_DiaDaMedida> onEscolher;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ptS.evolucaoMedidaData, style: FocuxHubTypography.chip(chrome.mute)),
        const SizedBox(height: TokensStrip.s1),
        FxQuickChips<_DiaDaMedida>(
          itens: _DiaDaMedida.values,
          selecionado: dia,
          rotuloDe:
              (d) => d == _DiaDaMedida.hoje ? ptS.evolucaoHoje : ptS.evolucaoOntem,
          onSelecionar: onEscolher,
        ),
        const SizedBox(height: TokensStrip.s2),
      ],
    );
  }
}

/// Registra medida do aluno. [medidas] traz os valores atuais como referência.
Future<NovaMedida?> novaMedidaSheet(
  BuildContext context, {
  required List<MedidaCorporal> medidas,
}) async {
  final peso = TextEditingController();
  final cintura = TextEditingController();
  final quadril = TextEditingController();
  final braco = TextEditingController();
  final gordura = TextEditingController();
  final massa = TextEditingController();
  var dia = _DiaDaMedida.hoje;
  final referencia = <EvolucaoMetrica, String>{
    for (final m in EvolucaoMetrica.values)
      if (serieDaMetrica(medidas, m).lastOrNull case final ponto?)
        m: '${formatBrDecimal(ponto.valor)} ${m.unidade}',
  };
  try {
    final ok = await showFxFormSheet(
      context,
      title: ptS.evolucaoNovaMedida,
      icon: Icons.monitor_weight_outlined,
      confirmLabel: ptS.evolucaoSalvar,
      child: StatefulBuilder(
        builder:
            (context, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EscolhaDaData(
                  dia: dia,
                  onEscolher: (d) => setSheet(() => dia = d),
                ),
                _Campos(
                  peso: peso,
                  cintura: cintura,
                  quadril: quadril,
                  braco: braco,
                  gordura: gordura,
                  massa: massa,
                  referencia: referencia,
                ),
              ],
            ),
      ),
    );
    if (!ok) return null;
    final data = DateTime.now().subtract(
      Duration(days: dia == _DiaDaMedida.ontem ? 1 : 0),
    );
    return (
      data: data.toIso8601String().substring(0, 10),
      peso: _ler(peso),
      cintura: _ler(cintura),
      quadril: _ler(quadril),
      braco: _ler(braco),
      gordura: _ler(gordura),
      massa: _ler(massa),
    );
  } finally {
    for (final c in [peso, cintura, quadril, braco, gordura, massa]) {
      c.dispose();
    }
  }
}

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
  try {
    final ok = await showFxFormSheet(
      context,
      title: ptS.evolucaoMedidaEditar,
      icon: Icons.edit_outlined,
      confirmLabel: ptS.evolucaoSalvar,
      child: _Campos(peso: peso, cintura: cintura, quadril: quadril, braco: braco),
    );
    if (!ok) return null;
    return (
      peso: _ler(peso),
      cintura: _ler(cintura),
      quadril: _ler(quadril),
      braco: _ler(braco),
    );
  } finally {
    peso.dispose();
    cintura.dispose();
    quadril.dispose();
    braco.dispose();
  }
}
