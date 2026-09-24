import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/convite_repository.dart';
import '../providers/convite_provider.dart';
import '../utils/convite_display.dart';
import '../widgets/convites_help_sheet.dart';

class ConvitesScreen extends ConsumerStatefulWidget {
  const ConvitesScreen({super.key});

  @override
  ConsumerState<ConvitesScreen> createState() => _ConvitesScreenState();
}

class _ConvitesScreenState extends ConsumerState<ConvitesScreen> {
  final _openedAt = DateTime.now();
  final _emailCtrl = TextEditingController();
  Convite? _convite;
  var _personalNome = '';
  var _loading = true;
  var _generating = false;
  var _revoking = false;
  String? _error;
  DateTime? _fetchedAt;
  Timer? _countdownTimer;
  var _viewTracked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(conviteRepositoryProvider).getHome();
      if (!mounted) return;
      _applyConvite(home.convite, home.personalNome);
      setState(() {
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackView();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(
          e,
          fallback: 'Não conseguimos abrir os convites. Tente novamente.',
        );
        _loading = false;
      });
    }
  }

  void _trackView() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.convitesHubViewed,
      props: {'tem_link': _convite != null},
    );
    AnalyticsService.instance.track(
      ProductEvents.convitesHubTtv,
      props: {'ms': DateTime.now().difference(_openedAt).inMilliseconds},
    );
  }

  void _applyConvite(Convite? convite, String personalNome) {
    _countdownTimer?.cancel();
    _personalNome = personalNome;
    final now = DateTime.now();
    if (convite != null && conviteAindaValido(convite.expiraEm, now)) {
      _convite = convite;
      _startCountdown(convite.expiraEm!);
    } else {
      _convite = null;
    }
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    void tick() {
      if (!mounted) return;
      final left = expiresAt.difference(DateTime.now());
      if (left.isNegative) {
        _countdownTimer?.cancel();
        setState(() => _convite = null);
        return;
      }
      setState(() {});
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _gerar() async {
    if (_generating) return;
    final emailErro = conviteEmailInvalido(_emailCtrl.text);
    if (emailErro != null) {
      setState(() => _error = emailErro);
      return;
    }
    if (_convite != null) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Gerar novo link?',
        message: 'O link atual deixa de valer na hora.',
        icon: Icons.link_off_outlined,
        confirmLabel: 'Gerar novo',
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final substituiu = _convite != null;
      final convite = await ref
          .read(conviteRepositoryProvider)
          .gerar(email: _emailCtrl.text);
      if (!mounted) return;
      _emailCtrl.clear();
      _applyConvite(convite, _personalNome);
      if (!mounted) return;
      setState(() => _fetchedAt = DateTime.now());
      AnalyticsService.instance.track(ProductEvents.convitesGenerated);
      HapticFeedback.lightImpact();
      FeedbackHelper.showSuccess(
        context,
        conviteGeradoLabel(substituiu: substituiu),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(
          e,
          fallback: 'Não conseguimos gerar o convite. Tente novamente.',
        );
      });
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _revogar() async {
    if (_revoking || _convite == null) return;
    final ok = await showFxConfirmSheet(
      context,
      title: 'Revogar link?',
      message:
          'Quem ainda não usou deixa de conseguir entrar com este convite.',
      icon: Icons.link_off_outlined,
      confirmLabel: 'Revogar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _revoking = true;
      _error = null;
    });
    try {
      await ref.read(conviteRepositoryProvider).revogar();
      if (!mounted) return;
      _countdownTimer?.cancel();
      setState(() {
        _convite = null;
        _revoking = false;
        _fetchedAt = DateTime.now();
      });
      FeedbackHelper.showSuccess(context, 'Link revogado.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _revoking = false;
        _error = friendlyError(
          e,
          fallback: 'Não revogou o convite. Tente novamente.',
        );
      });
    }
  }

  String get _shareLink => _convite?.shareLink ?? '';

  Future<void> _copiar() async {
    if (_shareLink.isEmpty) return;
    HapticFeedback.selectionClick();
    await copySensitiveToClipboard(_shareLink);
    if (!mounted) return;
    AnalyticsService.instance.track(ProductEvents.convitesCopied);
    FeedbackHelper.showSuccess(context, 'Link copiado. Some em 1 min.');
  }

  Future<void> _compartilharWhatsApp() async {
    if (_shareLink.isEmpty) return;
    HapticFeedback.selectionClick();
    AnalyticsService.instance.track(ProductEvents.convitesWhatsapp);
    final texto = conviteShareMessage(
      personalNome: _personalNome,
      shareLink: _shareLink,
    );
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(texto)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ativo = _convite != null;
    final linkVisivel = _shareLink.isNotEmpty;

    return fxScreenA11yScope(
      label: 'Convidar aluno',
      child: PopScope(
        canPop: MediaQuery.viewInsetsOf(context).bottom == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Convidar aluno',
            subtitle: FxHubFreshness.joinCount(
              conviteCountLabel(ativo: ativo),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/dashboard/personal');
            },
            actions: [
              FxHelpIconButton(
                tooltip: 'Como convidar',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.convitesHubHelpOpened,
                  );
                  showConvitesHelpSheet(context);
                },
              ),
            ],
          ),
          body:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 6),
                  )
                  : _error != null && _fetchedAt == null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: 'Não conseguimos abrir o convite',
                    message: _error!,
                    onRetry: _load,
                  )
                  : Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          color: primary,
                          onRefresh: _load,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                            ),
                            itemCount: 1,
                            itemBuilder: (context, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (!ativo)
                                    SizedBox(
                                      height: 280,
                                      child: FxEmptyState(
                                        icon: 'users',
                                        title: 'Nenhum convite ativo',
                                        subtitle:
                                            'Gere um link de um uso. O aluno cria a conta e troca a senha no primeiro acesso.',
                                      ),
                                    )
                                  else ...[
                                    OperationalMetricTile(
                                      label: 'Link vigente',
                                      value: conviteRemainingLabel(
                                        _convite!.expiraEm,
                                        DateTime.now(),
                                      ),
                                      hint: conviteVigenteHint(
                                        linkVisivel: linkVisivel,
                                        email: _convite!.email,
                                      ),
                                      color: primary,
                                      isDark: isDark,
                                    ),
                                    if (linkVisivel) ...[
                                      const SizedBox(height: TokensStrip.s4),
                                      Wrap(
                                        spacing: TokensStrip.s2,
                                        runSpacing: TokensStrip.s2,
                                        children: [
                                          DashboardHomeActionChip(
                                            label: 'Copiar',
                                            accent: primary,
                                            isDark: isDark,
                                            onPressed: _copiar,
                                          ),
                                          DashboardHomeActionChip(
                                            label: 'WhatsApp',
                                            accent: primary,
                                            isDark: isDark,
                                            onPressed: _compartilharWhatsApp,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: TokensStrip.s4),
                                  TextField(
                                    controller: _emailCtrl,
                                    enabled: !_generating,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    textInputAction: TextInputAction.done,
                                    decoration: FxInputDeco.build(
                                      context,
                                      conviteEmailLabel,
                                      icon: Icons.alternate_email_rounded,
                                      hint: conviteEmailHint,
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: TokensStrip.s4),
                                    FxErrorState(
                                      chromeOnDark: isDark,
                                      primary: primary,
                                      title: 'Não gerou',
                                      message: _error!,
                                      onRetry: _gerar,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ativo)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: TokensStrip.s2,
                                  ),
                                  child: TextButton(
                                    onPressed:
                                        _revoking || _generating
                                            ? null
                                            : _revogar,
                                    child: Text(
                                      _revoking ? 'Revogando…' : 'Revogar link',
                                    ),
                                  ),
                                ),
                              FxLiquidPrimaryButton(
                                label: ativo ? 'Gerar novo link' : 'Gerar link',
                                loading: _generating,
                                loadingLabel: 'Gerando…',
                                onPressed:
                                    _generating || _revoking ? null : _gerar,
                              ),
                            ],
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
