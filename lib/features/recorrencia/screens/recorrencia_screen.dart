import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/money/fx_money.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
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
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';

part 'recorrencia_screen_form.part.dart';

class RecorrenciaScreen extends ConsumerStatefulWidget {
  const RecorrenciaScreen({super.key});

  @override
  ConsumerState<RecorrenciaScreen> createState() => _RecorrenciaScreenState();
}

class _RecorrenciaScreenState extends ConsumerState<RecorrenciaScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  var _query = '';
  var _filtro = RecorrenciaHubFiltro.todos;
  List<RecorrenciaAssinatura> _items = [];
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loading = true;
  var _loadingMore = false;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == _query) return;
      _query = next;
      _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _erro = null;
        _page = 0;
        _items = [];
        _hasMore = false;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }
    try {
      final pagina = await RecorrenciaRepository(
        ref.read(apiClientProvider),
      ).listarPagina(
        page: reset ? 0 : _page + 1,
        q: _query,
        status: recorrenciaHubFiltroStatus(_filtro),
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = pagina.content;
          _fetchedAt = DateTime.now();
        } else {
          final seen = _items.map((i) => i.id).toSet();
          _items = [
            ..._items,
            ...pagina.content.where((i) => seen.add(i.id)),
          ];
        }
        _page = pagina.page ?? (reset ? 0 : _page + 1);
        _hasMore = pagina.hasNext;
        _total = pagina.totalElements ?? _items.length;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _abrirCheckout(String initPoint) async {
    final uri = Uri.tryParse(initPoint);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Recorrência MP',
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          FxKeyboardDismissScope.dismiss();
          safePopOrGo(context, '/financeiro');
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Recorrência MP',
            subtitle: FxHubFreshness.joinCount(
              recorrenciaCountLabel(_loading ? 0 : _total),
              _loading ? null : FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, '/financeiro');
            },
          ),
          body: _loading
              ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 5),
                )
              : _erro != null
              ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: () => _load(reset: true),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        8,
                        FxSettingsLayout.pageInset,
                        8,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: _onQueryChanged,
                        onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                        decoration: FxInputDeco.build(context, 'Buscar aluno'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        0,
                        FxSettingsLayout.pageInset,
                        8,
                      ),
                      child: Wrap(
                        spacing: TokensStrip.s2,
                        runSpacing: TokensStrip.s2,
                        children: [
                          for (final filtro in RecorrenciaHubFiltro.values)
                            FxToggleChip(
                              label: recorrenciaHubFiltroLabel(filtro),
                              selected: _filtro == filtro,
                              isDark: chrome.isDark,
                              onTap: () {
                                if (_filtro == filtro) return;
                                setState(() => _filtro = filtro);
                                _load(reset: true);
                              },
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: FxContentWidthLimiter(child: _buildBody()),
                    ),
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
                          label: 'Nova recorrência',
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

  Widget _buildBody() {
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: _items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              children: [
                FxEmptyState(
                  icon: _query.isEmpty && _filtro == RecorrenciaHubFiltro.todos
                      ? 'coin'
                      : 'search',
                  title: _query.isEmpty && _filtro == RecorrenciaHubFiltro.todos
                      ? 'Nenhuma assinatura ainda'
                      : 'Nenhuma assinatura encontrada',
                  subtitle: _query.isEmpty &&
                          _filtro == RecorrenciaHubFiltro.todos
                      ? 'Crie a primeira recorrência para cobrar seus alunos via Mercado Pago.'
                      : 'Ajuste a busca ou o filtro para ver outras assinaturas.',
                  action: _query.isEmpty &&
                          _filtro == RecorrenciaHubFiltro.todos
                      ? null
                      : FxEmptyAction(
                          label: 'Limpar filtros',
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() {
                              _query = '';
                              _filtro = RecorrenciaHubFiltro.todos;
                            });
                            _load(reset: true);
                          },
                        ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
                FxSettingsLayout.pageInset,
                TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              itemCount: _items.length + 1 + (_hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: TokensStrip.s3),
                    child: DashboardSectionHeader(title: 'Assinaturas'),
                  );
                }
                if (_hasMore && i == _items.length + 1) {
                  return FxSatelliteListTile(
                    title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    onTap: _loadingMore ? null : () => _load(reset: false),
                  );
                }
                final item = _items[i - 1];
                final danger = recorrenciaDanger(item.status);
                return FxSatelliteListTile(
                  title: recorrenciaAlunoLabel(item.alunoNome),
                  subtitle: Text(
                    recorrenciaSubtitle(
                      status: item.status,
                      proximaCobranca: item.proximaCobranca,
                    ),
                  ),
                  trailing: Text(
                    recorrenciaValorLabel(item.valor),
                    style: FocuxHubTypography.bodyMuted(
                      color: danger ? EagleTokens.bad : fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  accent: danger
                      ? EagleTokens.bad
                      : recorrenciaPendente(item.status)
                          ? primary
                          : null,
                  onTap: recorrenciaTemLinkCheckout(
                    item.status,
                    item.initPoint,
                  )
                      ? () => _abrirCheckout(item.initPoint!)
                      : null,
                );
              },
            ),
    );
  }
}
