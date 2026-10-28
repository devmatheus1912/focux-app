import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/utils/dashboard_shortcut_navigation.dart';
import '../../dashboard/utils/dashboard_tool_groups.dart';
import '../../dashboard/widgets/dashboard_tool_shortcut_group.dart';
import '../providers/ferramentas_catalogo_provider.dart';
import '../utils/ferramentas_agrupar.dart';
import '../widgets/ferramentas_help_sheet.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Tudo o que o plano oferece, agrupado por tarefa. Substitui o catálogo em sheet.
class FerramentasScreen extends ConsumerStatefulWidget {
  const FerramentasScreen({super.key});

  @override
  ConsumerState<FerramentasScreen> createState() => _FerramentasScreenState();
}

class _FerramentasScreenState extends ConsumerState<FerramentasScreen> {
  var _busca = '';

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.track(ProductEvents.ferramentasAberta);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final catalogo = ref.watch(ferramentasCatalogoProvider);

    return fxScreenA11yScope(
      label: s.ferramentasTitulo,
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: s.ferramentasTitulo,
          actions: [
            FxHelpIconButton(
              tooltip: 'Sobre as ferramentas',
              onTap: () => showFerramentasHelpSheet(context),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
              ),
              child: Semantics(
                textField: true,
                label: s.ferramentasBuscar,
                child: TextField(
                  onChanged: (v) => setState(() => _busca = v),
                  textInputAction: TextInputAction.search,
                  style: FocuxHubTypography.body(color: chrome.ink),
                  decoration: InputDecoration(
                    hintText: s.ferramentasBuscar,
                    hintStyle: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: chrome.mute,
                      size: FxSettingsLayout.iconSize,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: chrome.cardFill,
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(TokensStrip.rInput),
                      borderSide: BorderSide(color: chrome.lineStrong),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s3,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: catalogo.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 6),
                ),
                error: (_, __) => Center(
                  child: FxTonalButton(label: '${s.ferramentasNaoCarregou} ${s.ferramentasTentar}', onPressed: () => ref.invalidate(ferramentasCatalogoProvider), compact: true),
                ),
                data: (dados) {
                  final grupos = agruparFerramentas(
                    groupCatalogoHubs(dados, query: _busca),
                  );
                  if (grupos.isEmpty) {
                    return Center(
                      child: Text(
                        s.ferramentasNenhuma,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s5,
                    ),
                    itemCount: grupos.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: FxSettingsLayout.groupGap),
                    itemBuilder: (context, i) {
                      final grupo = grupos[i];
                      return DashboardToolShortcutGroup(
                        header: grupo.title.isEmpty ? null : grupo.title,
                        caption: grupo.title.isEmpty ? null : grupo.subtitulo,
                        shortcuts: grupo.shortcuts,
                        onShortcut: (atalho) =>
                            openDashboardShortcut(context, ref, atalho),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
