import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/captura_repository.dart';
import '../utils/leads_publicos_display.dart';

final _repoProvider = Provider(
  (ref) => CapturaRepository(ref.read(apiClientProvider)),
);

enum _LeadPublicoAcao { criarAluno, converter }

class LeadsPublicosScreen extends ConsumerStatefulWidget {
  const LeadsPublicosScreen({super.key});

  @override
  ConsumerState<LeadsPublicosScreen> createState() =>
      _LeadsPublicosScreenState();
}

class _LeadsPublicosScreenState extends ConsumerState<LeadsPublicosScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<SubmissaoCaptura> _leads = [];
  var _loading = true;
  var _carregandoMais = false;
  var _hasMore = false;
  var _page = 0;
  var _total = 0;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = LeadPublicoChip.todos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/leads');
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (!mounted || next == _query) return;
      _query = next;
      _carregar();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    if (_query.isEmpty) return;
    _query = '';
    _carregar();
  }

  void _clearFiltros() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    final hadFilter = leadPublicoHasActiveFilter(query: _query, chip: _chip);
    if (!hadFilter) return;
    setState(() {
      _query = '';
      _chip = LeadPublicoChip.todos;
    });
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await ref.read(_repoProvider).meus(
        q: _query,
        convertido: leadPublicoConvertidoParam(_chip),
      );
      if (!mounted) return;
      setState(() {
        _leads = pagina.content;
        _page = pagina.page ?? 0;
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? pagina.content.length;
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

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final pagina = await ref.read(_repoProvider).meus(
        page: _page + 1,
        q: _query,
        convertido: leadPublicoConvertidoParam(_chip),
      );
      if (!mounted) return;
      final seen = _leads.map((l) => l.id).toSet();
      setState(() {
        _leads = [
          ..._leads,
          ...pagina.content.where((l) => seen.add(l.id)),
        ];
        _page = pagina.page ?? _page + 1;
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _total;
        _carregandoMais = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
    }
  }

  void _abrirNovoAluno({String? nome, String? email}) {
    HapticFeedback.selectionClick();
    final q = <String, String>{
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (nome != null && nome.trim().isNotEmpty) 'nome': nome.trim(),
    };
    if (q.isEmpty) {
      context.push('/alunos/novo');
      return;
    }
    context.push(Uri(path: '/alunos/novo', queryParameters: q).toString());
  }

  Future<void> _marcarConvertido(SubmissaoCaptura lead) async {
    try {
      await ref.read(_repoProvider).marcarConvertido(lead.id);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _abrirAcoes(SubmissaoCaptura lead) async {
    if (lead.convertido) return;
    final items = <FxInsetPickerSheetItem<_LeadPublicoAcao>>[
      if (leadPublicoPodeCriarAluno(lead.email))
        const FxInsetPickerSheetItem(
          value: _LeadPublicoAcao.criarAluno,
          label: 'Converter em aluno',
        ),
      const FxInsetPickerSheetItem(
        value: _LeadPublicoAcao.converter,
        label: 'Marcar como convertido',
      ),
    ];
    final picked = await showFxInsetPickerSheet<_LeadPublicoAcao>(
      context,
      title: leadPublicoNome(lead.nome),
      items: items,
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case _LeadPublicoAcao.criarAluno:
        _abrirNovoAluno(nome: lead.nome, email: lead.email);
      case _LeadPublicoAcao.converter:
        await _marcarConvertido(lead);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Leads do link público',
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
          dismissKeyboard: true,
          appBar: FxShellAppBar(
            title: 'Leads do link público',
            subtitle: FxHubFreshness.joinCount(
              leadPublicoCountLabel(_loading ? 0 : _total),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar os leads públicos',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Leads do link',
                  subtitle: 'Contatos que chegaram pela sua página pública.',
                  tips: const [
                    FxHelpTip(
                      'Converter em aluno',
                      'No card, abre o cadastro já com nome e e-mail do lead.',
                    ),
                    FxHelpTip(
                      'Marcar convertido',
                      'Toque no lead novo para marcar quando virar aluno.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
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
                      isDense: true,
                      hintText: 'Buscar por nome, e-mail ou objetivo',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: primary,
                        size: 20,
                      ),
                      suffixIcon: _query.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: _clearQuery,
                              icon: Icon(
                                Icons.close_rounded,
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
                    for (final chip in LeadPublicoChip.values)
                      FxToggleChip(
                        label: leadPublicoChipLabel(chip),
                        selected: _chip == chip,
                        isDark: chrome.isDark,
                        onTap: () {
                          if (_chip == chip) return;
                          setState(() => _chip = chip);
                          _carregar();
                        },
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 5),
                      )
                    : _erro != null
                    ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: _carregar,
                      )
                    : FxContentWidthLimiter(child: _buildBody()),
              ),
              if (!_loading && _erro == null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3 +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: leadPublicoStickyLabel(),
                      onPressed: () => context.push('/perfil/landing-editor'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final primary = Theme.of(context).colorScheme.primary;
    final filtered = leadPublicoHasActiveFilter(query: _query, chip: _chip);
    return RefreshIndicator(
      color: primary,
      onRefresh: _carregar,
      child: _leads.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                0,
                0,
                0,
                TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                FxEmptyState(
                  icon: filtered ? 'search' : 'users',
                  title: filtered
                      ? 'Nenhum lead encontrado'
                      : 'Nenhum lead ainda',
                  subtitle: filtered
                      ? 'Ajuste a busca ou o filtro.'
                      : 'Compartilhe o link da página pública. Para virar aluno, toque no lead e escolha Converter.',
                  // Sticky já oferece Abrir página pública — evita CTA duplicado.
                  action: filtered
                      ? FxEmptyAction(
                          label: 'Limpar filtros',
                          onTap: _clearFiltros,
                        )
                      : null,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              itemCount: _leads.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (_hasMore && i == _leads.length) {
                  return FxSatelliteListTile(
                    title: _carregandoMais ? 'Carregando…' : 'Carregar mais',
                    onTap: _carregandoMais ? null : _carregarMais,
                  );
                }
                final lead = _leads[i];
                return FxSatelliteListTile(
                  title: leadPublicoNome(lead.nome),
                  subtitle: Text(
                    leadPublicoSubtitle(
                      telefone: lead.telefone,
                      email: lead.email,
                      objetivo: lead.objetivo,
                    ),
                  ),
                  trailing: Text(
                    leadPublicoValue(lead.convertido),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  accent: lead.convertido ? null : primary,
                  onTap: () => _abrirAcoes(lead),
                );
              },
            ),
    );
  }
}
