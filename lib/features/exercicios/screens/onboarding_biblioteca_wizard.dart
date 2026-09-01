import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/enums.dart';
import '../models/curated_biblioteca.dart';
import '../providers/exercicios_provider.dart';
import '../utils/biblioteca_wizard_display.dart';
import 'widgets/biblioteca_wizard_steps.dart';

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
  Future<CuratedBibliotecaPreview>? _previewFuture;
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

  void _pular() {
    if (_importing) return;
    AnalyticsService.instance.track('wizard_skipped');
    context.pop(false);
  }

  void _voltar() {
    if (_importing || _step <= 0) return;
    setState(() => _step -= 1);
  }

  void _next() {
    if (_step == 0 && _modalidades.isEmpty) {
      FeedbackHelper.showWarn(context, 'Escolha pelo menos uma modalidade.');
      return;
    }
    if (_step == 1 && _espacos.isEmpty) {
      FeedbackHelper.showWarn(context, 'Escolha pelo menos um espaço.');
      return;
    }
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
      AnalyticsService.instance.track(
        'wizard_completed',
        props: {
          'modalidades': _modalidades.map((e) => e.backendName).toList(),
          'espacos': _espacos.map((e) => e.backendName).toList(),
          'importados': result.importados,
        },
      );
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        bibliotecaImportSuccess(result.importados),
      );
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

  void _retryPreview() {
    setState(() {
      _previewFuture = ref
          .read(exercicioRepositoryProvider)
          .previewCuratedV2(modalidades: _modalidades, espacos: _espacos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canGoNext =
        (_step == 0 && _modalidades.isNotEmpty) ||
        (_step == 1 && _espacos.isNotEmpty);

    return fxScreenA11yScope(
      label: 'Biblioteca curada',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Biblioteca curada',
          subtitle: 'Monte sua base de exercícios em minutos',
          onBack: _importing ? () {} : _pular,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s3),
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Pular',
                  child: ShellHeaderIconButton(
                    icon: 'x',
                    tooltip: 'Pular',
                    onTap: _pular,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child: BibliotecaWizardPagePadding(
            child: Column(
              children: [
                BibliotecaWizardProgress(step: _step),
                const SizedBox(height: FxSettingsLayout.headerToGroup),
                Expanded(
                  child: SingleChildScrollView(child: _content()),
                ),
                BibliotecaWizardActions(
                  step: _step,
                  canContinue: canGoNext,
                  importing: _importing,
                  onBack: _voltar,
                  onContinue: _next,
                  onImport: _importar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return switch (_step) {
      0 => WizardStepModalidades(
        selecionadas: _modalidades,
        onToggle: _toggleModalidade,
      ),
      1 => WizardStepEspacos(selecionados: _espacos, onToggle: _toggleEspaco),
      2 => FutureBuilder<CuratedBibliotecaPreview>(
        future: _previewFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(count: 3);
          }
          if (snapshot.hasError) {
            return FxErrorState(
              chromeOnDark: chrome.isDark,
              primary: primary,
              title: 'Não conseguimos calcular a biblioteca',
              message: friendlyError(snapshot.error!),
              onRetry: _retryPreview,
            );
          }
          return WizardStepConfirmacao(
            modalidades: _modalidades,
            espacos: _espacos,
            preview:
                snapshot.data ?? const CuratedBibliotecaPreview(totalCandidatos: 0),
          );
        },
      ),
      _ => const SkeletonList(count: 4),
    };
  }
}
