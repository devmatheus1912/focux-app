import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/ferramentas_catalogo_models.dart';
import '../providers/ferramentas_catalogo_provider.dart';
import '../utils/ferramentas_tab_screens.dart';
import '../widgets/hub_embed_scope.dart';

/// Hub com tabs → telas existentes (Captação / Vendas / Financeiro).
class FerramentasHubScreen extends ConsumerStatefulWidget {
  const FerramentasHubScreen({
    super.key,
    required this.itemId,
    this.initialAbaId,
  });

  final String itemId;
  final String? initialAbaId;

  @override
  ConsumerState<FerramentasHubScreen> createState() =>
      _FerramentasHubScreenState();
}

class _FerramentasHubScreenState extends ConsumerState<FerramentasHubScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;
  CatalogoEntrada? _item;
  List<CatalogoEntrada> _abas = const [];

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  void _ensureTabs(CatalogoEntrada item) {
    if (_item?.id == item.id && _tabs != null) return;
    _tabs?.dispose();
    _item = item;
    _abas = item.abas;
    var initial = 0;
    final want = widget.initialAbaId?.toLowerCase();
    if (want != null && want.isNotEmpty) {
      final idx = _abas.indexWhere(
        (a) =>
            a.id.toLowerCase() == want ||
            a.legacyIds.any((id) => id.toLowerCase() == want),
      );
      if (idx >= 0) initial = idx;
    }
    _tabs = TabController(
      length: _abas.length,
      vsync: this,
      initialIndex: _abas.isEmpty ? 0 : initial.clamp(0, _abas.length - 1),
    );
    _tabs!.addListener(() {
      if (_tabs!.indexIsChanging) return;
      final aba = _abas[_tabs!.index];
      AnalyticsService.instance.track(
        'ferramentas_hub_aba',
        props: {'hub': item.id, 'aba': aba.id},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ferramentasCatalogoProvider);
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;

    return async.when(
      loading:
          () => FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Ferramentas',
              onBack: () => safePopOrGo(context, '/dashboard/personal'),
            ),
            body: const FxContentWidthLimiter(
              child: Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 4),
              ),
            ),
          ),
      error:
          (e, _) => FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Ferramentas',
              onBack: () => safePopOrGo(context, '/dashboard/personal'),
            ),
            body: FxContentWidthLimiter(
              child: FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: scheme.primary,
                message: '$e',
                onRetry: () => ref.invalidate(ferramentasCatalogoProvider),
              ),
            ),
          ),
      data: (catalogo) {
        final item = catalogo.resolveNavTarget(widget.itemId);
        if (item == null || !item.isHubComAbas) {
          return FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Ferramentas',
              onBack: () => safePopOrGo(context, '/dashboard/personal'),
            ),
            body: const FxContentWidthLimiter(
              child: FxEmptyState(
                icon: 'spark',
                title: 'Hub indisponível',
                subtitle: 'Este agrupamento não está no catálogo atual.',
              ),
            ),
          );
        }
        _ensureTabs(item);
        final tabs = _tabs!;
        final hub = catalogo.hubForEntrada(item);

        return fxScreenA11yScope(
          label: item.titulo,
          child: FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: item.titulo,
              subtitle: hub?.titulo ?? item.subtitulo,
              onBack: () => safePopOrGo(context, '/dashboard/personal'),
            ),
            body: FxContentWidthLimiter(
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: TabBar(
                      controller: tabs,
                      isScrollable: _abas.length > 3,
                      labelColor: scheme.primary,
                      unselectedLabelColor: chrome.mute,
                      indicatorColor: scheme.primary,
                      labelStyle: FocuxHubTypography.body(
                        color: scheme.primary,
                      ).copyWith(fontWeight: FontWeight.w700),
                      tabs: [for (final aba in _abas) Tab(text: aba.titulo)],
                    ),
                  ),
                  Expanded(
                    child: FxStaggerItem(
                      index: 0,
                      child: TabBarView(
                        controller: tabs,
                        children: [
                          for (final aba in _abas)
                            HubEmbedScope(
                              child:
                                  buildFerramentasTabScreen(aba.rotaApp) ??
                                  Center(
                                    child: Text(
                                      'Rota não mapeada: ${aba.rotaApp ?? aba.id}',
                                      style: FocuxHubTypography.bodyMuted(
                                        color: chrome.mute,
                                      ),
                                    ),
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
