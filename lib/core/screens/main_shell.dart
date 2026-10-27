import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../platform/focux_platform.dart';
import '../theme/focux_system_chrome.dart';
import '../widgets/cinematic_mesh_background.dart';
import '../widgets/fx_dock.dart';
import '../widgets/mesh_scope.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../l10n/app_localizations.dart';

/// Shell scaffold wrapping the 5 main personal-trainer tabs.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = FocuxPlatform.safeBottomInset(context);
    final compact = FocuxPlatform.isCompact(context);
    final dockClearance = FxDock.shellClearance(
      bottomInset: bottomInset,
      compact: compact,
    );

    final emRisco = ref.watch(
      dashboardHomeProvider.select(
        (async) => async.value?.commandCenter.alunosEmRisco.length ?? 0,
      ),
    );
    final agendaHoje = ref.watch(
      dashboardHomeProvider.select(
        (async) => async.value?.commandCenter.agendaHojeCount ?? 0,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: FocuxSystemChrome.forDark(isDark),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: MeshScope(
          active: true,
          child: CinematicMeshBackground(
            showCenterGlow: false,
            showCornerGlow: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: dockClearance),
                  child: navigationShell,
                ),
                Positioned(
                  bottom: bottomInset + FxDock.floatGap,
                  left: FxDock.sideInset,
                  right: FxDock.sideInset,
                  child: FxDock(
                    items: FxDockItems.personal(
                      S.of(context),
                      alunosEmRisco: emRisco,
                      agendaHoje: agendaHoje,
                    ),
                    currentIndex: navigationShell.currentIndex,
                    cinematicChrome: true,
                    isDark: isDark,
                    onTap:
                        (i) => navigationShell.goBranch(
                          i,
                          initialLocation: i == navigationShell.currentIndex,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
