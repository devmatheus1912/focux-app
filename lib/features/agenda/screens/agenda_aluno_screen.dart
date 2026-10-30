import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/pagina.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/data/aluno_onboarding_prefs.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../chat/providers/chat_rascunho_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/agenda_repository.dart';
import '../utils/agenda_display.dart';
import '../utils/agenda_status.dart';

class AgendaAlunoScreen extends ConsumerStatefulWidget {
  const AgendaAlunoScreen({super.key});
  @override
  ConsumerState<AgendaAlunoScreen> createState() => _AgendaAlunoScreenState();
}

/// Uma lista paginada por escopo (próximas / anteriores).
class _Secao {
  _Secao(this.escopo);

  final String escopo;
  List<Agendamento> items = [];
  var page = 0;
  var hasMore = false;
  var total = 0;
  var loadingMore = false;

  void reset(Pagina<Agendamento> pagina) {
    items = pagina.content;
    page = pagina.page ?? 0;
    hasMore = pagina.hasNext;
    total = pagina.totalElements ?? pagina.content.length;
  }

  void append(Pagina<Agendamento> pagina) {
    final seen = items.map((a) => a.id).toSet();
    items = [...items, ...pagina.content.where((a) => seen.add(a.id))];
    page = pagina.page ?? (page + 1);
    hasMore = pagina.hasNext;
    total = pagina.totalElements ?? items.length;
  }
}

