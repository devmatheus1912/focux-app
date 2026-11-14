import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../dashboard/widgets/aluno_recurso_indisponivel.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';
import '../widgets/recorrencia_aluno_help_sheet.dart';
import '../../../core/theme/fx_icons.dart';

class RecorrenciaAlunoScreen extends ConsumerStatefulWidget {
  const RecorrenciaAlunoScreen({super.key});

  @override
  ConsumerState<RecorrenciaAlunoScreen> createState() =>
      _RecorrenciaAlunoScreenState();
}

class _RecorrenciaAlunoScreenState
    extends ConsumerState<RecorrenciaAlunoScreen> {
  RecorrenciaAssinatura? _assinatura;
  bool _loading = true;
  bool _mutando = false;
  String? _erro;

  /// Erro da última carga (decide entre o aviso de recurso e o erro comum).
  Object? _erroCarga;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
      _erroCarga = null;
    });
    try {
      final a =
          await RecorrenciaRepository(ref.read(apiClientProvider)).minha();
      if (mounted) {
        setState(() {
          _assinatura = a;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
          _erroCarga = e;
        });
      }
    }
  }

  Future<void> _autorizar() async {
    final link = _assinatura?.initPoint?.trim();
    if (link == null || link.isEmpty) return;
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, _mensagemDeErro(e));
    }
  }

  Future<void> _pausar() async {
    final ok = await showFxConfirmSheet(
      context,
      title: recorrenciaPausarConfirmTitle(),
      message: recorrenciaPausarConfirmMessage(),
      confirmLabel: recorrenciaAlunoStickyLabel(
        RecorrenciaAlunoStickyKind.pausar,
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _mutando = true);
    try {
      final a =
          await RecorrenciaRepository(ref.read(apiClientProvider)).pausarMinha();
      if (!mounted) return;
      setState(() {
        _assinatura = a;
        _fetchedAt = DateTime.now();
      });
      FeedbackHelper.showSuccess(context, 'Pagamento automático pausado.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, _mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _mutando = false);
    }
  }

  Future<void> _retomar() async {
    final ok = await showFxConfirmSheet(
      context,
      title: recorrenciaRetomarConfirmTitle(),
      message: recorrenciaRetomarConfirmMessage(),
      confirmLabel: recorrenciaAlunoStickyLabel(
        RecorrenciaAlunoStickyKind.retomar,
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _mutando = true);
    try {
      final a = await RecorrenciaRepository(
        ref.read(apiClientProvider),
      ).retomarMinha();
      if (!mounted) return;
      setState(() {
        _assinatura = a;
        _fetchedAt = DateTime.now();
      });
      FeedbackHelper.showSuccess(context, 'Pagamento automático retomado.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, _mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _mutando = false);
    }
  }

  void _leave() => safePopOrGo(context, '/dashboard/aluno');

  VoidCallback _stickyOnPressed(RecorrenciaAlunoStickyKind kind) {
    return switch (kind) {
      RecorrenciaAlunoStickyKind.autorizar => _autorizar,
      RecorrenciaAlunoStickyKind.pausar => _pausar,
      RecorrenciaAlunoStickyKind.retomar => _retomar,
      RecorrenciaAlunoStickyKind.chat => () => openAlunoRoute(context, '/chat/aluno'),
    };
  }

  /// Uma linha do cartão: rótulo à esquerda, valor à direita.
  Widget _linha(String rotulo, String valor) {
    final chrome = ShellChrome.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ),
          Text(valor, style: FocuxHubTypography.body(color: chrome.ink)),
        ],
      ),
    );
  }

  Widget _cartao(RecorrenciaAssinatura a) {
    final chrome = ShellChrome.of(context);
    final forma = recorrenciaFormaLabel(a.forma);
    final proxima = recorrenciaProximaValue(a.proximaCobranca);
    return FxStripCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recorrenciaAlunoStatusLabel(status: a.status, initPoint: a.initPoint),
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            '${recorrenciaValorLabel(a.valor)} por mês',
            style: FocuxHubTypography.metric(color: chrome.ink),
          ),
          if (proxima != '—') _linha('Próxima cobrança', proxima),
          if (forma != null) _linha('Forma', forma),
        ],
      ),
    );
  }

  String _mensagemDeErro(Object e) => alunoMensagemDeErro(
    ref,
    e,
    capability: 'recorrencia',
    fallbackNome: 'Pagamento automático',
  );

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final assinatura = _assinatura;
    final stickyKind = recorrenciaAlunoStickyKind(
      status: assinatura?.status,
      initPoint: assinatura?.initPoint,
    );
    final showSticky = !_loading && _erro == null;

    return fxScreenA11yScope(
      label: 'Pagamento automático',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Pagamento automático',
          subtitle: freshnessLabel,
          onBack: _leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funciona o pagamento automático',
              onTap: () => showRecorrenciaAlunoHelpSheet(context),
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 4),
                )
                : alunoBarradoPeloPlano(_erroCarga)
                ? const AlunoRecursoIndisponivelConteudo(
                  capability: 'recorrencia',
                  fallbackNome: 'Pagamento automático',
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  title: 'Não conseguimos carregar o pagamento automático',
                  message: _erro!,
                  onRetry: _load,
                )
                : Column(
                  children: [
                    Expanded(
                      child: FxContentWidthLimiter(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (assinatura == null)
                                FxEmptyState(
                                  icon: FxIcons.dinheiro,
                                  title: 'Sem pagamento automático',
                                  subtitle:
                                      'Seu personal ainda não ligou o pagamento automático.',
                                )
                              else
                                _cartao(assinatura),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showSticky)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3 +
                                MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: FxLiquidPrimaryButton(
                            label: recorrenciaAlunoStickyLabel(stickyKind),
                            loading: _mutando,
                            loadingLabel: 'Salvando…',
                            onPressed:
                                _mutando ? null : _stickyOnPressed(stickyKind),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
