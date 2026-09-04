import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
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
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
      if (mounted) {
        setState(() {
          _info = info;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
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
    await AnalyticsService.instance.track('referral_link_shared');
    await copySensitiveToClipboard(text);
    if (mounted) {
      FeedbackHelper.showSuccess(
        context,
        'Convite copiado. Some da área de transferência em 1 min.',
      );
    }
  }

  Future<void> _copiarLink() async {
    final link = _info?.linkCompartilhamento ?? '';
    if (!referralTemLink(link)) return;
    HapticFeedback.selectionClick();
    await copySensitiveToClipboard(link.trim());
    if (mounted) {
      FeedbackHelper.showSuccess(
        context,
        'Link copiado. Some da área de transferência em 1 min.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Indique e ganhe',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Indique e ganhe',
          subtitle: referralHubSubtitle(freshness),
          onBack: () => safePopOrGo(context, '/perfil'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como indicar e ganhar',
              onTap: () => showReferralHelpSheet(context),
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 4),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                  title: 'Não conseguimos carregar a indicação',
                )
                : FxContentWidthLimiter(
                  child: _buildBody(
                    isDark: chrome.isDark,
                    primary: primary,
                    freshness: freshness,
                  ),
                ),
      ),
    );
  }

  Widget _buildBody({
    required bool isDark,
    required Color primary,
    required String? freshness,
  }) {
    final info = _info;
    if (info == null || referralCodigoLabel(info.codigo) == '—') {
      return Column(
        children: [
          Expanded(
            child: RefreshIndicator(
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
                  FxHubHeader(
                    title: 'Seu convite',
                    subtitle: referralHubSubtitle(freshness),
                  ),
                  const SizedBox(height: TokensStrip.s4),
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
                TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: FxLiquidPrimaryButton(
                label: 'Tentar de novo',
                onPressed: _load,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
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
                FxHubHeader(
                  title: referralCodigoLabel(info.codigo),
                  subtitle: referralHeaderSubtitle(
                    usos: info.usosTotais,
                    freshness: freshness,
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
                const SizedBox(height: TokensStrip.s4),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    DashboardHomeActionChip(
                      label: 'Só o link',
                      accent: primary,
                      isDark: isDark,
                      onPressed: _copiarLink,
                    ),
                  ],
                ),
              ],
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
              TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: FxLiquidPrimaryButton(
              label: 'Copiar convite',
              onPressed: _share,
            ),
          ),
        ),
      ],
    );
  }
}
