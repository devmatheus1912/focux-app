import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';

class FeedAlunoScreen extends ConsumerStatefulWidget {
  const FeedAlunoScreen({super.key});

  @override
  ConsumerState<FeedAlunoScreen> createState() => _FeedAlunoScreenState();
}

class _FeedAlunoScreenState extends ConsumerState<FeedAlunoScreen> {
  List<FeedPost> _posts = [];
  bool _loading = true;
  final Map<int, int> _curtidasLocais = {}; // postId -> total
  final Map<int, int> _comentariosLocais = {}; // postId -> total

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await FeedRepository(ref.read(apiClientProvider)).listarAluno();
      setState(() {
        _posts = posts;
        for (var p in posts) {
          _curtidasLocais[p.id] = p.totalCurtidas;
          _comentariosLocais[p.id] = p.totalComentarios;
        }
        _loading = false;
      });
    } catch (e) { debugPrint('[Focux] Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _curtir(int postId) async {
    try {
      final novoTotal = await FeedRepository(ref.read(apiClientProvider)).toggleCurtida(postId);
      setState(() {
        _curtidasLocais[postId] = novoTotal;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao curtir: $e')));
      }
    }
  }

  void _abrirComentarios(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => _ComentariosBottomSheet(postId: postId, repo: FeedRepository(ref.read(apiClientProvider)), onComentou: (novoTotal) {
        setState(() {
          _comentariosLocais[postId] = novoTotal;
        });
      }),
    );
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo) {
      case 'IMAGEM': return Icons.image;
      case 'VIDEO': return Icons.play_circle_fill;
      case 'ENQUETE': return Icons.poll;
      case 'DICA': return Icons.lightbulb;
      default: return Icons.article;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Meu Feed')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Nenhuma publicação disponível.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) {
                      final p = _posts[i];
                      final mUrl = p.midiaUrl ?? p.imagemUrl;
                      final curtidas = _curtidasLocais[p.id] ?? p.totalCurtidas;
                      final comentarios = _comentariosLocais[p.id] ?? p.totalComentarios;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: p.fixado ? const BorderSide(color: EagleTokens.brand, width: 2) : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (p.fixado) ...[
                                    const Icon(Icons.push_pin, color: EagleTokens.brand, size: 18),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(_getIconForTipo(p.tipoPost), size: 20, color: const Color(0xFF374151)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.titulo,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              if (p.tipoPost != null && p.tipoPost != 'TEXTO') ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: EagleTokens.brand.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.tipoPost!,
                                    style: const TextStyle(fontSize: 10, color: EagleTokens.brand, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(p.conteudo, style: const TextStyle(fontSize: 14)),
                              if (mUrl != null && mUrl.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    mUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _curtir(p.id),
                                    icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                                    label: Text('$curtidas Curtir', style: const TextStyle(color: EagleTokens.inkMute)),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _abrirComentarios(p.id),
                                    icon: const Icon(Icons.comment_outlined, size: 18),
                                    label: Text('$comentarios Comentar', style: const TextStyle(color: EagleTokens.inkMute)),
                                  ),
                                  const Spacer(),
                                  Text(
                                    p.criadoEm.length >= 10 ? p.criadoEm.substring(0, 10) : p.criadoEm,
                                    style: TextStyle(fontSize: 12, color: const Color(0xFF4B5563)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ComentariosBottomSheet extends StatefulWidget {
  final int postId;
  final FeedRepository repo;
  final Function(int) onComentou;

  const _ComentariosBottomSheet({required this.postId, required this.repo, required this.onComentou});

  @override
  State<_ComentariosBottomSheet> createState() => _ComentariosBottomSheetState();
}

class _ComentariosBottomSheetState extends State<_ComentariosBottomSheet> {
  List<FeedComentario> _comentarios = [];
  bool _loading = true;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lista = await widget.repo.listarComentarios(widget.postId);
      setState(() {
        _comentarios = lista;
        _loading = false;
      });
    } catch (e) { debugPrint('[Focux] Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _enviar() async {
    if (_ctrl.text.trim().isEmpty) return;
    try {
      final c = await widget.repo.comentar(widget.postId, _ctrl.text.trim());
      _ctrl.clear();
      setState(() {
        _comentarios.insert(0, c);
      });
      widget.onComentou(_comentarios.length);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Comentários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comentarios.isEmpty
                    ? const Center(child: Text('Seja o primeiro a comentar!'))
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
                                CircleAvatar(child: Text(c.alunoNome.isNotEmpty ? c.alunoNome[0] : 'A')),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5E7EB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.alunoNome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(c.texto),
                                      ],
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Escreva um comentário...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _enviar,
                  icon: const Icon(Icons.send, color: EagleTokens.brand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
