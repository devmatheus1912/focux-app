import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../data/referral_repository.dart';
import '../utils/referral_display.dart';
import '../widgets/referral_body.dart';
import '../widgets/referral_help_sheet.dart';

final referralRepositoryProvider = Provider(
  (ref) => ReferralRepository(ref.read(apiClientProvider)),
);

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  ReferralInfo? _info;
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load(primeiraCarga: true);
  }

  Future<void> _load({bool primeiraCarga = false}) async {
    setState(() {
      _loading = _info == null;
      _erro = null;
    });
    try {
      final info = await ref.read(referralRepositoryProvider).getInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      if (primeiraCarga) {
        AnalyticsService.instance.track(
          ProductEvents.referralViewed,
          props: {
            'campanha_ativa': info.campanhaAtiva,
            'limite_atingido': info.limiteAtingido,
            'indicacoes': info.indicacoes.length,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      AnalyticsService.instance.track(ProductEvents.referralLoadFailed);
      final mensagem = friendlyError(e);
      setState(() {
        _loading = false;
        _erro = mensagem;
      });
      if (_info != null) FeedbackHelper.showError(context, mensagem);
    }
  }

  Future<void> _share() async {
    final info = _info;
    if (info == null) return;
    final l10n = S.of(context);
    HapticFeedback.selectionClick();
    await AnalyticsService.instance.track(ProductEvents.referralLinkShared);
    await copySensitiveToClipboard(referralInviteText(l10n, info));
    if (!mounted) return;
    FeedbackHelper.showSuccess(context, l10n.referralInviteCopied);
  }

  Future<void> _copiarLink() async {
    final link = _info?.linkCompartilhamento ?? '';
    if (!referralTemLink(link)) return;
    final l10n = S.of(context);
    HapticFeedback.selectionClick();
    await AnalyticsService.instance.track(ProductEvents.referralLinkCopied);
    await copySensitiveToClipboard(link.trim());
    if (!mounted) return;
    FeedbackHelper.showSuccess(context, l10n.referralLinkCopied);
  }

  void _abrirAjuda() {
    AnalyticsService.instance.track(ProductEvents.referralHelpOpened);
    showReferralHelpSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: l10n.referralTitle,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: l10n.referralTitle,
          subtitle: referralHubSubtitle(
            l10n,
            _info,
            FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: () => safePopOrGo(context, '/perfil'),
          actions: [
            FxHelpIconButton(
              tooltip: l10n.referralHelpTooltip,
              onTap: _abrirAjuda,
            ),
          ],
        ),
        body: _loading
            ? const SkeletonList(count: 4)
            : _erro != null && _info == null
            ? FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                message: _erro!,
                onRetry: _load,
                title: l10n.referralLoadErrorTitle,
              )
            : RefreshIndicator(
                color: primary,
                onRefresh: _load,
                child: _info == null || referralCodigoLabel(_info!.codigo) == '—'
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 48),
                          FxEmptyState(
                            icon: 'users',
                            title: l10n.referralNoCodeTitle,
                            subtitle: l10n.referralNoCodeSubtitle,
                            action: FxEmptyAction(
                              label: l10n.referralTryAgain,
                              onTap: _load,
                            ),
                          ),
                        ],
                      )
                    : FxContentWidthLimiter(
                        child: ReferralBody(
                          info: _info!,
                          isDark: chrome.isDark,
                          onShare: _share,
                          onCopyLink: _copiarLink,
                        ),
                      ),
              ),
      ),
    );
  }
}
