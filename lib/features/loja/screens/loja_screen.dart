import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/loja_repository.dart';
import '../models/loja_pedido.dart';
import '../utils/loja_hub_display.dart';

final lojaRepositoryProvider = Provider(
  (ref) => LojaRepository(ref.read(apiClientProvider)),
);

class LojaScreen extends ConsumerStatefulWidget {
  const LojaScreen({super.key});

  @override
  ConsumerState<LojaScreen> createState() => _LojaScreenState();
}

class _LojaScreenState extends ConsumerState<LojaScreen> {
  LojaHubView _view = LojaHubView.vitrine;
  List<Pacote> _pacotes = [];
  List<LojaPedido> _pedidos = [];
  PlanoFeatures? _planoFromHome;
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _abrirVista() async {
    final picked = await showFxInsetPickerSheet<LojaHubView>(
      context,
      title: 'Ver',
      selected: _view,
      items: [
        for (final v in LojaHubView.values)
          FxInsetPickerSheetItem(value: v, label: lojaHubViewLabel(v)),
      ],
    );
    if (!mounted || picked == null || picked == _view) return;
    setState(() => _view = picked);
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
    final ok = await showFxFormSheet(
      context,
      title: 'Checkout — ${pacote.titulo}',
      subtitle: formatBrlCurrency(pacote.valor),
      icon: Icons.qr_code_rounded,
      confirmLabel: 'Gerar PIX',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailCtrl,
            decoration: FxInputDeco.build(context, 'Email do comprador'),
            keyboardType: TextInputType.emailAddress,
          ),
          TextField(
            controller: nomeCtrl,
            decoration: FxInputDeco.build(context, 'Nome (opcional)'),
          ),
        ],
      ),
    );

    final email = emailCtrl.text.trim();
    final nome = nomeCtrl.text.trim();
    emailCtrl.dispose();
    nomeCtrl.dispose();
    if (ok != true || email.isEmpty) return;

    AnalyticsService.instance.track(
      ProductEvents.lojaCheckoutStarted,
      props: {'feature': 'loja', 'pacote_id': pacote.id},
    );

    try {
      final result = await ref.read(lojaRepositoryProvider).checkout(
        pacoteId: pacote.id,
        buyerEmail: email,
        buyerNome: nome.isEmpty ? null : nome,
      );

      if (!mounted) return;

      final pix = result.pixCopiaECola;
      await showFxNoticeSheet(
        context,
        title: 'PIX gerado',
        icon: Icons.qr_code_rounded,
        actionLabel: 'OK',
        message: pix.isEmpty ? 'Pedido criado.' : pix,
        extraActions: [
          if (pix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () async {
                    await copySensitiveToClipboard(pix);
                    if (!mounted) return;
                    FeedbackHelper.showSuccess(context, 'Código copiado');
                  },
                  child: const Text('Copiar'),
                ),
              ),
            ),
        ],
      );

      await _load();
      if (!mounted) return;
      setState(() => _view = LojaHubView.pedidos);
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
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'lojaDigital',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Loja digital',
            subtitle: lojaHubSubtitle(
              view: _view,
              freshness: freshnessLabel,
            ),
            actions: [
              ShellHeaderIconButton(
                icon: 'pix',
                tooltip: 'Trocar visão',
                onTap: _abrirVista,
              ),
            ],
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
              : FxContentWidthLimiter(
                  child: IndexedStack(
                    index: _view.index,
                    children: [_buildVitrine(), _buildPedidos()],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildVitrine() {
    if (_pacotes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxSettingsGroup(
            header: 'Vitrine',
            caption: 'Toque no pacote para gerar um PIX.',
            children: [
              for (var i = 0; i < _pacotes.length; i++)
                FxSettingsTile(
                  fxIcon: 'spark',
                  label: _pacotes[i].titulo,
                  subtitle: lojaPacoteSubtitle(
                    descricao: _pacotes[i].descricao,
                    duracaoMeses: _pacotes[i].duracaoMeses,
                  ),
                  value: formatBrlCurrency(
                    _pacotes[i].valor,
                    showDecimals: false,
                  ),
                  numeric: true,
                  showDivider: i != _pacotes.length - 1,
                  onTap: () => _checkoutPacote(_pacotes[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPedidos() {
    if (_pedidos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            FxEmptyState(
              icon: 'article',
              title: 'Nenhum pedido ainda',
              subtitle: 'Gere um PIX na vitrine para ver pedidos aqui.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxSettingsGroup(
            header: 'Pedidos',
            caption: 'PIX gerados nesta loja.',
            children: [
              for (var i = 0; i < _pedidos.length; i++)
                FxSettingsTile(
                  fxIcon: lojaPedidoFxIcon(_pedidos[i].status),
                  label: lojaPedidoLabel(
                    buyerNome: _pedidos[i].buyerNome,
                    buyerEmail: _pedidos[i].buyerEmail,
                  ),
                  subtitle: lojaPedidoSubtitle(
                    buyerNome: _pedidos[i].buyerNome,
                    buyerEmail: _pedidos[i].buyerEmail,
                    status: _pedidos[i].status,
                  ),
                  value: formatBrlCurrency(_pedidos[i].valor),
                  numeric: true,
                  showDivider: i != _pedidos.length - 1,
                  onTap: () {},
                ),
            ],
          ),
        ],
      ),
    );
  }
}
