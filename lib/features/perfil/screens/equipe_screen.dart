import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/equipe_repository.dart';
import '../models/tenant_membro.dart';
import '../utils/equipe_display.dart';

final equipeRepositoryProvider = Provider(
  (ref) => EquipeRepository(ref.read(apiClientProvider)),
);

class EquipeScreen extends ConsumerStatefulWidget {
  const EquipeScreen({super.key});

  @override
  ConsumerState<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends ConsumerState<EquipeScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<TenantMembro> _membros = [];
  var _loading = true;
  var _carregandoMais = false;
  var _hasMore = false;
  var _page = 0;
  var _total = 0;
  String? _error;
  DateTime? _fetchedAt;
  var _query = '';
  var _chip = EquipeChip.todos;

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

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/perfil');
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (!mounted || next == _query) return;
      _query = next;
      _load();
    });
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    if (_query.isEmpty) return;
    _query = '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pagina = await ref.read(equipeRepositoryProvider).listar(
        q: _query,
        status: equipeStatusParam(_chip),
      );
      if (!mounted) return;
      setState(() {
        _membros = pagina.content;
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
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final pagina = await ref.read(equipeRepositoryProvider).listar(
        page: _page + 1,
        q: _query,
        status: equipeStatusParam(_chip),
      );
      if (!mounted) return;
      final seen = _membros.map((m) => m.id).toSet();
      setState(() {
        _membros = [
          ..._membros,
          ...pagina.content.where((m) => seen.add(m.id)),
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

  Future<void> _convidar() async {
    final ctrl = TextEditingController();
    var sent = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Convidar assistente',
        icon: Icons.mail_outline_rounded,
        confirmLabel: 'Convidar',
        child: AlunoInsetFormField(
          controller: ctrl,
          label: 'Email',
          icon: Icons.alternate_email_outlined,
          keyboardType: TextInputType.emailAddress,
          showDivider: false,
        ),
      );
      if (ok != true || ctrl.text.trim().isEmpty) return;
      await ref
          .read(equipeRepositoryProvider)
          .convidar(email: ctrl.text.trim());
      sent = true;
      if (mounted) FeedbackHelper.showSuccess(context, 'Convite enviado');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      ctrl.dispose();
    }
    if (sent) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chrome = ShellChrome.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Equipe',
      child: FeatureGate(
        featureName: 'Equipe',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'equipeRbac',
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
              title: 'Equipe',
              subtitle: FxHubFreshness.joinCount(
                equipeCountLabel(_loading ? 0 : _total),
                FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar a equipe',
                  onTap: () => showFxHelpSheet(
                    context,
                    title: 'Equipe',
                    subtitle: 'Convites e papéis de quem te ajuda na operação.',
                    tips: const [
                      FxHelpTip(
                        'Convidar',
                        'O botão de baixo envia o convite por e-mail.',
                      ),
                      FxHelpTip(
                        'Status',
                        'Convites ficam pendentes até a pessoa aceitar.',
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
                      accent: scheme.primary,
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
                        hintText: 'Buscar por e-mail ou papel',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: scheme.primary,
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
                      for (final chip in EquipeChip.values)
                        FxToggleChip(
                          label: equipeChipLabel(chip),
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
                Expanded(
                  child: _loading
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
                          title: 'Não conseguimos carregar a equipe',
                        )
                      : FxContentWidthLimiter(child: _buildBody()),
                ),
                if (!_loading && _error == null)
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
                        label: 'Convidar',
                        onPressed: _convidar,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final primary = Theme.of(context).colorScheme.primary;
    final filtered =
        _query.trim().isNotEmpty || _chip != EquipeChip.todos;
    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: _membros.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                FxEmptyState(
                  icon: filtered ? 'search' : 'users',
                  title: filtered
                      ? 'Nenhum membro encontrado'
                      : 'Nenhum membro',
                  subtitle: filtered
                      ? 'Ajuste a busca ou o filtro.'
                      : 'Convide assistentes para escalar sua operação.',
                  action: filtered
                      ? FxEmptyAction(
                          label: 'Limpar filtros',
                          onTap: _clearQuery,
                        )
                      : FxEmptyAction(label: 'Convidar', onTap: _convidar),
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
              itemCount: _membros.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (_hasMore && i == _membros.length) {
                  return FxSatelliteListTile(
                    title: _carregandoMais ? 'Carregando…' : 'Carregar mais',
                    onTap: _carregandoMais ? null : _carregarMais,
                  );
                }
                final membro = _membros[i];
                return FxSatelliteListTile(
                  title: membro.userEmail,
                  titleCase: false,
                  subtitle: Text(
                    equipeMembroSubtitle(
                      role: membro.role,
                      status: membro.status,
                    ),
                  ),
                  trailing: Text(
                    equipeStatusLabel(membro.status),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
