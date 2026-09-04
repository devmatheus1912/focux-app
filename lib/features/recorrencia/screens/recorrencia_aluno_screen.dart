import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';
import '../widgets/recorrencia_aluno_help_sheet.dart';

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
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final assinatura = _assinatura;
    final podeAutorizar = recorrenciaTemLinkCheckout(
      assinatura?.status ?? '',
      assinatura?.initPoint,
    );

    return fxScreenA11yScope(
      label: 'Minha assinatura',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Assinatura',
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar sua assinatura',
              onTap: () => showRecorrenciaAlunoHelpSheet(context),
            ),
          ],
        ),
        body:
            _loading
                ? const SkeletonList(count: 4)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  title: 'Não conseguimos carregar sua assinatura',
                  message: _erro!,
                  onRetry: _load,
                )
                : Column(
                  children: [
                    Expanded(
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
                              const Padding(
                                padding: EdgeInsets.only(top: 48),
                                child: FxEmptyState(
                                  icon: 'coin',
                                  title: 'Sem assinatura recorrente ainda',
                                  subtitle:
                                      'Seu personal ainda não configurou cobrança automática mensal.',
                                ),
                              )
                            else ...[
                              FxHubHeader(
                                title: recorrenciaStatusLabel(
                                  assinatura.status,
                                ),
                                freshnessLabel: freshnessLabel,
                                subtitle:
                                    assinatura.proximaCobranca == null
                                        ? 'Cobrança mensal'
                                        : 'Próxima: ${assinatura.proximaCobranca}',
                              ),
                              const SizedBox(height: TokensStrip.s4),
                              OperationalMetricTile(
                                label: 'Valor mensal',
                                value: assinatura.valor.format(),
                                hint: 'Mercado Pago',
                                color: primary,
                                isDark: isDark,
                              ),
                              if (assinatura.proximaCobranca != null) ...[
                                const SizedBox(height: TokensStrip.s3),
                                Text(
                                  'A cobrança seguinte entra em ${assinatura.proximaCobranca}.',
                                  style: FocuxHubTypography.bodyMuted(
                                    color: fxScreenMute(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (podeAutorizar)
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
                            label: 'Autorizar pagamento',
                            onPressed: _autorizar,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
