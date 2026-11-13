import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../loja/data/loja_repository.dart';
import '../../loja/models/loja_pedido.dart';
import '../../loja/utils/loja_hub_display.dart';
import '../../monetizacao/data/upsell_repository.dart';
import '../../monetizacao/utils/oferta_upsell_display.dart';
import '../../monetizacao/widgets/oferta_upsell_editor.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/pacote_repository.dart';
import '../providers/pacotes_provider.dart';
import '../utils/pacote_display.dart';
import '../widgets/pacotes_storefront_links.dart';
import '../widgets/plano_sheet.dart';

part 'vendas_screen_acoes.part.dart';

/// Vendas: uma tela, sem abas. Sua página, Planos à venda, Ofertas para
/// alunos e o que já foi vendido (pedidos da página e ofertas aceitas).
class VendasScreen extends ConsumerStatefulWidget {
  const VendasScreen({super.key});

  @override
  ConsumerState<VendasScreen> createState() => _VendasScreenState();
}

class _VendasScreenState extends ConsumerState<VendasScreen> {
  List<Pacote> _planos = const [];
  List<Pacote> _pausados = const [];
  var _mostrarPausados = false;
  List<OfertaUpsell> _ofertas = const [];
  List<OfertaAceita> _aceitas = const [];
  List<LojaPedido> _pedidos = const [];
  String? _slug;
  var _paginaNoAr = true;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/financeiro');
  }

  Future<T?> _talvez<T>(Future<T> f) async {
    try {
      return await f;
    } catch (_) {
      return null;
    }
  }

  Future<void> _carregar({bool force = false}) async {
    setState(() {
      _loading = _fetchedAt == null;
      _erro = null;
    });
    try {
      if (force) invalidatePacotesCaches(ref);
      final upsell = ref.read(upsellRepositoryProvider);
      // Planos são o essencial; ofertas e vendas não derrubam a tela.
      final results = await Future.wait<Object?>([
        ref.read(pacoteRepositoryProvider).getHome(),
        _talvez(upsell.listarOfertas()),
        _talvez(upsell.listarAceitas()),
        _talvez(ref.read(lojaRepositoryProvider).pedidos()),
      ]);
      if (!mounted) return;
      final home = results[0]! as PacotesHomeBundle;
      setState(() {
        _planos = home.pacotes;
        _pausados = home.pausados;
        _slug = home.perfil?.slug;
        _paginaNoAr = home.perfil?.paginaNoAr ?? true;
        _ofertas = (results[1] as List<OfertaUpsell>?) ?? _ofertas;
        _aceitas = (results[2] as List<OfertaAceita>?) ?? _aceitas;
        _pedidos =
            (results[3] as dynamic)?.content as List<LojaPedido>? ?? _pedidos;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  int get _pixAguardando =>
      _pedidos.where((p) => lojaPedidoPendente(p.status)).length;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Vendas',
      child: FeatureGate(
        featureName: 'Vendas',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'loja',
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave();
          },
          child: FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Vendas',
              subtitle: FxHubFreshness.joinCount(
                _loading
                    ? 'Vendas'
                    : vendasSubtitulo(
                      pixAguardando: _pixAguardando,
                      planos: _planos.length,
                    ),
                FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar vendas',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Vendas',
                        subtitle:
                            'O que você vende, para quem e o que já vendeu.',
                        tips: const [
                          FxHelpTip(
                            'Planos à venda',
                            'Aparecem na sua página. Quem não é aluno compra por lá com PIX.',
                          ),
                          FxHelpTip(
                            'Ofertas para alunos',
                            'Mostre um plano a quem já é aluno: upgrade, renovação ou extra.',
                          ),
                          FxHelpTip(
                            'Vendas',
                            'Pedidos da página e ofertas aceitas. Aceitar uma oferta já cria a cobrança, com vencimento em 3 dias.',
                          ),
                        ],
                      ),
                ),
              ],
            ),
            body:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                      child: SkeletonList(count: 6),
                    )
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      message: _erro!,
                      onRetry: () => _carregar(force: true),
                    )
                    : RefreshIndicator(
                      color: primary,
                      onRefresh: () => _carregar(force: true),
                      child: FxContentWidthLimiter(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s6,
                          ),
                          children: [
                            ..._suaPagina(),
                            const SizedBox(height: FxSettingsLayout.groupGap),
                            ..._planosAVenda(chrome),
                            const SizedBox(height: FxSettingsLayout.groupGap),
                            ..._ofertasParaAlunos(chrome),
                            const SizedBox(height: FxSettingsLayout.groupGap),
                            ..._vendas(chrome),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  List<Widget> _suaPagina() => [
    FxSettingsGroup(
      header: 'Sua página',
      children: [
        if (!_paginaNoAr)
          FxSettingsTile(
            icon: FxIcons.alerta,
            label: pacotePaginaForaDoArTitulo,
            subtitle: pacotePaginaForaDoArTexto,
            value: '',
            onTap: () => context.push('/perfil/landing-editor'),
          ),
        FxSettingsTile(
          icon: FxIcons.ver,
          label: 'Ver como o cliente vê',
          value: '',
          onTap: () => openStorefrontPreview(context, _slug),
        ),
        FxSettingsTile(
          icon: FxIcons.link,
          label: 'Copiar link',
          value: '',
          showDivider: false,
          onTap: () => copyStorefrontLink(context, _slug),
        ),
      ],
    ),
  ];

  List<Widget> _planosAVenda(ShellPalette chrome) => [
    const DashboardSectionHeader(title: 'Planos à venda'),
    const SizedBox(height: TokensStrip.s2),
    for (final p in _planos)
      FxSatelliteListTile(
        title: p.titulo,
        titleCase: false,
        subtitle: Text(
          pacoteLinha(
            treino: p.incluiTreino,
            consultoria: p.incluiConsultoria,
            meses: p.duracaoMeses,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.destaque)
              Padding(
                padding: const EdgeInsets.only(right: TokensStrip.s1),
                child: Semantics(
                  label: 'Em destaque',
                  child: const Icon(
                    FxIcons.estrela,
                    size: 18,
                    color: EagleTokens.warn,
                  ),
                ),
              ),
            Text(
              p.valor.format(),
              style: FocuxHubTypography.rotulo(color: chrome.ink),
            ),
            IconButton(
              tooltip: 'Mais opções do plano',
              onPressed: () => _maisPlano(p),
              icon: Icon(FxIcons.mais, color: chrome.mute),
            ),
          ],
        ),
        onTap: () => _editarPlano(p),
      ),
    FxSatelliteListTile(
      title: 'Novo plano',
      titleCase: false,
      leading: Icon(
        FxIcons.adicionar,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => _editarPlano(null),
    ),
    if (_pausados.isNotEmpty)
      FxSatelliteListTile(
        title: 'Pausados (${_pausados.length})',
        titleCase: false,
        muted: true,
        trailing: Icon(
          _mostrarPausados ? FxIcons.chevronCima : FxIcons.chevronBaixo,
          color: chrome.mute,
        ),
        onTap: () => setState(() => _mostrarPausados = !_mostrarPausados),
      ),
    if (_mostrarPausados)
      for (final p in _pausados)
        FxSatelliteListTile(
          title: p.titulo,
          titleCase: false,
          muted: true,
          leading: Icon(FxIcons.pausar, color: chrome.mute),
          subtitle: Text('Pausado · fora da página · ${p.valor.format()}'),
          trailing: IconButton(
            tooltip: 'Mais opções do plano',
            onPressed: () => _maisPlano(p),
            icon: Icon(FxIcons.mais, color: chrome.mute),
          ),
          onTap: () => _maisPlano(p),
        ),
  ];

  List<Widget> _ofertasParaAlunos(ShellPalette chrome) => [
    const DashboardSectionHeader(title: 'Ofertas para alunos'),
    const SizedBox(height: TokensStrip.s2),
    if (_ofertas.isEmpty)
      Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
        child: Text(
          vendasOfertasVazio,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      ),
    for (final o in _ofertas)
      FxSatelliteListTile(
        title: o.titulo,
        titleCase: false,
        muted: !o.ativo,
        subtitle: Text(
          ofertaLinha(
            tipoGatilho: o.tipoGatilho,
            enviadas: o.enviadas,
            aceitas: o.aceitas,
            ativo: o.ativo,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Mais opções da oferta',
          onPressed: () => _maisOferta(o),
          icon: Icon(FxIcons.mais, color: chrome.mute),
        ),
        onTap: () => _editarOferta(o),
      ),
    FxSatelliteListTile(
      title: 'Nova oferta',
      titleCase: false,
      leading: Icon(
        FxIcons.adicionar,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => _editarOferta(null),
    ),
  ];

  List<Widget> _vendas(ShellPalette chrome) {
    final vazio = _pedidos.isEmpty && _aceitas.isEmpty;
    return [
      const DashboardSectionHeader(title: 'Vendas'),
      const SizedBox(height: TokensStrip.s2),
      if (vazio)
        Text(
          vendasPedidosVazio,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      for (final a in _aceitas)
        FxSatelliteListTile(
          title: '${fxTitleCaseName(a.alunoNome).split(' ').first} aceitou',
          titleCase: false,
          subtitle: Text('${a.titulo} · cobrança criada'),
          trailing: Text(
            a.valor.format(),
            style: FocuxHubTypography.rotulo(color: chrome.ink),
          ),
          onTap: () => context.push('/financeiro?alunoId=${a.alunoId}'),
        ),
      for (final p in _pedidos)
        FxSatelliteListTile(
          title: lojaPedidoLabel(
            buyerNome: p.buyerNome,
            buyerEmail: p.buyerEmail,
          ),
          titleCase: false,
          subtitle: Text(vendasPedidoEstado(p)),
          trailing: Text(
            p.valor.format(),
            style: FocuxHubTypography.rotulo(color: chrome.ink),
          ),
          onTap: () => _abrirPedido(p),
        ),
    ];
  }
}

/// "Aguardando PIX", "Pago · aluno criado".
String vendasPedidoEstado(LojaPedido p) {
  if (lojaPedidoPendente(p.status)) return 'Aguardando PIX';
  final status = lojaPedidoStatusLabel(p.status);
  if (status == 'Pago' && p.alunoId != null) return 'Pago · aluno criado';
  return status;
}
