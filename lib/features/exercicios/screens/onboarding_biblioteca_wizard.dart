import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_wizard_chrome.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/biblioteca_wizard_draft.dart';
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

  @override
  void initState() {
    super.initState();
    final draft = BibliotecaWizardDraftCache.get();
    if (draft == null) return;
    _step = draft.step >= bibliotecaWizardVisibleSteps ? 2 : draft.step;
    _modalidades
      ..clear()
      ..addAll(draft.modalidades);
    _espacos
      ..clear()
      ..addAll(draft.espacos);
    if (_step >= 2) {
      _previewFuture = ref
          .read(exercicioRepositoryProvider)
          .previewCuratedV2(modalidades: _modalidades, espacos: _espacos);
    }
  }

  void _persistDraft() {
    if (_importing) return;
    BibliotecaWizardDraftCache.put(
      BibliotecaWizardDraft(
        step: _step >= bibliotecaWizardVisibleSteps ? 2 : _step,
        modalidades: Set<Modalidade>.of(_modalidades),
        espacos: Set<Espaco>.of(_espacos),
      ),
    );
  }

  void _toggleModalidade(Modalidade value) {
    setState(() {
      _modalidades.contains(value)
          ? _modalidades.remove(value)
          : _modalidades.add(value);
    });
    _persistDraft();
  }

  void _toggleEspaco(Espaco value) {
    setState(() {
      _espacos.contains(value) ? _espacos.remove(value) : _espacos.add(value);
    });
    _persistDraft();
  }

  Future<void> _pular() async {
    if (_importing) return;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Sair da biblioteca?',
      message: 'Dá para retomar depois. O que você já escolheu fica salvo.',
      confirmLabel: 'Sair',
    );
    if (!ok || !mounted) return;
    AnalyticsService.instance.track('wizard_skipped');
    safePopOrGo(context, '/exercicios');
  }

  Future<void> _onLeave() async {
    if (_importing) return;
    if (_step > 0) {
      _voltar();
      return;
    }
    await _pular();
  }

  void _voltar() {
    if (_importing || _step <= 0) return;
    setState(() => _step -= 1);
    _persistDraft();
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
    _persistDraft();
  }

  Future<void> _importar() async {
    setState(() => _importing = true);
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
      BibliotecaWizardDraftCache.clear();
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        bibliotecaImportSuccess(result.importados),
      );
      safePopOrGo(context, '/exercicios');
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      _persistDraft();
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

  void _abrirAjuda() {
    showFxHelpSheet(
      context,
      title: bibliotecaHelpTitle(),
      subtitle: bibliotecaHelpSubtitle(),
      tips: [
        FxHelpTip('Etapas', bibliotecaHelpPassosBody(), icon: 'route'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final canGoNext =
        (_step == 0 && _modalidades.isNotEmpty) ||
        (_step == 1 && _espacos.isNotEmpty) ||
        _step >= 2;
    return FxWizardPopGuard(
      onLeave: _onLeave,
      child: fxScreenA11yScope(
      label: 'Biblioteca curada',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Biblioteca curada',
          subtitle: bibliotecaEtapaLabel(_step),
          leadingWidth: 88,
          leading: TextButton(
            onPressed: _importing ? null : _pular,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(bibliotecaPularLabel()),
          ),
          actions: [
            FxHelpIconButton(
              tooltip: bibliotecaHelpTitle(),
              onTap: _abrirAjuda,
            ),
          ],
        ),
        bottomNavigationBar: FxWizardStickyBar(
          secondary:
              _step > 0
                  ? TextButton(
                    onPressed: _importing ? null : _voltar,
                    child: Text(bibliotecaVoltarLabel()),
                  )
                  : null,
          primary: FxLiquidPrimaryButton(
            label: bibliotecaContinueLabel(step: _step),
            loading: _importing,
            loadingLabel: 'Carregando…',
            onPressed:
                _importing
                    ? null
                    : _step < 2
                    ? (canGoNext ? _next : null)
                    : _importar,
          ),
        ),
        body: FxContentWidthLimiter(
          child: BibliotecaWizardPagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bibliotecaQuestionTitle(_step),
                  style: FocuxHubTypography.sectionTitle(
                    context,
                    color: chrome.ink,
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  bibliotecaQuestionCaption(_step),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                const SizedBox(height: FxSettingsLayout.headerToGroup),
                Expanded(
                  child: SingleChildScrollView(child: _content()),
                ),
              ],
            ),
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
                snapshot.data ??
                const CuratedBibliotecaPreview(totalCandidatos: 0),
          );
        },
      ),
      _ => const SkeletonList(count: 4),
    };
  }
}
