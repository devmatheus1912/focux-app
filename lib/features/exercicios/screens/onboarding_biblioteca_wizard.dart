import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../data/enums.dart';
import '../providers/exercicios_provider.dart';
import 'widgets/wizard_step_confirmacao.dart';
import 'widgets/wizard_step_espacos.dart';
import 'widgets/wizard_step_loading.dart';
import 'widgets/wizard_step_modalidades.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class OnboardingBibliotecaWizard extends ConsumerStatefulWidget {
  const OnboardingBibliotecaWizard({super.key});

  @override
  ConsumerState<OnboardingBibliotecaWizard> createState() =>
      _OnboardingBibliotecaWizardState();
}

class _OnboardingBibliotecaWizardState
    extends ConsumerState<OnboardingBibliotecaWizard> {
  int _step = 0;
  bool _importing = false;
  Future<Map<String, dynamic>>? _previewFuture;
  final Set<Modalidade> _modalidades = {
    Modalidade.musculacao,
    Modalidade.mobilidade,
    Modalidade.cardio,
  };
  final Set<Espaco> _espacos = {
    Espaco.academiaCompleta,
    Espaco.academiaBasica,
    Espaco.casaEquipada,
  };

  void _toggleModalidade(Modalidade value) {
    setState(() {
      _modalidades.contains(value)
          ? _modalidades.remove(value)
          : _modalidades.add(value);
    });
  }

  void _toggleEspaco(Espaco value) {
    setState(() {
      _espacos.contains(value) ? _espacos.remove(value) : _espacos.add(value);
    });
  }

  void _next() {
    if (_step == 0 && _modalidades.isEmpty) return;
    if (_step == 1 && _espacos.isEmpty) return;
    setState(() {
      if (_step == 1) {
        _previewFuture = ref
            .read(exercicioRepositoryProvider)
            .previewCuratedV2(modalidades: _modalidades, espacos: _espacos);
      }
      _step += 1;
    });
  }

  Future<void> _importar() async {
    setState(() {
      _importing = true;
      _step = 3;
    });
    try {
      final result = await ref
          .read(exercicioRepositoryProvider)
          .importarCuratedV2(modalidades: _modalidades, espacos: _espacos);
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      final importados = (result['importados'] as num?)?.toInt() ?? 0;
      AnalyticsService.instance.track(
        'wizard_completed',
        props: {
          'modalidades': _modalidades.map((e) => e.backendName).toList(),
          'espacos': _espacos.map((e) => e.backendName).toList(),
          'importados': importados,
        },
      );
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, '$importados exercicios carregados.');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importing = false;
        _step = 2;
      });
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoNext =
        (_step == 0 && _modalidades.isNotEmpty) ||
        (_step == 1 && _espacos.isNotEmpty);

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Biblioteca curada',
        subtitle: 'Monte sua base de exercícios em minutos',
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Pular configuração',
          onPressed:
              _importing
                  ? null
                  : () {
                    AnalyticsService.instance.track('wizard_skipped');
                    context.pop(false);
                  },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              LinearProgressIndicator(value: (_step + 1) / 4),
              const SizedBox(height: 24),
              Expanded(child: _content()),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_step > 0 && _step < 3)
                    TextButton(
                      onPressed:
                          _importing ? null : () => setState(() => _step -= 1),
                      child: const Text('Voltar'),
                    ),
                  const Spacer(),
                  if (_step < 2)
                    FxLiquidPrimaryButton(
                      label: 'Continuar',
                      onPressed: canGoNext ? _next : null,
                      expand: false,
                    ),
                  if (_step == 2)
                    FxLiquidPrimaryButton(
                      label: 'Carregar biblioteca',
                      icon: Icons.download_rounded,
                      onPressed: _importing ? null : _importar,
                      loading: _importing,
                      expand: false,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return switch (_step) {
      0 => WizardStepModalidades(
        selecionadas: _modalidades,
        onToggle: _toggleModalidade,
      ),
      1 => WizardStepEspacos(selecionados: _espacos, onToggle: _toggleEspaco),
      2 => FutureBuilder<Map<String, dynamic>>(
        future: _previewFuture,
        builder:
            (context, snapshot) => WizardStepConfirmacao(
              modalidades: _modalidades,
              espacos: _espacos,
              preview: snapshot,
            ),
      ),
      _ => const WizardStepLoading(),
    };
  }
}
