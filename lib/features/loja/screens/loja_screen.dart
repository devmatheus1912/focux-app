import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
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
          AlunoInsetFormField(
            controller: emailCtrl,
            label: 'Email do comprador',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          AlunoInsetFormField(
            controller: nomeCtrl,
            label: 'Nome (opcional)',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            showDivider: false,
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

  Future<void> _abrirPedido(LojaPedido pedido) async {
    final pix = lojaPedidoPix(pedido.pixCopiaECola);
    final pendente = lojaPedidoPendente(pedido.status);
    await showFxNoticeSheet(
      context,
      title: lojaPedidoLabel(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
      ),
      icon: Icons.qr_code_rounded,
      message: lojaPedidoSubtitle(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
        status: pedido.status,
      ),
      extraActions: [
        if (pix != null)
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
                child: const Text('Copiar PIX'),
              ),
            ),
          ),
        if (pendente)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              height: 48,
              child: Builder(
                builder: (sheetCtx) => TextButton(
                  onPressed: () async {
                    Navigator.of(sheetCtx).pop();
                    await _confirmarPedido(pedido);
                  },
                  child: const Text('Marcar pago'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmarPedido(LojaPedido pedido) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Marcar este PIX como pago?',
      subtitle: lojaPedidoLabel(
        buyerNome: pedido.buyerNome,
        buyerEmail: pedido.buyerEmail,
      ),
      message: formatBrlCurrency(pedido.valor),
      confirmLabel: 'Marcar pago',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(lojaRepositoryProvider).confirmar(pedido.id);
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Pedido marcado como pago');
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
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Loja digital',
            subtitle: lojaHubSubtitle(
              view: _view,
              freshness: freshnessLabel,
            ),
            onBack: () => safePopOrGo(context, '/perfil/ferramentas'),
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
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: _pacotes.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const DashboardSectionHeader(title: 'Vitrine');
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(
                top: TokensStrip.s2,
                bottom: TokensStrip.s3,
              ),
              child: Text(
                'Toque no pacote para gerar um PIX.',
                style: FocuxHubTypography.bodyMuted(
                  color: fxScreenMute(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          final pacote = _pacotes[index - 2];
          return FxSatelliteListTile(
            title: pacote.titulo,
            subtitle: Text(
              lojaPacoteSubtitle(
                descricao: pacote.descricao,
                duracaoMeses: pacote.duracaoMeses,
              ),
            ),
            trailing: Text(
              formatBrlCurrency(pacote.valor, showDecimals: false),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _checkoutPacote(pacote),
          );
        },
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
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: _pedidos.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const DashboardSectionHeader(title: 'Pedidos');
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(
                top: TokensStrip.s2,
                bottom: TokensStrip.s3,
              ),
              child: Text(
                'Toque para copiar o PIX ou marcar pago.',
                style: FocuxHubTypography.bodyMuted(
                  color: fxScreenMute(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          final pedido = _pedidos[index - 2];
          return FxSatelliteListTile(
            title: lojaPedidoLabel(
              buyerNome: pedido.buyerNome,
              buyerEmail: pedido.buyerEmail,
            ),
            subtitle: Text(
              lojaPedidoSubtitle(
                buyerNome: pedido.buyerNome,
                buyerEmail: pedido.buyerEmail,
                status: pedido.status,
              ),
            ),
            trailing: Text(
              formatBrlCurrency(pedido.valor),
              style: FocuxHubTypography.bodyMuted(
                color: fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => _abrirPedido(pedido),
          );
        },
      ),
    );
  }
}
