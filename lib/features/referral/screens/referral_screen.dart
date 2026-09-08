import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
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
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/referral_repository.dart';
import '../utils/referral_display.dart';
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _share() async {
    final info = _info;
    if (info == null) return;
    HapticFeedback.selectionClick();
    final text = referralInviteText(
      codigo: info.codigo,
      link: info.linkCompartilhamento,
    );
    await AnalyticsService.instance.track(ProductEvents.referralLinkShared);
    await copySensitiveToClipboard(text);
    if (!mounted) return;
    FeedbackHelper.showSuccess(
      context,
      'Convite copiado. Some da área de transferência em 1 min.',
    );
  }

  Future<void> _copiarLink() async {
    final link = _info?.linkCompartilhamento ?? '';
    if (!referralTemLink(link)) return;
    HapticFeedback.selectionClick();
    await copySensitiveToClipboard(link.trim());
    if (!mounted) return;
    FeedbackHelper.showSuccess(
      context,
      'Link copiado. Some da área de transferência em 1 min.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Indique e ganhe',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Indique e ganhe',
          subtitle: referralHubSubtitle(
            FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: () => safePopOrGo(context, '/perfil'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como indicar e ganhar',
              onTap: () => showReferralHelpSheet(context),
            ),
          ],
        ),
        body: _loading
            ? const SkeletonList(count: 4)
            : _erro != null
            ? FxErrorState(
              chromeOnDark: chrome.isDark,
              primary: primary,
              message: _erro!,
              onRetry: _load,
              title: 'Não conseguimos carregar a indicação',
            )
            : RefreshIndicator(
              color: primary,
              onRefresh: _load,
              child: _info == null ||
                      referralCodigoLabel(_info!.codigo) == '—'
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 48),
                      FxEmptyState(
                        icon: 'users',
                        title: 'Código ainda não disponível',
                        subtitle:
                            'Puxe para atualizar. O servidor cria o código no primeiro acesso.',
                        action: FxEmptyAction(
                          label: 'Tentar de novo',
                          onTap: _load,
                        ),
                      ),
                    ],
                  )
                  : FxContentWidthLimiter(
                    child: _ReferralBody(
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

class _ReferralBody extends StatelessWidget {
  const _ReferralBody({
    required this.info,
    required this.isDark,
    required this.onShare,
    required this.onCopyLink,
  });

  final ReferralInfo info;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final codigo = referralCodigoLabel(info.codigo);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        FxStripCard(
          emphasize: true,
          semanticsLabel: 'Código $codigo',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seu código', style: FocuxHubTypography.chip(chrome.mute)),
              const SizedBox(height: 6),
              Text(
                codigo,
                style: FocuxHubTypography.kpi(
                  color: chrome.ink,
                  fontSize: FocuxHubTypography.metricLg,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '30 dias extras no plano de quem indicar',
                style: FocuxHubTypography.body(
                  color: chrome.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: TokensStrip.s3),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  DashboardHomeActionChip(
                    label: 'Copiar convite',
                    accent: primary,
                    isDark: isDark,
                    onPressed: onShare,
                  ),
                  if (referralTemLink(info.linkCompartilhamento))
                    DashboardHomeActionChip(
                      label: 'Só o link',
                      accent: primary,
                      isDark: isDark,
                      onPressed: onCopyLink,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        OperationalMetricTile(
          label: 'Conversões',
          value: '${info.usosTotais}',
          hint: referralUsosLabel(info.usosTotais),
          color: primary,
          isDark: isDark,
        ),
      ],
    );
  }
}
