import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/exercicios_aba_treinos.dart';
import '../providers/ficha_modelos_provider.dart';
import '../widgets/ficha_modelos_aba.dart';
import '../widgets/modelo_acoes.dart';
import '../widgets/treinos_list_help_sheet.dart';

/// Aba Treinos do personal: Semanas (modelos de ficha) | Exercícios.
/// Sessão solta não tem mais aba: reaproveitar é "Copiar de um modelo" no dia.
class ModelosDeTreinoView extends ConsumerStatefulWidget {
  const ModelosDeTreinoView({super.key, this.abrirNovoModelo = false});

  final bool abrirNovoModelo;

  @override
  ConsumerState<ModelosDeTreinoView> createState() => _ModelosDeTreinoViewState();
}

class _ModelosDeTreinoViewState extends ConsumerState<ModelosDeTreinoView> {
  static const _semanas = 0;
  static const _exercicios = 1;
  var _aba = _semanas;
  String? _resumoExercicios; // topo da aba Exercícios, vindo da lista

  @override
  void initState() {
    super.initState();
    if (widget.abrirNovoModelo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) criarNovoModelo(context, ref);
      });
    }
  }

  Widget _abas(S s) => FxChoiceStrip<int>(
    itens: [
      FxChoiceItem(value: _semanas, label: s.modelosAbaSemanas),
      FxChoiceItem(value: _exercicios, label: s.modelosAbaExercicios),
    ],
    selecionado: _aba,
    onSelecionar: (aba) => setState(() => _aba = aba),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final modelos = ref.watch(fichaModelosProvider).asData?.value;
    // O topo segue a aba: em Exercícios conta exercícios, nunca modelos.
    final emExercicios = _aba == _exercicios;
    final titulo = emExercicios ? s.modelosAbaExercicios : s.treinosModelosTitulo;
    return fxScreenA11yScope(
      label: titulo,
      child: FxShellScaffold(
        comFundo: true,
        appBar: FxShellAppBar(
          title: titulo,
          subtitle: emExercicios
              ? _resumoExercicios
              : (modelos == null ? null : s.modelosContagemTopo(modelos.length)),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar os treinos',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.treinosHelpOpened,
                  props: {'scope': 'library'},
                );
                showTreinosListHelpSheet(context);
              },
            ),
          ],
        ),
        body: _aba == _semanas
            ? FichaModelosAba(abas: _abas(s))
            : ExerciciosAbaTreinos(
                abas: _abas(s),
                onResumoTopo: (r) => setState(() => _resumoExercicios = r),
              ),
      ),
    );
  }
}
