import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/alertas_repository.dart';
import '../utils/alerta_detalhe_display.dart';
import '../widgets/alerta_enviar_mensagem_sheet.dart';

class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
  final _openedAt = DateTime.now();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<AlertaRisco> _alertas = [];
  AlertasConfiguracao? _config;
  var _page = 0;
  var _hasMore = false;
  var _totalRiscos = 0;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;
  var _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _query = value);
      _load();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _load();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/dashboard/personal');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final home =
          await AlertasRepository(ref.read(apiClientProvider)).getHome(
            q: _query,
          );
      if (!mounted) return;
      setState(() {
        _alertas = home.riscos;
        _config = home.configuracao;
        _page = home.page;
        _hasMore = home.hasNext;
        _totalRiscos = home.totalRiscos;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final home = await AlertasRepository(
        ref.read(apiClientProvider),
      ).getHome(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _alertas.map((a) => a.alunoId).toSet();
      setState(() {
        _alertas = [
          ..._alertas,
          ...home.riscos.where((a) => seen.add(a.alunoId)),
        ];
        _page = home.page;
        _hasMore = home.hasNext;
        _totalRiscos = home.totalRiscos;
        _config = home.configuracao;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    final altos = _alertas.where((a) => a.score >= 2).length;
    AnalyticsService.instance.track(
      ProductEvents.alertasHubViewed,
      props: {'count': _alertas.length, 'altos': altos},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.alertasHubTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
          'count': _alertas.length,
        },
      );
    }
  }

  Future<void> _abrirConfig() async {
    final changed = await context.push<bool>('/alertas/config');
    if (changed == true && mounted) _load();
  }

  Future<void> _resolverAlerta(AlertaRisco alerta) async {
    try {
      await AlertasRepository(
        ref.read(apiClientProvider),
      ).resolver(alerta.alunoId);
      setState(() => _alertas.removeWhere((a) => a.alunoId == alerta.alunoId));
      if (mounted) {
        FeedbackHelper.showSuccess(context, alertaAdiadoSuccessMessage());
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _enviarMensagemChat(AlertaRisco alerta) async {
    final texto = await showAlertaEnviarMensagemSheet(
      context,
      draft: alertaMensagemDraft(alunoNome: alerta.alunoNome),
    );
    if (texto == null || !mounted) return;

    try {
      await AlertasRepository(
        ref.read(apiClientProvider),
      ).enviarMensagemChat(alerta.alunoId, texto);
      if (mounted) {
        FeedbackHelper.showSuccess(context, alertaMensagemEnviadaSuccess());
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _openAlerta(AlertaRisco alerta) {
    AnalyticsService.instance.track(
      ProductEvents.alertaRiscoOpened,
      props: {
        'feature': 'alertas',
        'aluno_id': alerta.alunoId,
        'score': alerta.score,
      },
    );
    context.push('/alertas/aluno/${alerta.alunoId}', extra: alerta.alunoNome);
  }

  void _openActions(AlertaRisco alerta) {
    HapticFeedback.selectionClick();
    showFxHomeSheet<void>(
      context,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: FxSettingsLayout.headerToGroup),
              FxHomeSheetHeader(
                isDark: isDark,
                leading: const Icon(Icons.person_outline_rounded, size: 18),
                title: alerta.alunoNome,
                subtitle:
                    alerta.motivos.isEmpty
                        ? 'O que você quer fazer agora?'
                        : alerta.motivos.first,
              ),
              const SizedBox(height: TokensStrip.s3),
              FxLiquidPrimaryButton(
                label: alertaEnviarMensagemCtaLabel(),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _enviarMensagemChat(alerta);
                },
              ),
              const SizedBox(height: TokensStrip.s2),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _resolverAlerta(alerta);
                },
                child: Text(alertaAdiarCtaLabel()),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = Theme.of(context).colorScheme.primary;
    final mute = fxScreenMute(context);
    final altos = _alertas.where((a) => a.score >= 2).toList();
    final medios = _alertas.where((a) => a.score == 1).toList();
    final rows = <_HubRow>[
      if (_config != null) _HubRow.config(_config!),
      for (final item in altos) _HubRow.risco(item, 'alto'),
      for (final item in medios) _HubRow.risco(item, 'medio'),
    ];
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final emptyFiltered =
        !_loading && _erro == null && _query.trim().isNotEmpty && _alertas.isEmpty;

    Widget configTile(AlertasConfiguracao config) {
      return FxSatelliteListTile(
        title: 'Quando dispara',
        subtitle: Text(
          'Sem treino acima de ${config.diasSemTreino} dias ou aderência abaixo de ${config.aderenciaMinima}%.',
        ),
        trailing: Text(
          '${config.diasSemTreino}d · ${config.aderenciaMinima}%',
          style: FocuxHubTypography.bodyMuted(
            color: mute,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: _abrirConfig,
      );
    }

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Alertas',
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          _leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Alertas',
          subtitle:
              _loading
                  ? freshness
                  : alertaListSubtitle(
                    totalRiscos: _totalRiscos,
                    freshness: freshness,
                  ),
          onBack: _leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar os alertas',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.alertasHubHelpOpened,
                );
                showFxHelpSheet(
                  context,
                  title: 'Alertas',
                  subtitle:
                      'Quem está esfriando. O check-in live continua no aluno.',
                  tips: const [
                    FxHelpTip('Como calculamos', alertaComoCalculamos),
                    FxHelpTip(
                      'Lista',
                      'Toque no aluno para o detalhe. Segure para escrever ou adiar 24h.',
                    ),
                    FxHelpTip('Limiares', 'Ajuste em Quando dispara.'),
                  ],
                );
              },
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
                  chromeOnDark: isDark,
                  primary: brand,
                  message: _erro!,
                  onRetry: _load,
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s2,
                        TokensStrip.s4,
                        TokensStrip.s2,
                      ),
                      child: DecoratedBox(
                        decoration: fxStripCardDecoration(
                          context,
                          accent: brand,
                          radius: TokensStrip.rCard,
                          glowStrength: 0.03,
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          onChanged: _onQueryChanged,
                          onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Buscar aluno ou motivo',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: brand,
                              size: 20,
                            ),
                            suffixIcon:
                                _query.trim().isEmpty
                                    ? null
                                    : IconButton(
                                      tooltip: 'Limpar busca',
                                      onPressed: _clearQuery,
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: mute,
                                        size: 18,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: brand,
                        onRefresh: () async {
                          AnalyticsService.instance.track(
                            ProductEvents.alertasHubRefreshed,
                          );
                          await _load();
                        },
                        child:
                            emptyFiltered
                                ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  children: [
                                    SizedBox(
                                      height: 280,
                                      child: FxEmptyState(
                                        icon: 'search',
                                        title: 'Nada encontrado',
                                        subtitle:
                                            'Ajuste a busca para achar outro aluno em risco.',
                                        action: FxEmptyAction(
                                          label: 'Limpar busca',
                                          onTap: _clearQuery,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : _alertas.isEmpty
                                ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: const EdgeInsets.fromLTRB(
                                    TokensStrip.s4,
                                    TokensStrip.s2,
                                    TokensStrip.s4,
                                    TokensStrip.s6,
                                  ),
                                  children: [
                                    if (_config != null) configTile(_config!),
                                    SizedBox(
                                      height: 280,
                                      child: FxEmptyState(
                                        icon: 'circle-check',
                                        title: 'Nenhum aluno em risco',
                                        subtitle:
                                            'Avisamos aqui quando alguém esfriar. Você pode apertar ou folgar os limiares.',
                                        action:
                                            _config == null
                                                ? null
                                                : FxEmptyAction(
                                                  label: 'Ajustar limiares',
                                                  onTap: _abrirConfig,
                                                ),
                                      ),
                                    ),
                                  ],
                                )
                                : FxContentWidthLimiter(
                                  child: ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    keyboardDismissBehavior:
                                        ScrollViewKeyboardDismissBehavior
                                            .onDrag,
                                    padding: EdgeInsets.fromLTRB(
                                      TokensStrip.s4,
                                      TokensStrip.s2,
                                      TokensStrip.s4,
                                      TokensStrip.s6 +
                                          MediaQuery.viewInsetsOf(
                                            context,
                                          ).bottom,
                                    ),
                                    itemCount:
                                        rows.length + (_hasMore ? 1 : 0),
                                    itemBuilder: (context, i) {
                                      if (_hasMore && i == rows.length) {
                                        return FxSatelliteListTile(
                                          title:
                                              _carregandoMais
                                                  ? 'Carregando…'
                                                  : 'Carregar mais',
                                          onTap:
                                              _carregandoMais
                                                  ? null
                                                  : _carregarMais,
                                        );
                                      }
                                      final row = rows[i];
                                      if (row.config != null) {
                                        return configTile(row.config!);
                                      }
                                      final alerta = row.alerta!;
                                      final showSection =
                                          i == 0 ||
                                          rows[i - 1].section != row.section;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          if (showSection &&
                                              row.section == 'alto')
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                bottom: TokensStrip.s2,
                                              ),
                                              child: DashboardSectionHeader(
                                                title: 'Alto',
                                              ),
                                            ),
                                          if (showSection &&
                                              row.section == 'medio')
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                top: TokensStrip.s2,
                                                bottom: TokensStrip.s2,
                                              ),
                                              child: DashboardSectionHeader(
                                                title: 'Médio',
                                              ),
                                            ),
                                          GestureDetector(
                                            onLongPress:
                                                () => _openActions(alerta),
                                            child: FxSatelliteListTile(
                                              title: alerta.alunoNome,
                                              subtitle:
                                                  alerta.motivos.isEmpty
                                                      ? null
                                                      : Text(
                                                        alerta.motivos.first,
                                                      ),
                                              leading: AlunoAvatar(
                                                name: alerta.alunoNome,
                                                variant:
                                                    AlunoAvatarVariant.strip,
                                              ),
                                              trailing: Text(
                                                '${alerta.diasSemTreino ?? 0}d',
                                                style:
                                                    FocuxHubTypography.bodyMuted(
                                                      color: mute,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              accent:
                                                  alerta.score >= 2
                                                      ? brand
                                                      : null,
                                              onTap: () => _openAlerta(alerta),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
      ),
      ),
    );
  }
}

class _HubRow {
  const _HubRow._({this.config, this.alerta, required this.section});

  factory _HubRow.config(AlertasConfiguracao config) =>
      _HubRow._(config: config, section: 'config');

  factory _HubRow.risco(AlertaRisco alerta, String section) =>
      _HubRow._(alerta: alerta, section: section);

  final AlertasConfiguracao? config;
  final AlertaRisco? alerta;
  final String section;
}
