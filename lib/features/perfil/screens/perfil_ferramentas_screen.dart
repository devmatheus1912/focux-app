import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/gated_profile_shortcuts.dart';
import '../../planos/providers/plano_features_provider.dart';

/// Hub de ferramentas de crescimento.
class PerfilFerramentasScreen extends ConsumerWidget {
  const PerfilFerramentasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final accent = BrandPalette.softened(theme.colorScheme.primary);
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
          actions: [
            FxHelpIconButton(
              tooltip: 'Sobre as ferramentas',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'Mais ferramentas',
                    subtitle: 'Atalhos do plano ativo.',
                    tips: const [
                      FxHelpTip(
                        'Crescimento',
                        'Cada linha abre a ferramenta. Itens bloqueados levam ao upgrade.',
                        icon: 'trend',
                      ),
                      FxHelpTip(
                        'Plano',
                        'O que aparece depende do plano efetivo, não de um rótulo fixo.',
                        icon: 'spark',
                      ),
                    ],
                  ),
            ),
          ],
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
                FxSettingsLayout.pageInset,
                FxSettingsLayout.pageInset,
                FxSettingsLayout.pageInset,
                FxSettingsLayout.groupGap * 2,
              ),
              children: [
                FxStaggerItem(
                  index: 0,
                  child: FxSettingsGroup(
                    header: 'Crescimento',
                    caption:
                        'Ferramentas do plano ativo. Itens bloqueados abrem o upgrade.',
                    children: [
                      GatedProfileShortcuts(
                        tileBuilder:
                            ({
                              required icon,
                              required label,
                              required value,
                              required onTap,
                              required locked,
                              required showDivider,
                              upgradeTierLabel,
                            }) => FxSettingsTile(
                              icon: icon,
                              label: label,
                              value: value,
                              mute: mute,
                              line: line,
                              locked: locked,
                              showDivider: showDivider,
                              upgradeTierLabel: upgradeTierLabel,
                              onTap: onTap,
                            ),
                      ),
                    ],
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
