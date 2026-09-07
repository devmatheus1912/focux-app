import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/feedback_video_repository.dart';
import '../utils/feedback_video_display.dart';
import '../widgets/feedback_aluno_enviar_sheet.dart';

class FeedbackAlunoScreen extends ConsumerStatefulWidget {
  const FeedbackAlunoScreen({super.key});

  @override
  ConsumerState<FeedbackAlunoScreen> createState() =>
      _FeedbackAlunoScreenState();
}

class _FeedbackAlunoScreenState extends ConsumerState<FeedbackAlunoScreen> {
  final _searchCtrl = TextEditingController();
  final _items = <FeedbackVideo>[];
  List<ExercicioOpcao> _exercicios = [];
  var _loading = true;
  var _loadingMore = false;
  var _hasNext = false;
  var _page = 0;
  String? _erro;
  DateTime? _fetchedAt;
  var _query = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
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
        _items.clear();
        _page = 0;
        _hasNext = false;
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }
    try {
      final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
      final pagina = await repo.listarMeus(
        page: reset ? 0 : _page,
        q: _query,
      );
      List<ExercicioOpcao>? exs;
      if (reset) {
        try {
          exs = await repo.exerciciosDisponiveis();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _items.addAll(pagina.content);
        _hasNext = pagina.hasNext;
        _page = (pagina.page ?? 0) + 1;
        if (exs != null) _exercicios = exs;
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

  Future<void> _enviar() async {
    if (_exercicios.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Você precisa de um treino atribuído pelo personal antes de enviar form-check.',
      );
      return;
    }

    final result = await showFxHomeSheet<FeedbackAlunoFormResult>(
      context,
      builder: (_) => FeedbackAlunoEnviarSheet(exercicios: _exercicios),
    );
    if (result == null) return;

    try {
      await FeedbackVideoRepository(ref.read(apiClientProvider)).enviarMeu(
        videoUrl: result.videoUrl,
        exercicioId: result.exercicioId,
        comentario: result.comentario,
      );
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Vídeo enviado! Análise IA em andamento — atualize em alguns segundos.',
        );
        _load(reset: true);
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Color _scoreColor(int? score) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return EagleTokens.scoreColor(score, isDark: isDark);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final mute = chrome.mute;

    return fxScreenA11yScope(
      label: 'Form check',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Form check',
          subtitle: FxHubFreshness.joinCount(
            feedbackVideoCountLabel(_items.length),
            FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
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
                  onChanged: _onQueryChanged,
                  onTapOutside:
                      (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar no comentário',
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
                        chromeOnDark: isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: () => _load(reset: true),
                        title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      )
                      : FxContentWidthLimiter(child: _buildList(chrome, primary, isDark)),
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
                    label: 'Enviar vídeo',
                    onPressed: _enviar,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(ShellPalette chrome, Color primary, bool isDark) {
    if (_items.isEmpty) {
      final filtered = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: () => _load(reset: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (filtered)
              FxEmptyState(
                icon: 'search',
                title: 'Nenhum vídeo encontrado',
                subtitle: 'Ajuste a busca para ver outros envios.',
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
                icon: 'spark',
                title: 'Nenhum vídeo enviado ainda',
                subtitle:
                    'Toque em Enviar vídeo para receber análise IA da sua execução.',
                action: FxEmptyAction(
                  label: 'Enviar vídeo',
                  onTap: _enviar,
                ),
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
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: _items.length + (showMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (showMore && i == _items.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : () => _load(reset: false),
            );
          }
          return _videoTile(_items[i], chrome, primary, isDark);
        },
      ),
    );
  }

  Widget _videoTile(
    FeedbackVideo f,
    ShellPalette chrome,
    Color primary,
    bool isDark,
  ) {
    final exNome =
        _exercicios
            .where((e) => e.id == f.exercicioId)
            .map((e) => e.nome)
            .firstOrNull ??
        'Exercício #${f.exercicioId}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: chrome.listCard(primary: primary),
      child: ExpansionTile(
        title: Text(
          exNome,
          style: TextStyle(color: chrome.ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          feedbackVideoSubtitle(
            criadoEm: f.criadoEm,
            aiScore: f.aiScore,
            statusAnalise: f.statusAnalise,
          ),
          style: TextStyle(color: chrome.mute),
        ),
        leading:
            f.aiScore != null
                ? CircleAvatar(
                  backgroundColor: _scoreColor(f.aiScore),
                  foregroundColor: Colors.white,
                  child: Text('${f.aiScore}'),
                )
                : CircleAvatar(
                  backgroundColor: BrandPalette.soft(primary, dark: isDark),
                  child: Icon(Icons.hourglass_empty, color: primary),
                ),
        children: [
          if (f.aiAnalise != null && f.aiAnalise!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                f.aiAnalise!,
                style: TextStyle(height: 1.4, color: chrome.ink),
              ),
            ),
          if (f.comentario.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Sua nota: ${f.comentario}',
                style: TextStyle(color: chrome.mute),
              ),
            ),
        ],
      ),
    );
  }
}
