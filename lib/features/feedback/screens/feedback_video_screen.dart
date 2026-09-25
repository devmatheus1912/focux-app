import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/safe_external_launch.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../planos/utils/plano_capability.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../data/feedback_video_repository.dart';
import '../utils/feedback_video_display.dart';

part 'feedback_video_screen_form.part.dart';

enum _FeedbackVideoAcao { abrir, deletar }

class FeedbackVideoScreen extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const FeedbackVideoScreen({super.key, this.alunoId, this.alunoNome});

  @override
  ConsumerState<FeedbackVideoScreen> createState() =>
      _FeedbackVideoScreenState();
}

class _FeedbackVideoScreenState extends ConsumerState<FeedbackVideoScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _feedbacks = <FeedbackVideo>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasNext = false;
  var _page = 0;
  var _total = 0;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  Timer? _searchDebounce;

  String get _parentRoute => widget.alunoId == null
      ? '/dashboard/personal'
      : '/alunos/${widget.alunoId}';

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _load(reset: true);
    });
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _erro = null;
        _page = 0;
        _feedbacks.clear();
        _hasNext = false;
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }
    try {
      final pagina = await FeedbackVideoRepository(
        ref.read(apiClientProvider),
      ).listarPagina(
        page: reset ? 0 : _page,
        alunoId: widget.alunoId,
        q: _query,
      );
      if (!mounted) return;
      setState(() {
        _feedbacks.addAll(pagina.content);
        _hasNext = pagina.hasNext;
        _page = (pagina.page ?? 0) + 1;
        _total = pagina.totalElements ?? _feedbacks.length;
        _loading = false;
        _loadingMore = false;
        if (reset) _fetchedAt = DateTime.now();
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

  Future<void> _abrirVideo(String url) async {
    final opened = await launchSafeHttpUrl(url);
    if (!opened && mounted) {
      FeedbackHelper.showError(context, 'Não foi possível abrir a URL');
    }
  }

  Future<void> _deletar(FeedbackVideo item) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Remover feedback?',
      subtitle: feedbackVideoLabel(item.comentario),
      message: 'O vídeo some desta lista. Dá para registrar de novo depois.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).deletar(item.id);
      if (!mounted) return;
      setState(() => _feedbacks.removeWhere((f) => f.id == item.id));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _abrirAcoes(FeedbackVideo item) async {
    final picked = await showFxInsetPickerSheet<_FeedbackVideoAcao>(
      context,
      title: feedbackVideoLabel(item.comentario),
      items: const [
        FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.abrir,
          label: 'Assistir vídeo',
        ),
        FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.deletar,
          label: 'Remover',
        ),
      ],
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case _FeedbackVideoAcao.abrir:
        await _abrirVideo(item.videoUrl);
      case _FeedbackVideoAcao.deletar:
        await _deletar(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final visible = _feedbacks;
    final count = _total;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Feedback de vídeo',
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          FxKeyboardDismissScope.dismiss();
          safePopOrGo(context, _parentRoute);
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title:
                widget.alunoNome != null
                    ? 'Feedbacks — ${widget.alunoNome}'
                    : 'Feedbacks de vídeo',
            subtitle: FxHubFreshness.joinCount(
              feedbackVideoCountLabel(_loading ? 0 : count),
              _loading ? null : FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, _parentRoute);
            },
            actions: [
              FxHelpIconButton(
                tooltip: 'Ajuda — feedback de vídeo',
                onTap:
                    () => showFxHelpSheet(
                      context,
                      title: 'Feedback de vídeo',
                      subtitle: feedbackVideoHelpTip,
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
                      filled: false,
                      isDense: true,
                      hintText: 'Buscar comentário',
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
                      suffixIcon:
                          _query.trim().isEmpty
                              ? null
                              : IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _searchDebounce?.cancel();
                                  _searchCtrl.clear();
                                  setState(() => _query = '');
                                  _load(reset: true);
                                },
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
                          onRetry: () => _load(reset: true),
                          title: 'Não conseguimos carregar os feedbacks',
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
                      TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Novo feedback',
                      onPressed: _novoFeedback,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(List<FeedbackVideo> visible) {
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            if (filtered)
              FxEmptyState(
                icon: 'search',
                title: 'Nenhum feedback encontrado',
                subtitle: 'Ajuste a busca para ver outros comentários.',
                action: FxEmptyAction(
                  label: 'Limpar busca',
                  onTap: () {
                    _searchDebounce?.cancel();
                    _searchCtrl.clear();
                    setState(() => _query = '');
                    _load(reset: true);
                  },
                ),
              )
            else
              FxEmptyState(
                key: const ValueKey('feedback_video_empty'),
                icon: 'spark',
                title: 'Nenhum feedback de vídeo',
                subtitle:
                    widget.alunoNome != null
                        ? 'Peça a ${satelliteFirstName(widget.alunoNome)} um vídeo de execução ou use Novo feedback abaixo.'
                        : 'Use Novo feedback abaixo para registrar o primeiro comentário técnico.',
              ),
          ],
        ),
      );
    }

    final showMore = _hasNext;
    return RefreshIndicator(
      color: primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: visible.length + (showMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (showMore && i == visible.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : () => _load(reset: false),
            );
          }
          final item = visible[i];
          return FxSatelliteListTile(
            title: feedbackVideoLabel(item.comentario),
            subtitle: Text(
              feedbackVideoSubtitle(
                criadoEm: item.criadoEm,
                aiScore: item.aiScore,
                statusAnalise: item.statusAnalise,
              ),
            ),
            trailing: Text(
              feedbackVideoValue(item.aiScore),
              style: FocuxHubTypography.bodyMuted(
                color:
                    feedbackVideoDanger(item.aiScore)
                        ? EagleTokens.bad
                        : fxScreenMute(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: feedbackVideoDanger(item.aiScore) ? EagleTokens.bad : null,
            onTap: () => _abrirAcoes(item),
          );
        },
      ),
    );
  }
}
