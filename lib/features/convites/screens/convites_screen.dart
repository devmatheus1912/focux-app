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
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
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
  Convite? _convite;
  var _personalNome = '';
  var _loading = true;
  var _generating = false;
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
    HapticFeedback.mediumImpact();
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final convite = await ref.read(conviteRepositoryProvider).gerar();
      if (!mounted) return;
      _applyConvite(convite, _personalNome);
      if (!mounted) return;
      setState(() => _fetchedAt = DateTime.now());
      AnalyticsService.instance.track(ProductEvents.convitesGenerated);
      HapticFeedback.lightImpact();
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
    final ativo = _convite != null && _shareLink.isNotEmpty;

    return fxScreenA11yScope(
      label: 'Convidar aluno',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Convidar aluno',
          subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
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
        body: _loading
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
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s4,
                        FxSettingsLayout.pageInset,
                        TokensStrip.s4,
                      ),
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
                            hint: 'Um uso. Some da área de transferência em 1 min.',
                            color: primary,
                            isDark: isDark,
                          ),
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
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: ativo ? 'Gerar novo link' : 'Gerar link',
                      loading: _generating,
                      loadingLabel: 'Gerando…',
                      onPressed: _generating ? null : _gerar,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