class _AgendaAlunoScreenState extends ConsumerState<AgendaAlunoScreen> {
  final _proximas = _Secao(agendaAlunoEscopoProximas);
  final _anteriores = _Secao(agendaAlunoEscopoAnteriores);
  var _anterioresAbertas = false;
  var _carregou = false;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    markAlunoAgendaReviewed(
      ref.read(alunoDashboardHomeProvider).value?.agendaProximoInicio,
    ).ignore();
    _load();
  }

  Future<Pagina<Agendamento>> _fetch(_Secao secao, {int page = 0}) =>
      AgendaRepository(ref.read(apiClientProvider)).meusAgendamentosPagina(
        page: page,
        escopo: secao.escopo,
      );

  Future<void> _load() async {
    // Recarga mantém a lista na tela: só a primeira mostra o esqueleto.
    setState(() {
      _loading = !_carregou;
      _erro = null;
    });
    try {
      final paginas = await Future.wait([
        _fetch(_proximas),
        _fetch(_anteriores),
      ]);
      if (!mounted) return;
      setState(() {
        _proximas.reset(paginas[0]);
        _anteriores.reset(paginas[1]);
        _loading = false;
        _carregou = true;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      if (_carregou) {
        FeedbackHelper.showError(context, friendlyError(e));
        return;
      }
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais(_Secao secao) async {
    if (secao.loadingMore || !secao.hasMore) return;
    setState(() => secao.loadingMore = true);
    try {
      final pagina = await _fetch(secao, page: secao.page + 1);
      if (!mounted) return;
      setState(() {
        secao.append(pagina);
        secao.loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => secao.loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  String _resolveAbsoluteApiUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    var base = Env.apiUrl;
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final path = pathOrUrl.startsWith('/') ? pathOrUrl : '/$pathOrUrl';
    if (base.endsWith('/api') && path.startsWith('/api/')) {
      base = base.substring(0, base.length - 4);
    }
    return '$base$path';
  }

  Future<void> _copyIcalLink() async {
    final s = S.of(context);
    try {
      final info =
          await AgendaRepository(ref.read(apiClientProvider)).icalTokenAluno();
      final fullUrl = _resolveAbsoluteApiUrl(info.url);
      await copySensitiveToClipboard(fullUrl);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, s.agendaAlunoLinkCopiado);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _menu() async {
    final s = S.of(context);
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: s.agendaAlunoMaisOpcoes,
      icone: Icons.more_horiz_rounded,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'calendario',
            rotulo: s.agendaAlunoAdicionarCalendario,
            descricao: s.agendaAlunoCalendarioTexto,
            icone: Icons.event_available_outlined,
          ),
        ]),
      ],
    );
    if (escolha == 'calendario' && mounted) await _copyIcalLink();
  }

  /// Um toque: o erro se resolve pelo chat, não há como desconfirmar.
  Future<void> _confirmar(Agendamento ag) async {
    final s = S.of(context);
    try {
      final atualizado = await AgendaRepository(
        ref.read(apiClientProvider),
      ).confirmarPresenca(ag.id);
      if (!mounted) return;
      setState(() {
        _proximas.items = [
          for (final item in _proximas.items)
            item.id == atualizado.id ? atualizado : item,
        ];
      });
      invalidateAlunoDashboardHome(ref);
      FeedbackHelper.showSuccess(context, s.agendaAlunoPresencaConfirmada);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(context, e);
    }
  }

  /// Só avisa: abre o chat com o texto pronto e o personal decide o horário.
  void _naoVou(Agendamento ag) {
    final s = S.of(context);
    ref.read(chatAlunoRascunhoProvider.notifier).value = s
        .agendaAlunoNaoVouMensagem(agendaAlunoDiaLabel(ag.inicio, ag.fim));
    openAlunoRoute(context, '/chat/aluno');
  }

  Future<void> _abrirDetalhe(Agendamento ag) async {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final obs = ag.observacoes?.trim() ?? '';
    final futura = !agendaAlunoJaPassou(ag);
    await showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => FxHomeSheetScaffold(
            isDark: chrome.isDark,
            leading: Icon(
              Icons.event_outlined,
              color: Theme.of(ctx).colorScheme.primary,
              size: 22,
            ),
            title: agendaAlunoDefaultTitle(ag.titulo),
            subtitle: agendaAlunoDiaLabel(ag.inicio, ag.fim),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${s.agendaAlunoStatus}: ${agendaAlunoStatusLabel(ag)}',
                  style: FocuxHubTypography.body(color: chrome.ink),
                ),
                const SizedBox(height: TokensStrip.s1),
                Text(
                  '${s.agendaAlunoDuracao}: ${ag.fim.difference(ag.inicio).inMinutes} min',
                  style: FocuxHubTypography.body(color: chrome.ink),
                ),
                if (obs.isNotEmpty) ...[
                  const SizedBox(height: TokensStrip.s3),
                  Text(
                    s.agendaAlunoObservacoes,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                  Text(obs, style: FocuxHubTypography.body(color: chrome.ink)),
                ],
                if (futura) ...[
                  const SizedBox(height: TokensStrip.s4),
                  if (agendaAlunoPodeConfirmar(ag)) ...[
                    FxLiquidPrimaryButton(
                      label: s.agendaAlunoConfirmarPresenca,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _confirmar(ag);
                      },
                    ),
                    const SizedBox(height: TokensStrip.s2),
                  ],
                  FxTonalButton(
                    label: s.agendaAlunoNaoVou,
                    expanded: true,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _naoVou(ag);
                    },
                  ),
                ],
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: s.agendaAlunoTitulo,
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: s.agendaAlunoTitulo,
          subtitle: _loading ? s.agendaAlunoCarregando : freshness,
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
          actions: [
            IconButton(
              tooltip: s.agendaAlunoMaisOpcoes,
              icon: const Icon(Icons.more_horiz_rounded),
              onPressed: _menu,
            ),
          ],
        ),
        body: FxContentWidthLimiter(
          child:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 4),
                  )
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: primary,
                    title: FocuxMicrocopy.naoFoiPossivelCarregar,
                    message: _erro!,
                    onRetry: _load,
                  )
                  : _buildList(s, chrome, primary),
        ),
      ),
    );
  }

  Widget _proximaCard(S s, Agendamento ag, ShellPalette chrome) {
    final podeConfirmar = agendaAlunoPodeConfirmar(ag);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(
        context,
        accent: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.agendaAlunoProxima,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s1),
          InkWell(
            onTap: () => _abrirDetalhe(ag),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agendaAlunoDiaLabel(ag.inicio, ag.fim),
                  style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${agendaAlunoDefaultTitle(ag.titulo)} · ${podeConfirmar ? s.agendaAlunoFaltaConfirmar : s.agendaAlunoConfirmada}',
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          if (podeConfirmar) ...[
            FxLiquidPrimaryButton(
              label: s.agendaAlunoConfirmarPresenca,
              onPressed: () => _confirmar(ag),
            ),
            const SizedBox(height: TokensStrip.s2),
          ],
          FxTonalButton(
            label: s.agendaAlunoNaoVou,
            expanded: true,
            onPressed: () => _naoVou(ag),
          ),
        ],
      ),
    );
  }

  Widget _buildList(S s, ShellPalette chrome, Color primary) {
    final proximas = agendaAlunoProximas(_proximas.items);
    final anteriores = agendaAlunoAnteriores(_anteriores.items);
    if (proximas.isEmpty && anteriores.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 48),
            FxEmptyState(
              icon: 'calendar',
              title: 'Nenhuma sessão marcada',
              subtitle:
                  'Seu personal ainda não agendou nada com você. Quando marcar, aparece aqui.',
              action: FxEmptyAction(
                label: 'Abrir chat',
                onTap: () => openAlunoRoute(context, '/chat/aluno'),
              ),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[
      if (proximas.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s3),
          child: Text(
            s.agendaAlunoSemProximas,
            style: FocuxHubTypography.bodyMuted(
              color: chrome.mute,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
      else
        _proximaCard(s, proximas.first, chrome),
      if (proximas.length > 1) ...[
        const SizedBox(height: TokensStrip.s3),
        DashboardSectionHeader(title: s.agendaAlunoProximas),
        for (final ag in proximas.skip(1)) _tile(ag, chrome, primary),
      ],
      if (_proximas.hasMore) _loadMoreTile(s, _proximas),
      if (anteriores.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s3),
        DashboardSectionHeader(
          title: s.agendaAlunoAnteriores,
          actionLabel:
              _anterioresAbertas
                  ? s.agendaAlunoOcultarAnteriores
                  : s.agendaAlunoVerAnteriores,
          onAction:
              () => setState(() => _anterioresAbertas = !_anterioresAbertas),
        ),
        if (_anterioresAbertas) ...[
          for (final ag in anteriores) _tile(ag, chrome, primary),
          if (_anteriores.hasMore) _loadMoreTile(s, _anteriores),
        ],
      ],
    ];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s5,
        ),
        itemCount: rows.length,
        itemBuilder: (_, i) => rows[i],
      ),
    );
  }

  Widget _loadMoreTile(S s, _Secao secao) => FxSatelliteListTile(
    title:
        secao.loadingMore ? s.agendaAlunoCarregando : s.agendaAlunoCarregarMais,
    onTap: secao.loadingMore ? null : () => _carregarMais(secao),
  );

  Widget _tile(Agendamento ag, ShellPalette chrome, Color primary) {
    final passou = agendaAlunoJaPassou(ag);
    final atendimento = ag.statusAtendimento?.trim().toUpperCase();
    final cor =
        passou && atendimento == null && agendaStatusIsActionable(ag.status)
            ? chrome.mute
            : agendaStatusColor(
              passou ? (atendimento ?? ag.status) : ag.status,
              isDark: chrome.isDark,
              primary: primary,
            );
    return FxSatelliteListTile(
      title: agendaAlunoDefaultTitle(ag.titulo),
      titleCase: false,
      muted: passou,
      subtitle: Text(agendaAlunoDiaLabel(ag.inicio, ag.fim)),
      trailing: Text(
        agendaAlunoStatusLabel(ag),
        style: FocuxHubTypography.bodyMuted(
          color: cor,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: () => _abrirDetalhe(ag),
    );
  }
}
