import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';

part 'evolucao_screen_widgets.part.dart';

final evolucaoHomeProvider = FutureProvider.family<EvolucaoHomeBundle, int>((
  ref,
  alunoId,
) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.getHome(alunoId);
});

class EvolucaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends ConsumerState<EvolucaoScreen> {
  EvolucaoHubView _view = EvolucaoHubView.medidas;

  Future<void> _abrirVista() async {
    final picked = await showFxInsetPickerSheet<EvolucaoHubView>(
      context,
      title: 'Ver',
      selected: _view,
      items: [
        for (final v in EvolucaoHubView.values)
          FxInsetPickerSheetItem(value: v, label: evolucaoHubViewLabel(v)),
      ],
    );
    if (!mounted || picked == null || picked == _view) return;
    setState(() => _view = picked);
  }

  void _registrar() {
    if (_view == EvolucaoHubView.medidas) {
      _mostrarDialogMedida();
    } else {
      _mostrarDialogRecorde();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(evolucaoHomeProvider(widget.alunoId));
    final medidasAsync = homeAsync.whenData((h) => h.medidas);
    final recordesAsync = homeAsync.whenData((h) => h.recordes);
    final variacao = medidasAsync.whenOrNull(
      data: evolucaoVariacaoPeso,
    );

    return fxScreenA11yScope(
      label: 'Evolução — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Evolução — ${widget.alunoNome}',
          subtitle: evolucaoHubSubtitle(view: _view, variacao: variacao),
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            ShellHeaderIconButton(
              icon: 'trend',
              tooltip: 'Trocar visão',
              onTap: _abrirVista,
            ),
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip:
                  _view == EvolucaoHubView.medidas
                      ? 'Registrar medida'
                      : 'Registrar recorde',
              onTap: _registrar,
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: IndexedStack(
            index: _view.index,
            children: [
              _TabMedidas(
                alunoNome: widget.alunoNome,
                medidasAsync: medidasAsync,
                onRegister: _mostrarDialogMedida,
                onRetry:
                    () => ref.invalidate(
                      evolucaoHomeProvider(widget.alunoId),
                    ),
              ),
              _TabRecordes(
                alunoNome: widget.alunoNome,
                recordesAsync: recordesAsync,
                onRegister: _mostrarDialogRecorde,
                onRetry:
                    () => ref.invalidate(
                      evolucaoHomeProvider(widget.alunoId),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogMedida() async {
    final pesoCtrl = TextEditingController();
    final abdomenCtrl = TextEditingController();
    final quadrilCtrl = TextEditingController();
    final bracoCtrl = TextEditingController();
    try {
      final saved = await showFxFormSheet(
        context,
        title: 'Nova medida',
        icon: Icons.monitor_weight_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CampoNumerico(controller: pesoCtrl, label: 'Peso (kg)'),
            const SizedBox(height: 10),
            _CampoNumerico(
              controller: abdomenCtrl,
              label: 'Circunf. abdômen (cm)',
            ),
            const SizedBox(height: 10),
            _CampoNumerico(controller: quadrilCtrl, label: 'Quadril (cm)'),
            const SizedBox(height: 10),
            _CampoNumerico(controller: bracoCtrl, label: 'Braço (cm)'),
          ],
        ),
      );
      if (saved != true) return;
      await EvolucaoRepository(ref.read(apiClientProvider)).adicionarMedida(
        widget.alunoId,
        peso: double.tryParse(pesoCtrl.text.replaceAll(',', '.')),
        cintura: double.tryParse(abdomenCtrl.text.replaceAll(',', '.')),
        quadril: double.tryParse(quadrilCtrl.text.replaceAll(',', '.')),
        braco: double.tryParse(bracoCtrl.text.replaceAll(',', '.')),
      );
      ref.invalidate(evolucaoHomeProvider(widget.alunoId));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Medida adicionada!');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      pesoCtrl.dispose();
      abdomenCtrl.dispose();
      quadrilCtrl.dispose();
      bracoCtrl.dispose();
    }
  }

  Future<void> _mostrarDialogRecorde() async {
    final exercicioCtrl = TextEditingController();
    final cargaCtrl = TextEditingController();
    final unidadeCtrl = TextEditingController(text: 'kg');
    final obsCtrl = TextEditingController();
    try {
      final saved = await showFxFormSheet(
        context,
        title: 'Novo recorde',
        icon: Icons.emoji_events_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: exercicioCtrl,
              decoration: FxInputDeco.build(context, 'Exercício'),
            ),
            const SizedBox(height: 10),
            _CampoNumerico(controller: cargaCtrl, label: 'Carga'),
            const SizedBox(height: 10),
            TextField(
              controller: unidadeCtrl,
              decoration: FxInputDeco.build(
                context,
                'Unidade (kg, reps…)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: obsCtrl,
              decoration: FxInputDeco.build(context, 'Observação'),
              maxLines: 2,
            ),
          ],
        ),
      );
      if (saved != true) return;
      final nome = exercicioCtrl.text.trim();
      if (nome.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(context, 'Informe o exercício.');
        return;
      }
      await EvolucaoRepository(ref.read(apiClientProvider)).adicionarRecorde(
        widget.alunoId,
        exercicioNome: nome,
        carga: double.tryParse(cargaCtrl.text.replaceAll(',', '.')),
        unidade: unidadeCtrl.text.trim(),
        observacao: obsCtrl.text.trim(),
      );
      ref.invalidate(evolucaoHomeProvider(widget.alunoId));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Recorde adicionado!');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      exercicioCtrl.dispose();
      cargaCtrl.dispose();
      unidadeCtrl.dispose();
      obsCtrl.dispose();
    }
  }
}
