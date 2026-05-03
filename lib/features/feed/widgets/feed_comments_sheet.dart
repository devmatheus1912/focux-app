import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/feed_repository.dart';

class FeedCommentsSheet extends StatefulWidget {
  final int postId;
  final FeedRepository repo;
  final ValueChanged<int> onComentou;

  const FeedCommentsSheet({
    super.key,
    required this.postId,
    required this.repo,
    required this.onComentou,
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
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comentários',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
              const Divider(height: 1),
              Expanded(
                child:
                    _loading
                        ? Center(
                          child: CircularProgressIndicator(color: primary),
                        )
                        : _comentarios.isEmpty
                        ? const Center(
                          child: Text('Seja o primeiro a comentar!'),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _comentarios.length,
                          itemBuilder: (ctx, i) {
                            final c = _comentarios[i];
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
                                    child: Text(
                                      c.alunoNome.isNotEmpty
                                          ? c.alunoNome[0].toUpperCase()
                                          : 'A',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: EagleTokens.line.withValues(
                                          alpha: 0.55,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.alunoNome,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(c.texto),
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _enviar(),
                        decoration: const InputDecoration(
                          hintText: 'Escreva um comentário...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
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
                                child: CircularProgressIndicator(
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
