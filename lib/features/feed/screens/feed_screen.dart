import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';
import '../widgets/feed_comments_sheet.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final Map<int, int> _curtidasLocais = {};
  final Map<int, int> _comentariosLocais = {};
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
      final posts =
          await FeedRepository(ref.read(apiClientProvider)).listarPersonal();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        for (final p in posts) {
          _curtidasLocais[p.id] = p.totalCurtidas;
          _comentariosLocais[p.id] = p.totalComentarios;
        }
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).deletar(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _toggleFixar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).toggleFixar(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _curtir(int postId) async {
    try {
      final novoTotal = await FeedRepository(
        ref.read(apiClientProvider),
      ).toggleCurtida(postId);
      if (mounted) {
        setState(() => _curtidasLocais[postId] = novoTotal);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  void _abrirComentarios(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => FeedCommentsSheet(
            postId: postId,
            repo: FeedRepository(ref.read(apiClientProvider)),
            onComentou:
                (novoTotal) =>
                    setState(() => _comentariosLocais[postId] = novoTotal),
          ),
    );
  }

  void _abrirFormulario() {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final conteudoCtrl = TextEditingController();
    final midiaUrlCtrl = TextEditingController();
    String tipoSelecionado = 'TEXTO';
    bool salvando = false;

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
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
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Fechar',
                                  icon: const Icon(Icons.close),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: tipoSelecionado,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de post',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'TEXTO',
                                  child: Text('Texto'),
                                ),
                                DropdownMenuItem(
                                  value: 'IMAGEM',
                                  child: Text('Imagem'),
                                ),
                                DropdownMenuItem(
                                  value: 'VIDEO',
                                  child: Text('Vídeo'),
                                ),
                                DropdownMenuItem(
                                  value: 'ENQUETE',
                                  child: Text('Enquete'),
                                ),
                                DropdownMenuItem(
                                  value: 'DICA',
                                  child: Text('Dica rápida'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setModalState(() => tipoSelecionado = v);
                                }
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
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Informe o título'
                                          : null,
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
                              validator:
                                  (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Informe o conteúdo'
                                          : null,
                            ),
                            if (tipoSelecionado == 'IMAGEM' ||
                                tipoSelecionado == 'VIDEO') ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: midiaUrlCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'URL da mídia',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed:
                                  salvando
                                      ? null
                                      : () async {
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        }
                                        setModalState(() => salvando = true);
                                        try {
                                          await FeedRepository(
                                            ref.read(apiClientProvider),
                                          ).criar(
                                            tituloCtrl.text.trim(),
                                            conteudoCtrl.text.trim(),
                                            tipoPost: tipoSelecionado,
                                            midiaUrl:
                                                midiaUrlCtrl.text.trim().isEmpty
                                                    ? null
                                                    : midiaUrlCtrl.text.trim(),
                                          );
                                          if (ctx.mounted) {
                                            Navigator.of(ctx).pop(true);
                                          }
                                        } catch (e) {
                                          if (ctx.mounted) {
                                            setModalState(
                                              () => salvando = false,
                                            );
                                            ScaffoldMessenger.of(
                                              ctx,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(friendlyError(e)),
                                              ),
                                            );
                                          }
                                        }
                                      },
                              icon:
                                  salvando
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: EagleTokens.darkInk,
                                        ),
                                      )
                                      : const Icon(Icons.send),
                              label: Text(
                                salvando ? 'Publicando...' : 'Publicar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    ).then((created) async {
      tituloCtrl.dispose();
      conteudoCtrl.dispose();
      midiaUrlCtrl.dispose();
      if (created != true || !mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Publicação criada com sucesso!')),
      );
    });
  }

  IconData _getIconForTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'IMAGEM':
        return Icons.image;
      case 'VIDEO':
        return Icons.play_circle_fill;
      case 'ENQUETE':
        return Icons.poll;
      case 'DICA':
        return Icons.lightbulb;
      default:
        return Icons.article;
    }
  }

  Color _feedBadgeColor(String? tipo, Color primary) {
    switch (tipo?.toUpperCase()) {
      case 'DICA':
        return EagleTokens.warn;
      case 'IMAGEM':
        return EagleTokens.good;
      case 'ENQUETE':
        return EagleTokens.purple;
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primary, primaryDeep]),
          borderRadius: BorderRadius.circular(44),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _abrirFormulario,
          tooltip: 'Nova Publicação',
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: EagleTokens.darkInk),
        ),
      ),
      body: SafeArea(
        child:
            _loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : _posts.isEmpty
                ? _EmptyFeed(primary: primary)
                : RefreshIndicator(
                  color: primary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                    itemCount: _posts.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  'Feed',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? EagleTokens.darkInk
                                            : EagleTokens.ink,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _abrirFormulario,
                                borderRadius: BorderRadius.circular(44),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primary, primaryDeep],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primary.withValues(alpha: 0.38),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final p = _posts[i - 1];
                      final mUrl = p.midiaUrl ?? p.imagemUrl;
                      final badgeColor = _feedBadgeColor(p.tipoPost, primary);
                      final curtidas = _curtidasLocais[p.id] ?? p.totalCurtidas;
                      final comentarios =
                          _comentariosLocais[p.id] ?? p.totalComentarios;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color:
                              isDark ? EagleTokens.darkCard : EagleTokens.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                p.fixado
                                    ? primary
                                    : (isDark
                                        ? EagleTokens.darkLine
                                        : EagleTokens.line),
                            width: p.fixado ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PostAuthorHeader(post: p, primary: primary),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (p.fixado) ...[
                                    Icon(
                                      Icons.push_pin,
                                      color: primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Icon(
                                    _getIconForTipo(p.tipoPost),
                                    size: 20,
                                    color: badgeColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      p.titulo,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Ações',
                                    onSelected: (val) {
                                      if (val == 'fixar') _toggleFixar(p.id);
                                      if (val == 'excluir') {
                                        _confirmarExclusao(p.id);
                                      }
                                    },
                                    itemBuilder:
                                        (ctx) => [
                                          PopupMenuItem(
                                            value: 'fixar',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  p.fixado
                                                      ? Icons.push_pin_outlined
                                                      : Icons.push_pin,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  p.fixado
                                                      ? 'Desafixar'
                                                      : 'Fixar no topo',
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'excluir',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete_outline,
                                                  color: EagleTokens.bad,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Excluir',
                                                  style: TextStyle(
                                                    color: EagleTokens.bad,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _TypeBadge(tipo: p.tipoPost, color: badgeColor),
                              const SizedBox(height: 8),
                              Text(
                                p.conteudo,
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (mUrl != null && mUrl.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    mUrl,
                                    fit: BoxFit.cover,
                                    height: 130,
                                    width: double.infinity,
                                    errorBuilder:
                                        (_, __, ___) =>
                                            _ImagePlaceholder(primary: primary),
                                  ),
                                ),
                              ] else if (p.tipoPost == 'IMAGEM') ...[
                                const SizedBox(height: 12),
                                _ImagePlaceholder(primary: primary),
                              ],
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _curtir(p.id),
                                    icon: const Icon(
                                      Icons.thumb_up_alt_outlined,
                                      size: 18,
                                    ),
                                    label: Text('$curtidas Curtir'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _abrirComentarios(p.id),
                                    icon: const Icon(
                                      Icons.comment_outlined,
                                      size: 18,
                                    ),
                                    label: Text('$comentarios Comentar'),
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
      ),
    );
  }

  void _confirmarExclusao(int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir publicação?'),
            content: const Text('Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deletar(id);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: EagleTokens.bad),
                ),
              ),
            ],
          ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  final Color primary;

  const _EmptyFeed({required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.article_outlined, color: primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma publicação',
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie a primeira publicação!',
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String? tipo;
  final Color color;

  const _TypeBadge({required this.tipo, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = (tipo == null || tipo!.isEmpty) ? 'TEXTO' : tipo!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PostAuthorHeader extends StatelessWidget {
  const _PostAuthorHeader({required this.post, required this.primary});

  final FeedPost post;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name =
        post.autorNome?.trim().isNotEmpty == true
            ? post.autorNome!.trim()
            : 'Personal';
    final avatarUrl = post.autorAvatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: primary.withValues(alpha: 0.14),
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
          child:
              hasAvatar
                  ? null
                  : Text(
                    fxInitials(name),
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                fxTimeAgo(DateTime.parse(post.criadoEm)),
                style: TextStyle(fontSize: 12, color: mute),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color primary;

  const _ImagePlaceholder({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.18),
            BrandPalette.deep(primary).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.image_outlined, color: primary, size: 28),
    );
  }
}
