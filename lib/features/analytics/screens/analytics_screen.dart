import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/analytics_repository.dart';
import '../providers/analytics_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';

part 'analytics_screen_widgets.part.dart';


class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final async = ref.watch(analyticsDashboardProvider);

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Analytics',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: async.when(
        loading: () => Center(child: FxLoading(color: primary)),
        error:
            (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: EagleTokens.bad,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar analytics',
                    style: TextStyle(
                      color: dark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friendlyError(e),
                    style: TextStyle(
                      color:
                          dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FxLiquidPrimaryButton(
                    label: 'Tentar novamente',
                    icon: Icons.refresh,
                    expand: false,
                    onPressed:
                        () => ref.invalidate(analyticsDashboardProvider),
                  ),
                ],
              ),
            ),
        data:
            (data) => RefreshIndicator(
              color: primary,
              onRefresh: () async => ref.invalidate(analyticsDashboardProvider),
              child: _AnalyticsBody(data: data, dark: dark),
            ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

