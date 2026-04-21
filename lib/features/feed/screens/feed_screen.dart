import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  List<FeedPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await FeedRepository(ref.read(apiClientProvider)).listarPersonal();
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deletar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).deletar(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _toggleFixar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).toggleFixar(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao fixar: $e')));
      }
    }
  }

  void _abrirFormulario() {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();
    final midiaUrlCtrl = TextEditingController();
    String tipoSelecionado = 'TEXTO';
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nova Publicação',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: tipoSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Post',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TEXTO', child: Text('Texto')),
                    DropdownMenuItem(value: 'IMAGEM', child: Text('Imagem')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('Vídeo')),
                    DropdownMenuItem(value: 'ENQUETE', child: Text('Enquete')),
                    DropdownMenuItem(value: 'DICA', child: Text('Dica Rápida')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModalState(() => tipoSelecionado = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: conteudoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conteúdo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_fields),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o conteúdo' : null,
                ),
                if (tipoSelecionado == 'IMAGEM' || tipoSelecionado == 'VIDEO') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: midiaUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da Mídia (Cloudinary)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => salvando = true);
                          try {
                            await FeedRepository(ref.read(apiClientProvider)).criar(
                              tituloCtrl.text.trim(),
                              conteudoCtrl.text.trim(),
                              tipoPost: tipoSelecionado,
                              midiaUrl: midiaUrlCtrl.text.trim().isEmpty ? null : midiaUrlCtrl.text.trim(),
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop();
                            _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Publicação criada com sucesso!')),
                              );
                            }
                          } catch (e) {
                            setModalState(() => salvando = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Erro: $e')),
                              );
                            }
                          }
                        },
                  icon: salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send),
                  label: Text(salvando ? 'Publicando...' : 'Publicar'),
                ),
              ],
            ),
          ),
        ),
      ),
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
      appBar: AppBar(title: const Text('Feed de Conteúdo')),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirFormulario,
        tooltip: 'Nova Publicação',
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Nenhuma publicação ainda. Crie a primeira!'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) {
                      final p = _posts[i];
                      final mUrl = p.midiaUrl ?? p.imagemUrl;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: p.fixado ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (p.fixado) ...[
                                    const Icon(Icons.push_pin, color: Colors.blue, size: 18),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(_getIconForTipo(p.tipoPost), size: 20, color: Colors.grey[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.titulo,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'fixar') _toggleFixar(p.id);
                                      if (val == 'excluir') {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Excluir publicação?'),
                                            content: const Text('Esta ação não pode ser desfeita.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                                              TextButton(
                                                onPressed: () { Navigator.of(ctx).pop(); _deletar(p.id); },
                                                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'fixar',
                                        child: Row(children: [
                                          Icon(p.fixado ? Icons.push_pin_outlined : Icons.push_pin, size: 20),
                                          const SizedBox(width: 8),
                                          Text(p.fixado ? 'Desafixar' : 'Fixar no topo'),
                                        ]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'excluir',
                                        child: Row(children: [
                                          Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          SizedBox(width: 8),
                                          Text('Excluir', style: TextStyle(color: Colors.red)),
                                        ]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (p.tipoPost != null && p.tipoPost != 'TEXTO') ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    p.tipoPost!,
                                    style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
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
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${p.totalCurtidas}', style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(width: 16),
                                  Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('${p.totalComentarios}', style: TextStyle(color: Colors.grey[600])),
                                  const Spacer(),
                                  Text(
                                    p.criadoEm.length >= 10 ? p.criadoEm.substring(0, 10) : p.criadoEm,
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
