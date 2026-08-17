import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/loja_repository.dart';
import '../models/loja_pedido.dart';

final lojaRepositoryProvider = Provider(
  (ref) => LojaRepository(ref.read(apiClientProvider)),
);

class LojaScreen extends ConsumerStatefulWidget {
  const LojaScreen({super.key});

  @override
  ConsumerState<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends ConsumerState<LojaScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Pacote> _pacotes = [];
  List<LojaPedido> _pedidos = [];
  PlanoFeatures? _planoFromHome;
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final home = await ref.read(lojaRepositoryProvider).getHome();
      if (!mounted) return;
      setState(() {
        _pacotes = home.pacotes;
        _pedidos = home.pedidos;
        _planoFromHome = home.planoFeatures;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _checkoutPacote(Pacote pacote) async {
    final emailCtrl = TextEditingController();
    final nomeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Checkout — ${pacote.titulo}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${pacote.valor.toStringAsFixed(2)}',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email do comprador'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gerar PIX'),
          ),
        ],
      ),
    );

    if (ok != true || emailCtrl.text.trim().isEmpty) return;

    AnalyticsService.instance.track(
      ProductEvents.lojaCheckoutStarted,
      props: {'feature': 'loja', 'pacote_id': pacote.id},
    );

    try {
      final result = await ref.read(lojaRepositoryProvider).checkout(
        pacoteId: pacote.id,
        buyerEmail: emailCtrl.text.trim(),
        buyerNome: nomeCtrl.text.trim().isEmpty ? null : nomeCtrl.text.trim(),
      );

      if (!mounted) return;

      final pix = result.pixCopiaECola;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PIX gerado'),
          content: SelectableText(pix.isEmpty ? 'Pedido criado.' : pix),
          actions: [
            if (pix.isNotEmpty)
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pix));
                  FeedbackHelper.showSuccess(ctx, 'Código copiado');
                },
                child: const Text('Copiar'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      await _load();
      _tabs.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = ShellChrome.of(context);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final planoFromHome = _planoFromHome;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    return fxScreenA11yScope(
      label: 'Loja digital',
      child: FeatureGate(
        featureName: 'Loja Digital',
        requiredPlan: SubscriptionPlan.ENTERPRISE_PRO,
        capability: 'lojaDigital',
        child: FxShellScaffold(
          appBar: FxShellAppBar(
            title: 'Loja digital',
            subtitle: freshnessLabel ?? 'Vitrine de pacotes e pedidos PIX',
          ),
          body: _loading
              ? const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: SkeletonList(count: 5),
                )
              : _error != null
              ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: scheme.primary,
                  message: _error!,
                  onRetry: _load,
                )
              : Column(
                  children: [
                    TabBar(
                      controller: _tabs,
                      tabs: const [Tab(text: 'Vitrine'), Tab(text: 'Pedidos')],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [_buildVitrine(scheme), _buildPedidos(scheme)],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildVitrine(ColorScheme scheme) {
    if (_pacotes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FxEmptyState(
            icon: 'spark',
            title: 'Nenhum pacote na vitrine',
            subtitle:
                'Crie planos em Planos & link de vendas para vender pela loja.',
            action: FxEmptyAction(
              label: 'Ir para pacotes',
              onTap: () => context.push('/pacotes'),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          96,
        ),
        itemCount: _pacotes.length,
        itemBuilder: (_, i) {
          final pacote = _pacotes[i];
          return FxStaggerItem(
            index: i,
            child: Semantics(
              label: 'Pacote ${pacote.titulo}, ${pacote.valor} reais',
              button: true,
              child: FxSatelliteListTile(
                margin: const EdgeInsets.only(bottom: TokensStrip.s3),
                accent: scheme.primary,
                title: pacote.titulo,
                titleCase: false,
                subtitle: Text(
                  pacote.descricao?.isNotEmpty == true
                      ? pacote.descricao!
                      : '${pacote.duracaoMeses} mês(es)',
                ),
                trailing: FilledButton(
                  onPressed: () => _checkoutPacote(pacote),
                  child: Text('R\$ ${pacote.valor.toStringAsFixed(0)}'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPedidos(ColorScheme scheme) {
    if (_pedidos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          FxEmptyState(
            icon: 'article',
            title: 'Nenhum pedido ainda',
            subtitle: 'Gere um PIX na vitrine para ver pedidos aqui.',
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          96,
        ),
        itemCount: _pedidos.length,
        itemBuilder: (_, i) {
          final pedido = _pedidos[i];
          return FxStaggerItem(
            index: i,
            child: Semantics(
              label: 'Pedido ${pedido.buyerEmail}, status ${pedido.status}',
              child: FxSatelliteListTile(
                accent: scheme.primary,
                title: pedido.buyerEmail,
                titleCase: false,
                subtitle: Text('Status: ${pedido.status}'),
                trailing: Text(
                  'R\$ ${pedido.valor.toStringAsFixed(2)}',
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
