import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

final _repo = Provider((ref) => DesafioRepository(ref.read(apiClientProvider)));

class DesafiosAlunoScreen extends ConsumerStatefulWidget {
  const DesafiosAlunoScreen({super.key});

  @override
  ConsumerState<DesafiosAlunoScreen> createState() =>
      _DesafiosAlunoScreenState();
}

class _DesafiosAlunoScreenState extends ConsumerState<DesafiosAlunoScreen> {
  List<Desafio> _desafios = [];
  var _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await ref.read(_repo).meus();
      if (!mounted) return;
      setState(() {
        _desafios = lista;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  void _abrir(Desafio d) {
    context.push(desafioAlunoDetailPath(d.id), extra: d);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Desafios',
      child: FeatureGate(
        featureName: 'Desafios',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'comunidadeGrupos',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Desafios',
            subtitle: desafioHubSubtitle(
              count: _loading ? 0 : _desafios.length,
              freshness: _loading ? null : freshness,
            ),
            onBack: () => safePopOrGo(context, '/dashboard/aluno'),
          ),
          body: _loading
              ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 5),
                )
              : _error != null
              ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: scheme.primary,
                  message: _error!,
                  onRetry: _load,
                )
              : FxContentWidthLimiter(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: _desafios.isEmpty ? 1 : _desafios.length + 2,
        itemBuilder: (context, index) {
          if (_desafios.isEmpty) {
            return const FxEmptyState(
              icon: 'spark',
              title: 'Nenhum desafio agora',
              subtitle: 'Quando seu personal abrir uma campanha, ela aparece aqui.',
            );
          }
          if (index == 0) {
            return const DashboardSectionHeader(title: 'Campanhas ativas');
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(
                top: TokensStrip.s2,
                bottom: TokensStrip.s3,
              ),
              child: Text(
                'Toque para entrar e ver o detalhe.',
                style: FocuxHubTypography.bodyMuted(
                  color: fxScreenMute(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          final desafio = _desafios[index - 2];
          return FxSatelliteListTile(
            title: desafio.titulo,
            subtitle: Text(
              desafioSubtitle(
                tipo: desafio.tipo,
                metaPontos: desafio.metaPontos,
                inicio: desafio.inicio,
                fim: desafio.fim,
              ),
            ),
            trailing: Text(
              desafioMetaLabel(desafio.metaPontos),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _abrir(desafio),
          );
        },
      ),
    );
  }
}
