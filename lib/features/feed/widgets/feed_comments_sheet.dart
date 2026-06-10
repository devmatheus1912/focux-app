import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../data/feed_repository.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

class FeedCommentsSheet extends StatefulWidget {
  final int postId;
  final FeedRepository repo;
  final ValueChanged<int> onComentou;
  final int? currentAlunoId;
  final String? currentAlunoFotoUrl;

  const FeedCommentsSheet({
    super.key,
    required this.postId,
    required this.repo,
    required this.onComentou,
    this.currentAlunoId,
    this.currentAlunoFotoUrl,
  });

  @override
  State<FeedCommentsSheet> createState() => _FeedCommentsSheetState();
}

class _FeedCommentsSheetState extends State<FeedCommentsSheet> {
  final _ctrl = TextEditingController();
  List<FeedComentario> _comentarios = [];
  bool _loading = true;
  bool _sending = false;

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

  Future<void> _load() async {
    try {
      final lista = await widget.repo.listarComentarios(widget.postId);
      if (!mounted) return;
      setState(() {
        _comentarios = lista;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
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
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: DecoratedBox(
          decoration: fxListCardDecoration(
            context,
            accent: primary,
            radius: 28,
          ).copyWith(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comentários',
                        style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: line),
              Expanded(
                child:
                    _loading
                        ? Center(child: FxLoading(color: primary))
                        : _comentarios.isEmpty
                        ? const Center(
                          child: Text('Seja o primeiro a comentar!'),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          itemCount: _comentarios.length,
                          itemBuilder: (ctx, i) {
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
                            final hasFoto =
                                fotoUrl != null && fotoUrl.isNotEmpty;
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
                                        hasFoto ? NetworkImage(fotoUrl) : null,
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
                                ],
                              ),
                            );
                          },
                        ),
              ),
              Divider(height: 1, color: line),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  MediaQuery.of(context).viewInsets.bottom + 12,
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
        ),
      ),
    );
  }
}
