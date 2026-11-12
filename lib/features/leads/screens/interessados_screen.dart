import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../pacotes/providers/pacotes_provider.dart';
import '../../pacotes/widgets/pacotes_storefront_links.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/lead_repository.dart';
import '../providers/leads_provider.dart';
import '../utils/interessados_display.dart';
import '../utils/lead_display.dart';
import '../widgets/interessado_contato_mixin.dart';
import '../widgets/interessado_sheets.dart';

/// Interessados: quem perguntou e ainda não é aluno, em etapas. Uma lista só
/// (sem kanban): Para responder, Em conversa e, fechados, os que viraram
/// alunos e os sem interesse.
class InteressadosScreen extends ConsumerStatefulWidget {
  const InteressadosScreen({
    super.key,
    this.soDaPagina = false,
    this.abrirNovo = false,
  });

  /// `/leads?origem=pagina`: só quem chegou pela página.
  final bool soDaPagina;

  /// `/leads?novo=1` (antigo `/leads/novo`): abre a folha de cara.
  final bool abrirNovo;

  @override
  ConsumerState<InteressadosScreen> createState() => _InteressadosScreenState();
}

class _InteressadosScreenState extends ConsumerState<InteressadosScreen>
    with InteressadoContatoMixin<InteressadosScreen> {
  final _searchCtrl = TextEditingController();
  List<Lead> _leads = const [];
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  late var _soDaPagina = widget.soDaPagina;
  var _abrirViraram = false;
  var _abrirSemInteresse = false;
  Timer? _debounce;

  @override
  LeadRepository get repoInteressados =>
      LeadRepository(ref.read(apiClientProvider));

  @override
  Future<void> aoAnotarContato() => _carregar();

  @override
  void initState() {
    super.initState();
    _carregar();
    if (widget.abrirNovo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _novo();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = _fetchedAt == null;
      _erro = null;
    });
    try {
      invalidateLeadsCaches(ref);
      final home = await ref.read(leadsHomeProvider.future);
      if (home.planoFeatures case final plano?) {
        ref.read(planoFeaturesProvider.notifier).seedFromHome(plano);
      }
      final pagina = await repoInteressados.listarPagina(q: _query, size: 200);
      if (!mounted) return;
      setState(() {
        _leads = pagina.content;
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

  void _onQuery(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _query = v.trim();
      _carregar();
    });
  }

  Future<void> _novo() async {
    AnalyticsService.instance.track(
      ProductEvents.leadCreatedOrOpened,
      props: {'feature': 'leads', 'action': 'novo'},
    );
    final salvo = await showInteressadoSheet(context, repo: repoInteressados);
    if (salvo != null && mounted) await _carregar();
  }

  Future<void> _abrir(Lead lead) async {
    AnalyticsService.instance.track(
      ProductEvents.leadCreatedOrOpened,
      props: {'feature': 'leads', 'action': 'abrir', 'lead_id': lead.id},
    );
    await context.push('/leads/${lead.id}', extra: lead);
    if (mounted) await _carregar();
  }

  Future<void> _copiarLinkPagina() async {
    try {
      final home = await ref.read(pacoteRepositoryProvider).getHome();
      if (mounted) copyStorefrontLink(context, home.perfil?.slug);
    } catch (e) {
      if (mounted) copyStorefrontLink(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final visiveis =
        _soDaPagina
            ? _leads.where((l) => interessadoDaPagina(l.origem)).toList()
            : _leads;
    final grupos = interessadosAgrupar(visiveis);
    final plano = ref.watch(planoFeaturesProvider).value;
    final limite = plano?.limiteLeads;

    return fxScreenA11yScope(
      label: 'Interessados',
      child: FeatureGate(
        featureName: 'Interessados',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'leads',
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, '/dashboard/personal');
          },
          child: FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Interessados',
              subtitle: FxHubFreshness.joinCount(
                _loading
                    ? 'Interessados'
                    : interessadosSubtitulo(grupos.paraResponder.length),
                FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
              onBack: () => safePopOrGo(context, '/dashboard/personal'),
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar Interessados',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Interessados',
                        subtitle: 'Quem perguntou e ainda não é aluno.',
                        tips: const [
                          FxHelpTip(
                            'Para responder',
                            'Quem espera há mais tempo vem primeiro. O WhatsApp fica na própria linha.',
                          ),
                          FxHelpTip(
                            'Em conversa',
                            'Depois de falar com a pessoa, anote o contato: ela passa para Em conversa sozinha.',
                          ),
                          FxHelpTip(
                            'Virou aluno',
                            'Na ficha, "Cadastrar como aluno" abre o cadastro já preenchido.',
                          ),
                        ],
                      ),
                ),
                ShellHeaderIconButton(
                  icon: FxIcons.adicionar,
                  tooltip: 'Novo interessado',
                  onTap: _novo,
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
                      onRetry: _carregar,
                    )
                    : RefreshIndicator(
                      color: primary,
                      onRefresh: _carregar,
                      child: FxContentWidthLimiter(
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s6,
                          ),
                          children: [
                            if (leadShowsLimitBanner(
                              _leads.length,
                              limiteLeads: limite,
                            ))
                              FxSatelliteListTile(
                                title: leadLimitLabel(_leads.length, limite!),
                                titleCase: false,
                                accent: primary,
                                trailing: Text(
                                  'Pro',
                                  style: FocuxHubTypography.rotulo(
                                    color: primary,
                                  ),
                                ),
                                onTap:
                                    () => context.push(
                                      '/assinatura',
                                      extra: 'Pro',
                                    ),
                              ),
                            if (interessadosMostraBusca(
                              total: _leads.length,
                              query: _query,
                            ))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TokensStrip.s3,
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: _onQuery,
                                  textInputAction: TextInputAction.search,
                                  onTapOutside:
                                      (_) => FxKeyboardDismissScope.dismiss(),
                                  decoration: FxInputDeco.build(
                                    context,
                                    'Buscar pelo nome',
                                  ),
                                ),
                              ),
                            if (_soDaPagina)
                              FxSatelliteListTile(
                                title: 'Só quem chegou pela sua página',
                                titleCase: false,
                                trailing: Icon(
                                  FxIcons.fechar,
                                  color: chrome.mute,
                                ),
                                onTap:
                                    () => setState(() => _soDaPagina = false),
                              ),
                            if (visiveis.isEmpty)
                              FxEmptyState(
                                icon: FxIcons.pessoa,
                                title:
                                    _query.isEmpty
                                        ? 'Ninguém por aqui ainda'
                                        : 'Ninguém com esse nome',
                                subtitle:
                                    _query.isEmpty
                                        ? 'Cadastre quem te chamou no Instagram ou no WhatsApp, ou compartilhe sua página.'
                                        : 'Ajuste a busca.',
                                action: FxEmptyAction(
                                  label: 'Novo interessado',
                                  onTap: _novo,
                                ),
                              ),
                            if (visiveis.isEmpty && _query.isEmpty)
                              Center(
                                child: FxTonalButton(
                                  label: 'Copiar link da página',
                                  icon: FxIcons.link,
                                  compact: true,
                                  onPressed: _copiarLinkPagina,
                                ),
                              )
                            else ...[
                              ..._grupo('Para responder', grupos.paraResponder),
                              ..._grupo('Em conversa', grupos.emConversa),
                              ..._grupoFechado(
                                'Viraram alunos',
                                grupos.viraramAlunos,
                                aberto: _abrirViraram,
                                alternar:
                                    () => setState(
                                      () => _abrirViraram = !_abrirViraram,
                                    ),
                              ),
                              ..._grupoFechado(
                                'Sem interesse',
                                grupos.semInteresse,
                                aberto: _abrirSemInteresse,
                                alternar:
                                    () => setState(
                                      () =>
                                          _abrirSemInteresse =
                                              !_abrirSemInteresse,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  List<Widget> _grupo(String titulo, List<Lead> leads) {
    if (leads.isEmpty) return const [];
    final chrome = ShellChrome.of(context);
    return [
      Padding(
        padding: const EdgeInsets.only(
          top: TokensStrip.s2,
          bottom: TokensStrip.s2,
          left: TokensStrip.s1,
        ),
        child: Text(
          '$titulo (${leads.length})',
          style: FocuxHubTypography.chip(chrome.mute),
        ),
      ),
      for (final l in leads) _linha(l),
    ];
  }

  List<Widget> _grupoFechado(
    String titulo,
    List<Lead> leads, {
    required bool aberto,
    required VoidCallback alternar,
  }) {
    if (leads.isEmpty) return const [];
    final chrome = ShellChrome.of(context);
    return [
      FxSatelliteListTile(
        title: '$titulo (${leads.length})',
        titleCase: false,
        muted: true,
        trailing: Icon(
          aberto ? FxIcons.chevronCima : FxIcons.chevronBaixo,
          color: chrome.mute,
        ),
        onTap: alternar,
      ),
      if (aberto)
        for (final l in leads) _linha(l),
    ];
  }

  Widget _linha(Lead lead) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final tempo = interessadoTempo(lead);
    final linha = interessadoLinha(lead);
    final temTelefone = (lead.telefone ?? '').trim().isNotEmpty;
    final noFunil =
        !interessadoVirouAluno(lead.status) &&
        lead.status.toUpperCase() != 'CANCELADO';
    return FxSatelliteListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: primary.withValues(alpha: 0.14),
        child: Text(
          fxInitials(lead.nome),
          style: FocuxHubTypography.rotulo(color: primary),
        ),
      ),
      title: lead.nome,
      subtitle:
          linha.isEmpty && tempo.texto.isEmpty
              ? null
              : Text(
                [linha, tempo.texto].where((p) => p.isNotEmpty).join(' · '),
                style: FocuxHubTypography.bodyMuted(
                  color: tempo.alerta ? EagleTokens.warn : chrome.mute,
                ),
              ),
      trailing:
          temTelefone && noFunil
              ? IconButton(
                tooltip: 'WhatsApp de ${lead.nome.split(' ').first}',
                onPressed: () => contatarInteressado(lead, 'WHATSAPP'),
                icon: Icon(FxIcons.chat, color: primary),
              )
              : null,
      onTap: () => _abrir(lead),
    );
  }
}
