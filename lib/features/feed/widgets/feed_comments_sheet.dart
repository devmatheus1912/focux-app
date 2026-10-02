import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../data/feed_repository.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../l10n/app_localizations.dart';

enum _AcaoComentario { apagar, denunciar, bloquear }

class FeedCommentsSheet extends StatefulWidget {
  final int postId;
  final FeedRepository repo;
  final ValueChanged<int> onComentou;
  final int? currentAlunoId;
  final String? currentAlunoFotoUrl;
  final bool canCompose;

  const FeedCommentsSheet({
    super.key,
    required this.postId,
    required this.repo,
    required this.onComentou,
    this.currentAlunoId,
    this.currentAlunoFotoUrl,
    this.canCompose = true,
  });

  @override
  State<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<FeedCommentsSheet> {
  final _ctrl = TextEditingController();
  List<FeedComentario> _comentarios = [];
  bool _loading = true;
  bool _sending = false;
  bool _loadingMore = false;
  bool _hasNext = false;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loadingMore || !_hasNext)) return;
    if (more) setState(() => _loadingMore = true);
    try {
      final pagina = await widget.repo.listarComentarios(
        widget.postId,
        cursor: more ? _nextCursor : null,
      );
      if (!mounted) return;
      setState(() {
        _comentarios = more ? [..._comentarios, ...pagina.content] : pagina.content;
        _hasNext = pagina.hasNext;
        _nextCursor = pagina.nextCursor;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _enviar() async {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final c = await widget.repo.comentar(widget.postId, texto);
      _ctrl.clear();
      if (!mounted) return;
      setState(() {
        _comentarios.insert(0, c);
        _sending = false;
      });
      widget.onComentou(_comentarios.length);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// Personal (sem compor) modera tudo; aluno apaga o próprio e denuncia/bloqueia o dos outros.
  List<_AcaoComentario> _acoesPara(FeedComentario c) {
    final moderador = !widget.canCompose;
    final meu = widget.currentAlunoId != null && widget.currentAlunoId == c.alunoId;
    if (moderador || meu) return const [_AcaoComentario.apagar];
    if (widget.currentAlunoId == null) return const [];
    return const [_AcaoComentario.denunciar, _AcaoComentario.bloquear];
  }

  Future<void> _executar(_AcaoComentario acao, FeedComentario c) async {
    final l10n = S.of(context);
    final (titulo, mensagem) = switch (acao) {
      _AcaoComentario.apagar => (l10n.feedComentarioApagar, l10n.feedComentarioApagarConfirma),
      _AcaoComentario.denunciar => (l10n.feedComentarioDenunciar, l10n.feedComentarioDenunciarConfirma),
      _AcaoComentario.bloquear => (l10n.feedComentarioBloquear(c.alunoNome), l10n.feedComentarioBloquearConfirma),
    };
    final ok = await showFxConfirmSheet(
      context,
      title: titulo,
      message: mensagem,
      confirmLabel: titulo,
      destructive: true,
      icon: Icons.flag_outlined,
    );
    if (!ok || !mounted) return;
    try {
      switch (acao) {
        case _AcaoComentario.apagar:
          await widget.repo.apagarComentario(c.id);
        case _AcaoComentario.denunciar:
          await widget.repo.denunciarComentario(c.id);
        case _AcaoComentario.bloquear:
          await widget.repo.bloquearAluno(c.alunoId);
      }
      if (!mounted) return;
      setState(() {
        if (acao == _AcaoComentario.bloquear) {
          _comentarios.removeWhere((x) => x.alunoId == c.alunoId);
        } else {
          _comentarios.removeWhere((x) => x.id == c.id);
        }
      });
      widget.onComentou(_comentarios.length);
      FeedbackHelper.showSuccess(
        context,
        switch (acao) {
          _AcaoComentario.apagar => l10n.feedComentarioApagado,
          _AcaoComentario.denunciar => l10n.feedComentarioDenunciado,
          _AcaoComentario.bloquear => l10n.feedComentarioBloqueado,
        },
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Widget _menu(FeedComentario c, Color mute) {
    final acoes = _acoesPara(c);
    if (acoes.isEmpty) return const SizedBox.shrink();
    final l10n = S.of(context);
    return PopupMenuButton<_AcaoComentario>(
      tooltip: l10n.feedComentarioOpcoes,
      icon: Icon(Icons.more_vert_rounded, size: 18, color: mute),
      padding: EdgeInsets.zero,
      onSelected: (a) => _executar(a, c),
      itemBuilder: (_) => [
        for (final a in acoes)
          PopupMenuItem(
            value: a,
            child: Text(switch (a) {
              _AcaoComentario.apagar => l10n.feedComentarioApagar,
              _AcaoComentario.denunciar => l10n.feedComentarioDenunciar,
              _AcaoComentario.bloquear => l10n.feedComentarioBloquear(c.alunoNome),
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight:
          MediaQuery.sizeOf(context).height *
          FxHomeSheetChrome.expandHeightFactor,
      child: Column(
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Comentários',
            leading: Icon(
              Icons.chat_bubble_outline_rounded,
              color: primary,
              size: 18,
            ),
          ),
          Divider(height: 1, color: line),
          Expanded(
            child:
                _loading
                    ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: FxLoading.sectionShimmer(context, height: 200),
                    )
                    : _comentarios.isEmpty
                    ? Center(
                      child: Text(
                        widget.canCompose
                            ? 'Seja o primeiro a comentar!'
                            : 'Nenhum comentário ainda',
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      itemCount: _comentarios.length + (_hasNext ? 1 : 0),
                      itemBuilder: (ctx, i) {
                        if (i >= _comentarios.length) {
                          return TextButton(
                            onPressed: _loadingMore
                                ? null
                                : () => _load(more: true),
                            child: Text(
                              _loadingMore ? 'Carregando…' : 'Carregar mais',
                            ),
                          );
                        }
                        final c = _comentarios[i];
                        final useCurrentAlunoFallback =
                            widget.currentAlunoId != null &&
                            widget.currentAlunoId == c.alunoId;
                        final fotoUrl =
                            (c.alunoFotoUrl?.trim().isNotEmpty == true
                                    ? c.alunoFotoUrl
                                    : useCurrentAlunoFallback
                                    ? widget.currentAlunoFotoUrl
                                    : null)
                                ?.trim();
                        final hasFoto = fotoUrl != null && fotoUrl.isNotEmpty;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: primary.withValues(
                                  alpha: 0.12,
                                ),
                                foregroundColor: primary,
                                backgroundImage:
                                    hasFoto
                                        ? fxCachedNetworkImageProvider(
                                          fotoUrl,
                                          maxWidth: 96,
                                        )
                                        : null,
                                child:
                                    hasFoto
                                        ? null
                                        : Text(fxInitials(c.alunoNome)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? EagleTokens.darkBg
                                            : EagleTokens.paper,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: line),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.alunoNome,
                                          style: TextStyle(
                                            color: ink,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.texto,
                                          style: TextStyle(color: ink),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _menu(c, mute),
                            ],
                          ),
                        );
                      },
                    ),
          ),
          if (widget.canCompose) Divider(height: 1, color: line),
          if (widget.canCompose)
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              10,
              16,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                    decoration: InputDecoration(
                      hintText: 'Escreva um comentário...',
                      hintStyle: TextStyle(color: mute),
                      filled: true,
                      fillColor:
                          isDark ? EagleTokens.darkBg : EagleTokens.paper,
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: line),
                      ),
                      enabledBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: primary, width: 1.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar',
                  onPressed: _sending ? null : _enviar,
                  icon:
                      _sending
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: FxLoading(
                              strokeWidth: 2,
                              color: EagleTokens.darkInk,
                            ),
                          )
                          : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
