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

class AlunoShell extends ConsumerWidget {
  const AlunoShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Índice do tab Chat em [FxDockItems.aluno] — conversa full-screen sem dock.
  static const int chatTabIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = FocuxPlatform.safeBottomInset(context);
    final compact = FocuxPlatform.isCompact(context);
    final onChat = navigationShell.currentIndex == chatTabIndex;
    // Conversa full-screen: sem dock; SafeArea do ConversationScreen cobre o inset.
    final dockClearance =
        onChat
            ? 0.0
            : FxDock.shellClearance(
              bottomInset: bottomInset,
              compact: compact,
            );
    final chatUnread = ref.watch(alunoHomeChatUnreadSelectProvider);

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
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: dockClearance),
                    child: navigationShell,
                  ),
                ),
                if (!onChat)
                  Positioned(
                    bottom: bottomInset + FxDock.floatGap,
                    left: FxDock.sideInset,
                    right: FxDock.sideInset,
                    child: FxDock(
                      items: FxDockItems.aluno(chatUnread: chatUnread),
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
