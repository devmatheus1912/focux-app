import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';
import '../utils/grupo_aula_display.dart';
import '../widgets/grupo_aula_alunos_sheet.dart';
import '../widgets/grupo_aula_detalhe_sheet.dart';
import '../widgets/grupo_aula_form_sheet.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/theme/fx_icons.dart';

class GrupoAulasPersonalScreen extends ConsumerStatefulWidget {
  const GrupoAulasPersonalScreen({super.key});

  @override
  ConsumerState<GrupoAulasPersonalScreen> createState() =>
      _GrupoAulasPersonalScreenState();
}

class _GrupoAulasPersonalScreenState
    extends ConsumerState<GrupoAulasPersonalScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<GrupoAula> _aulas = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = GrupoAulaChip.todas;
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
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
    _searchCtrl.clear();
    setState(() => _query = '');
    _load();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _chip = GrupoAulaChip.todas;
    });
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
      final pagina = await GrupoAulaRepository(
        ref.read(apiClientProvider),
      ).listarPersonalPagina(q: _query, chip: _chip);
      if (mounted) {
        setState(() {
          _aulas = pagina.content;
          _page = pagina.page ?? 0;
          _hasMore = pagina.hasNext;
          _total = pagina.totalElements ?? pagina.content.length;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await GrupoAulaRepository(
        ref.read(apiClientProvider),
      ).listarPersonalPagina(page: _page + 1, q: _query, chip: _chip);
      if (!mounted) return;
      final seen = _aulas.map((a) => a.id).toSet();
      setState(() {
        _aulas = [..._aulas, ...pagina.content.where((a) => seen.add(a.id))];
        _page = pagina.page ?? (_page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _aulas.length;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  GrupoAulaRepository get _repo =>
      GrupoAulaRepository(ref.read(apiClientProvider));

  Future<void> _criar() async {
    HapticFeedback.selectionClick();
    List<Aluno>? alunos;
    try {
      alunos = (await ref.read(alunosHomeProvider.future)).alunos;
    } catch (_) {
      alunos = const [];
    }
    if (!mounted) return;
    final rascunho = await showGrupoAulaFormSheet(context, alunos: alunos);
    if (rascunho == null || !mounted) return;
    try {
      await _repo.criar(
        titulo: rascunho.titulo,
        descricao: rascunho.descricao,
        inicio: rascunho.inicio,
        fim: rascunho.fim,
        capacidadeMax: rascunho.capacidade,
        localAula: rascunho.local,
        alunoIds: rascunho.alunoIds,
      );
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        rascunho.alunoIds.isEmpty
            ? 'Aula criada'
            : 'Aula criada e ${grupoAulaAlunosEscolhidosLabel(rascunho.alunoIds.length)} avisado(s)',
      );
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _openAula(GrupoAula aula) async {
    final acao = await showGrupoAulaDetalheSheet(
      context,
      aula: aula,
      inscritos: _repo.inscritos(aula.id),
    );
    if (acao == null || !mounted) return;
    switch (acao) {
      case GrupoAulaAcao.inscrever:
        await _inscrever(aula);
      case GrupoAulaAcao.editar:
        await _editar(aula);
      case GrupoAulaAcao.cancelar:
        await _cancelar(aula);
    }
  }

  Future<void> _inscrever(GrupoAula aula) async {
    try {
      final alunos = (await ref.read(alunosHomeProvider.future)).alunos;
      final ja = (await _repo.inscritos(aula.id)).map((i) => i.alunoId).toSet();
      if (!mounted) return;
      final livres = alunos.where((a) => !ja.contains(a.id)).toList();
      final vagas = aula.capacidadeMax - aula.inscritos;
      if (livres.isEmpty || vagas <= 0) {
        FeedbackHelper.showWarn(
          context,
          vagas <= 0 ? 'Aula lotada.' : 'Todos os alunos já estão inscritos.',
        );
        return;
      }
      final escolha = await showGrupoAulaAlunosSheet(
        context,
        alunos: livres,
        selecionados: const {},
        limite: vagas,
      );
      if (escolha == null || escolha.isEmpty || !mounted) return;
      await _repo.inscreverAlunos(aula.id, escolha.toList());
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        '${grupoAulaAlunosEscolhidosLabel(escolha.length)} inscrito(s) e avisado(s)',
      );
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _editar(GrupoAula aula) async {
    final rascunho = await showGrupoAulaFormSheet(
      context,
      aula: aula,
      minimoCapacidade: aula.inscritos < 1 ? 1 : aula.inscritos,
    );
    if (rascunho == null || !mounted) return;
    try {
      await _repo.editar(
        aula.id,
        titulo: rascunho.titulo,
        descricao: rascunho.descricao,
        inicio: rascunho.inicio,
        fim: rascunho.fim,
        capacidadeMax: rascunho.capacidade,
        localAula: rascunho.local,
      );
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Aula salva');
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _cancelar(GrupoAula aula) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Cancelar "${aula.titulo}"?',
      message:
          aula.inscritos == 0
              ? 'A aula sai da lista dos alunos.'
              : 'Os ${aula.inscritos} inscritos recebem um aviso de que a aula foi cancelada.',
      confirmLabel: 'Cancelar aula',
      cancelLabel: 'Manter',
      destructive: true,
      icon: FxIcons.excluir,
    );
    if (!ok || !mounted) return;
    try {
      await _repo.cancelar(aula.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Aula cancelada');
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// Sem nenhuma aula (e sem filtro), busca e filtros não têm o que fazer.
  bool get _mostrarFiltros =>
      _total > 0 || _query.trim().isNotEmpty || _chip != GrupoAulaChip.todas;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final visible = _aulas;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Aulas em grupo',
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
          comFundo: true,
          appBar: FxShellAppBar(
            title: 'Aulas em grupo',
            subtitle: FxHubFreshness.joinCount(
              grupoAulaCountLabel(_total),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar aulas em grupo',
                onTap:
                    () => showFxHelpSheet(
                      context,
                      title: 'Aulas em grupo',
                      subtitle: 'Turmas com vaga para o aluno se inscrever.',
                      tips: const [
                        FxHelpTip(
                          'Criar',
                          'O botão no rodapé abre título, horário e capacidade.',
                        ),
                        FxHelpTip(
                          'Turma',
                          'Toque na aula para ver quem se inscreveu, inscrever alunos, editar ou cancelar.',
                        ),
                      ],
                    ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (_mostrarFiltros) ...[
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
                      accent: primary,
                      radius: TokensStrip.rCard,
                      glowStrength: 0.03,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onChanged: _onQueryChanged,
                      onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        hintText: 'Buscar aula ou local',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          FxIcons.buscar,
                          color: primary,
                          size: 20,
                        ),
                        suffixIcon:
                            _query.trim().isEmpty
                                ? null
                                : IconButton(
                                  tooltip: 'Limpar busca',
                                  onPressed: _clearQuery,
                                  icon: Icon(
                                    FxIcons.fechar,
                                    color: chrome.mute,
                                    size: 18,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: Wrap(
                    spacing: TokensStrip.s2,
                    runSpacing: TokensStrip.s2,
                    children: [
                      for (final chip in GrupoAulaChip.values)
                        FxToggleChip(
                          label: grupoAulaChipLabel(chip),
                          selected: _chip == chip,
                          isDark: chrome.isDark,
                          onTap: () {
                            if (_chip == chip) return;
                            setState(() => _chip = chip);
                            _load();
                          },
                        ),
                    ],
                  ),
                ),
              ],
              Expanded(
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
                          message: _erro!,
                          onRetry: _load,
                        )
                        : FxContentWidthLimiter(child: _buildBody(visible)),
              ),
              if (!_loading && _erro == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Nova aula',
                      onPressed: _criar,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<GrupoAula> visible) {
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty || _chip != GrupoAulaChip.todas;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: filtered ? FxIcons.buscar : FxIcons.calendario,
              title:
                  filtered
                      ? 'Nenhuma aula encontrada'
                      : 'Nenhuma aula criada ainda',
              subtitle:
                  filtered
                      ? 'Ajuste a busca ou o filtro.'
                      : 'Crie uma aula em grupo para abrir vagas aos seus alunos.',
              // "Nova aula" mora só no rodapé fixo: um botão por tela.
              action:
                  filtered
                      ? FxEmptyAction(
                        label: 'Limpar filtros',
                        secondary: true,
                        onTap: _clearFilters,
                      )
                      : null,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length + 1 + (_hasMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: TokensStrip.s3),
              child: DashboardSectionHeader(title: 'Próximas aulas'),
            );
          }
          if (_hasMore && i == visible.length + 1) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : _carregarMais,
            );
          }
          final aula = visible[i - 1];
          final lotada =
              aula.cancelada ||
              grupoAulaLotada(
                inscritos: aula.inscritos,
                capacidadeMax: aula.capacidadeMax,
              );
          return FxSatelliteListTile(
            title: aula.titulo,
            subtitle: Text(
              grupoAulaLinha(
                inicio: aula.inicio,
                fim: aula.fim,
                localAula: aula.localAula,
              ),
            ),
            trailing: Text(
              grupoAulaOcupacaoLabel(
                inscritos: aula.inscritos,
                capacidadeMax: aula.capacidadeMax,
                status: aula.status,
              ),
              style: FocuxHubTypography.bodyMuted(
                color: lotada ? EagleTokens.bad : fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: lotada ? EagleTokens.bad : null,
            onTap: () => _openAula(aula),
          );
        },
      ),
    );
  }
}
