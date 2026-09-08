import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/anamnese_repository.dart';
import '../providers/anamnese_provider.dart';
import '../utils/anamnese_display.dart';
import '../utils/anamnese_pdf.dart';
import '../widgets/anamnese_help_sheet.dart';

part 'anamnese_screen_ficha.part.dart';

/// S3 — Personal solicita e revisa. Não edita PAR-Q/saúde do aluno.
class AnamneseScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AnamneseScreen({super.key, required this.alunoId});

  @override
  ConsumerState<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends ConsumerState<AnamneseScreen> {
  Anamnese? _anamnese;
  bool _loading = true;
  bool _acting = false;
  String? _erro;
  DateTime? _fetchedAt;

  AnamneseRepository get _repo =>
      AnamneseRepository(ref.read(apiClientProvider));

  void _voltar() => safePopOrGo(context, '/alunos/${widget.alunoId}');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }
    try {
      final a = await _repo.buscar(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _anamnese = a;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final semFicha = e is DioException && e.response?.statusCode == 404;
      if (semFicha) {
        setState(() {
          _anamnese = Anamnese();
          _fetchedAt = DateTime.now();
          _loading = false;
        });
      } else {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportarPdf() async {
    final a = _anamnese;
    if (a == null) return;
    await exportAnamnesePdf(AnamnesePdfSnapshot(anamnese: a));
  }

  Future<void> _solicitar() async {
    HapticFeedback.mediumImpact();
    setState(() => _acting = true);
    try {
      final a = await _repo.solicitar(widget.alunoId);
      if (!mounted) return;
      ref.invalidate(alunoAnamneseProvider(widget.alunoId));
      setState(() => _anamnese = a);
      FeedbackHelper.showSuccess(context, 'Anamnese solicitada ao aluno.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _revisar({
    required String status,
    required String title,
    required String confirmLabel,
    String? subtitle,
    bool pedirAtestado = false,
  }) async {
    final notasCtrl = TextEditingController(
      text: _anamnese?.notasProfissional ?? '',
    );
    final atestadoCtrl = TextEditingController(
      text: _anamnese?.atestadoObs ?? '',
    );
    final ok = await showFxFormSheet(
      context,
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      icon: Icons.fact_check_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AlunoInsetFormField(
            controller: notasCtrl,
            label: 'Notas do profissional',
            icon: Icons.sticky_note_2_outlined,
            maxLines: 4,
            showDivider: pedirAtestado,
          ),
          if (pedirAtestado)
            AlunoInsetFormField(
              controller: atestadoCtrl,
              label: 'Observação do atestado',
              icon: Icons.medical_information_outlined,
              maxLines: 3,
              showDivider: false,
            ),
        ],
      ),
    );
    if (!ok || !mounted) {
      notasCtrl.dispose();
      atestadoCtrl.dispose();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _acting = true);
    try {
      final a = await _repo.revisar(
        widget.alunoId,
        AnamneseRevisaoRequest(
          status: status,
          notasProfissional: notasCtrl.text.trim(),
          atestadoObs: pedirAtestado ? atestadoCtrl.text.trim() : null,
        ),
      );
      if (!mounted) return;
      ref.invalidate(alunoAnamneseProvider(widget.alunoId));
      setState(() => _anamnese = a);
      FeedbackHelper.showSuccess(
        context,
        status == AnamneseStatus.revisada
            ? 'Anamnese marcada como revisada.'
            : status == AnamneseStatus.precisaAtestado
            ? 'Atestado solicitado ao aluno.'
            : 'Atualização solicitada ao aluno.',
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      notasCtrl.dispose();
      atestadoCtrl.dispose();
      if (mounted) setState(() => _acting = false);
    }
  }

  String? get _primaryCtaLabel {
    final a = _anamnese;
    if (a == null) return null;
    if (a.isNaoIniciada || a.isSolicitada) return 'Solicitar anamnese';
    if (a.isPreenchida || a.isPrecisaAtestado) return 'Marcar revisada';
    if (a.isRevisada) return 'Pedir atualização';
    return null;
  }

  VoidCallback? get _primaryCtaAction {
    final a = _anamnese;
    if (a == null || _acting) return null;
    if (a.isNaoIniciada || a.isSolicitada) return _solicitar;
    if (a.isPreenchida || a.isPrecisaAtestado) {
      return () => _revisar(
        status: AnamneseStatus.revisada,
        title: 'Marcar como revisada',
        subtitle: 'Registre notas para o acompanhamento.',
        confirmLabel: 'Marcar revisada',
      );
    }
    if (a.isRevisada) {
      return () => _revisar(
        status: AnamneseStatus.solicitada,
        title: 'Pedir atualização',
        subtitle: 'O aluno será notificado para atualizar a ficha.',
        confirmLabel: 'Pedir atualização',
      );
    }
    return null;
  }

  List<Widget> get _appBarActions {
    final a = _anamnese;
    return [
      FxHelpIconButton(
        tooltip: 'Como usar a anamnese',
        onTap: () => showAnamneseHelpSheet(context),
      ),
      if (a?.personalPodeRevisar == true)
        ShellHeaderIconButton(
          icon: 'article',
          tooltip: 'Exportar PDF',
          onTap: _exportarPdf,
        ),
    ];
  }

  FxShellAppBar get _appBar => FxShellAppBar(
    title: 'Anamnese',
    subtitle:
        FxHubFreshness.fromFetchedAt(_fetchedAt) ??
        'Solicite e revise a ficha do aluno',
    onBack: _voltar,
    actions: _appBarActions,
  );

  Widget _page({required Widget body, Widget? bottom}) {
    return fxScreenA11yScope(
      label: 'Anamnese',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _voltar();
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: _appBar,
          bottomNavigationBar: bottom,
          body: body,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;

    if (_loading) {
      return _page(body: const SkeletonList(count: 5));
    }
    if (_erro != null) {
      return _page(
        body: FxErrorState(
          chromeOnDark: isDark,
          primary: primary,
          message: _erro!,
          onRetry: _load,
          title: 'Não conseguimos carregar a anamnese',
        ),
      );
    }

    final a = _anamnese!;
    final ctaLabel = _primaryCtaLabel;
    final ctaAction = _primaryCtaAction;

    return _page(
      bottom:
          ctaLabel == null
              ? null
              : SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: !_acting,
                    label: ctaLabel,
                    child: FxLiquidPrimaryButton(
                      label: ctaLabel,
                      loading: _acting,
                      loadingLabel: 'Salvando…',
                      onPressed: ctaAction,
                    ),
                  ),
                ),
              ),
      body: SafeArea(
        bottom: false,
        child: FxContentWidthLimiter(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s4,
                FxSettingsLayout.pageInset,
                24,
              ),
              children: [
                FxHubHeader(
                  title: anamneseStatusLabel(a.status),
                  subtitle: anamneseStatusSubtitle(a.status),
                ),
                _AnamneseBody(
                  anamnese: a,
                  acting: _acting,
                  isDark: isDark,
                  primary: primary,
                  alunoId: widget.alunoId,
                  onSolicitar: _solicitar,
                  onRevisar: _revisar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
