import 'dart:async';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/safe_external_launch.dart';
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
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/providers/alunos_provider.dart' show alunoProvider;
import '../data/feedback_video_repository.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_video_rede.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../widgets/feedback_gravador_audio.dart';
import '../utils/feedback_video_display.dart';
import '../../../core/theme/fx_icons.dart';

enum _FeedbackVideoAcao { abrir, responder, deletar }

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

  String get _parentRoute =>
      widget.alunoId == null
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
      await FeedbackVideoRepository(
        ref.read(apiClientProvider),
      ).deletar(item.id);
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
      title: feedbackVideoTitulo(
        exercicioNome: item.exercicioNome,
        comentario: item.comentario,
      ),
      subtitle: item.comentario.trim().isEmpty ? null : item.comentario.trim(),
      items: [
        const FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.abrir,
          label: 'Assistir vídeo',
          icon: FxIcons.playCirculo,
        ),
        FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.responder,
          label: feedbackVideoResponderLabel(respondido: item.respondido),
          icon: FxIcons.avaliacao,
        ),
        const FxInsetPickerSheetItem(
          value: _FeedbackVideoAcao.deletar,
          label: 'Remover',
          icon: FxIcons.excluir,
        ),
      ],
    );
    if (picked == null || !mounted) return;
    switch (picked) {
      case _FeedbackVideoAcao.abrir:
        await _abrirVideo(item.videoUrl);
      case _FeedbackVideoAcao.responder:
        await _responder(item);
      case _FeedbackVideoAcao.deletar:
        await _deletar(item);
    }
  }

  /// Vídeo tocando na folha, recado do aluno e a correção (texto, áudio ou
  /// os dois). Envia com a folha aberta: se falhar, o texto fica.
  Future<void> _responder(FeedbackVideo item) async {
    HapticFeedback.selectionClick();
    final ctrl = TextEditingController(text: item.respostaPersonal ?? '');
    final gravacao = ValueNotifier<GravacaoDeAudio?>(null);
    final comentario = item.comentario.trim();
    final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
    bool temAlgo() =>
        ctrl.text.trim().isNotEmpty || gravacao.value != null || item.temAudio;
    try {
      final ok = await showFxFormSheet(
        context,
        title: feedbackVideoResponderLabel(respondido: item.respondido),
        subtitle: feedbackVideoTitulo(
          exercicioNome: item.exercicioNome,
          comentario: item.comentario,
        ),
        icon: FxIcons.avaliacao,
        confirmLabel: 'Enviar ao aluno',
        ouvir: Listenable.merge([ctrl, gravacao]),
        podeConfirmar: temAlgo,
        aoConfirmar: () async {
          try {
            final audio = gravacao.value;
            final audioUrl =
                audio == null
                    ? null
                    : await repo.subirAudio(
                      path: audio.path,
                      filename: audio.path.split('/').last,
                    );
            final atualizado = await repo.responder(
              item.id,
              ctrl.text.trim(),
              audioUrl: audioUrl ?? item.respostaAudioUrl,
              audioSegundos: audio?.segundos ?? item.respostaAudioSegundos,
            );
            if (mounted) {
              setState(() {
                final i = _feedbacks.indexWhere((f) => f.id == item.id);
                if (i >= 0) _feedbacks[i] = atualizado;
              });
            }
            return null;
          } catch (e) {
            return friendlyError(e, fallback: 'Não deu para enviar agora.');
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxVideoRede(
              url: item.videoUrl,
              onAbrirFora: () => _abrirVideo(item.videoUrl),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              feedbackVideoEnviadoEm(item.criadoEm),
              style: FocuxHubTypography.bodyMuted(
                color: ShellChrome.of(context).mute,
              ),
            ),
            if (comentario.isNotEmpty) ...[
              const SizedBox(height: TokensStrip.s3),
              _RecadoDoAluno(recado: comentario),
            ],
            const SizedBox(height: TokensStrip.s2),
            AlunoInsetFormField(
              controller: ctrl,
              label: 'Sua correção',
              hint: 'Ex.: desça mais devagar e mantenha o joelho alinhado.',
              maxLines: 6,
              rotuloVisivel: true,
              mostrarOpcional: false,
              showDivider: false,
            ),
            const SizedBox(height: TokensStrip.s2),
            FeedbackGravadorAudio(gravacao: gravacao),
            const SizedBox(height: TokensStrip.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: FxTonalButton(
                label: 'Remover este vídeo',
                icon: FxIcons.excluir,
                danger: true,
                compact: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  _deletar(item);
                },
              ),
            ),
          ],
        ),
      );
      if (ok && mounted) {
        FeedbackHelper.showSuccess(context, 'Correção enviada.');
      }
    } finally {
      ctrl.dispose();
      gravacao.dispose();
    }
  }

  /// Abre a conversa com o texto pronto; nada é enviado sozinho.
  void _pedirVideo() {
    final id = widget.alunoId;
    if (id == null) return;
    final nome = _nomeAluno ?? 'Aluno';
    context.push(
      '/alunos/$id/chat',
      extra: {
        'nome': nome,
        'draft': feedbackVideoPedidoRascunho(satelliteFirstName(nome)),
      },
    );
  }

  /// Nome do aluno: o que veio na rota ou, sem ele (aviso, Tarefas), o do cadastro.
  String? get _nomeAluno {
    final daRota = widget.alunoNome?.trim();
    if (daRota != null && daRota.isNotEmpty) return daRota;
    final id = widget.alunoId;
    if (id == null) return null;
    return ref.watch(alunoProvider(id)).value?.nome;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final visible = feedbackVideosOrdenados(_feedbacks);
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
          comFundo: true,
          appBar: FxShellAppBar(
            title: feedbackVideoNome,
            subtitle: FxHubFreshness.joinCount(
              feedbackVideoPersonalSubtitulo(
                primeiroNome:
                    _nomeAluno == null ? null : satelliteFirstName(_nomeAluno),
                paraResponder:
                    _loading ? 0 : visible.where((f) => !f.respondido).length,
              ),
              _loading ? null : FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            onBack: () {
              FxKeyboardDismissScope.dismiss();
              safePopOrGo(context, _parentRoute);
            },
            actions: [
              FxHelpIconButton(
                tooltip: 'Ajuda — feedback em vídeo',
                onTap:
                    () => showFxHelpSheet(
                      context,
                      title: feedbackVideoNome,
                      subtitle: feedbackVideoHelpTip,
                    ),
              ),
            ],
          ),
          body: Column(
            children: [
              if (count >= feedbackVideoBuscaMinimo || _query.trim().isNotEmpty)
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
                        hintText: feedbackVideoBuscaDica,
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
                                  onPressed: () {
                                    _searchDebounce?.cancel();
                                    _searchCtrl.clear();
                                    setState(() => _query = '');
                                    _load(reset: true);
                                  },
                                  icon: Icon(
                                    FxIcons.fechar,
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
                icon: FxIcons.buscar,
                title: 'Nenhum feedback encontrado',
                subtitle: 'Ajuste a busca para ver outros comentários.',
                action: FxEmptyAction(
                  label: 'Limpar busca',
                  secondary: true,
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
                icon: FxIcons.video,
                title:
                    _nomeAluno != null
                        ? 'Nenhum vídeo do ${satelliteFirstName(_nomeAluno)} ainda'
                        : 'Nenhum vídeo ainda',
                subtitle:
                    _nomeAluno != null
                        ? 'Quando ${satelliteFirstName(_nomeAluno)} mandar um vídeo de execução, ele aparece aqui para você corrigir.'
                        : 'Quando um aluno mandar um vídeo de execução, ele aparece aqui para você corrigir.',
                // Sem aluno (lista geral) não há para quem pedir.
                action:
                    widget.alunoId == null
                        ? null
                        : FxEmptyAction(
                          label:
                              'Pedir vídeo ao ${satelliteFirstName(_nomeAluno)}',
                          onTap: _pedirVideo,
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
          final dor = feedbackVideoComDor(item);
          final exercicio = feedbackVideoTitulo(
            exercicioNome: item.exercicioNome,
            comentario: item.comentario,
          );
          // Lista geral: o aluno é o título; o exercício vai junto do resto.
          final geral = widget.alunoId == null && item.alunoNome != null;
          final linha = feedbackVideoSubtituloDaLinha(item);
          final alerta =
              ShellChrome.of(context).isDark
                  ? EagleTokens.warnDark
                  : EagleTokens.warn;
          return FxSatelliteListTile(
            titleCase: false,
            title: geral ? satelliteFirstName(item.alunoNome!) : exercicio,
            leading:
                geral
                    ? AlunoAvatar(
                      name: item.alunoNome!,
                      variant: AlunoAvatarVariant.strip,
                    )
                    : null,
            subtitle: Semantics(
              label: dor ? '$linha, fala de dor' : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dor) ...[
                    Icon(FxIcons.alertaPequeno, size: 14, color: alerta),
                    const SizedBox(width: TokensStrip.s1),
                  ],
                  Flexible(
                    child: Text(
                      geral ? '$exercicio · $linha' : linha,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          dor
                              ? FocuxHubTypography.bodyMuted(
                                color: alerta,
                                fontWeight: FontWeight.w600,
                              )
                              : null,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Text(
              feedbackVideoStatusLabel(respondido: item.respondido),
              style: FocuxHubTypography.bodyMuted(
                color: item.respondido ? fxScreenMute(context) : primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            accent: item.respondido ? null : primary,
            onTap: () => _responder(item),
            onLongPress: () => _abrirAcoes(item),
          );
        },
      ),
    );
  }
}

/// Recado que o aluno mandou com o vídeo, em destaque; fala de dor vai em alerta.
class _RecadoDoAluno extends StatelessWidget {
  const _RecadoDoAluno({required this.recado});

  final String recado;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dor = feedbackRecadoFalaDeDor(recado);
    final corRotulo =
        dor
            ? (chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn)
            : chrome.mute;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (dor) ...[
                Icon(FxIcons.alerta, size: 16, color: corRotulo),
                const SizedBox(width: TokensStrip.s1),
              ],
              Flexible(
                child: Text(
                  dor ? 'Recado do aluno · fala de dor' : 'Recado do aluno',
                  style: FocuxHubTypography.chip(corRotulo),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(recado, style: FocuxHubTypography.body(color: chrome.ink)),
        ],
      ),
    );
  }
}
