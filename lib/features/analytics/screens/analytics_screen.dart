import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/analytics_repository.dart';
import '../providers/analytics_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';

part 'analytics_screen_widgets.part.dart';


class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final async = ref.watch(analyticsDashboardProvider);

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Analytics',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: FxContentWidthLimiter(
        child: async.when(
          loading: () => Center(child: FxLoading(color: primary)),
          error:
              (e, _) => DashboardErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(analyticsDashboardProvider),
              ),
          data:
              (data) => RefreshIndicator(
                color: primary,
                onRefresh:
                    () async => ref.invalidate(analyticsDashboardProvider),
                child: _AnalyticsBody(data: data, dark: dark),
              ),
        ),
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
