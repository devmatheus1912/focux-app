import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/gated_profile_shortcuts.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../widgets/perfil_action_tile.dart';

/// Hub de ferramentas de crescimento (antes ExpansionTile no Perfil).
class PerfilFerramentasScreen extends ConsumerWidget {
  const PerfilFerramentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final accent = BrandPalette.softened(theme.colorScheme.primary);
    final actionInk =
        chrome.isDark
            ? theme.colorScheme.primary
            : BrandPalette.deep(theme.colorScheme.primary);
    final mute = chrome.mute;
    final line = chrome.line;
    final featuresAsync = ref.watch(planoFeaturesProvider);

    return fxScreenA11yScope(
      label: 'Mais ferramentas',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Mais ferramentas',
          onBack: () {
            HapticFeedback.selectionClick();
            safePopOrGo(context, '/perfil');
          },
        ),
        body: featuresAsync.when(
          loading: () => const SkeletonList(count: 5),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: accent,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(planoFeaturesProvider),
                title: 'Não conseguimos carregar as ferramentas',
              ),
          data: (_) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s4,
                TokensStrip.s3,
                TokensStrip.s4,
                TokensStrip.s6,
              ),
              children: [
                FxStaggerItem(
                  index: 0,
                  child: Text(
                    'Crescimento, loja, equipe e hábitos',
                    style: TokensStrip.bodyMuted(color: mute),
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
                FxStaggerItem(
                  index: 1,
                  child: Container(
                    decoration: chrome.panel(radius: 16, accent: accent),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s4,
                      vertical: TokensStrip.s2,
                    ),
                    child: GatedProfileShortcuts(
                      accent: accent,
                      actionInk: actionInk,
                      mute: mute,
                      line: line,
                      tileBuilder:
                          ({
                            required icon,
                            required label,
                            required value,
                            required onTap,
                            required locked,
                            upgradeTierLabel,
                          }) => PerfilActionTile(
                            icon: icon,
                            label: label,
                            value: value,
                            accent: accent,
                            actionInk: actionInk,
                            mute: mute,
                            line: line,
                            locked: locked,
                            upgradeTierLabel: upgradeTierLabel,
                            onTap: onTap,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s4),
                FxStaggerItem(
                  index: 2,
                  child: Text(
                    'Ferramentas do plano ativo. Itens bloqueados abrem o upgrade.',
                    style: TokensStrip.bodyMuted(
                      color: mute,
                    ).copyWith(height: 1.35),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
