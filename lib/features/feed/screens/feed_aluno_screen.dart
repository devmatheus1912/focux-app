import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../data/feed_repository.dart';
import '../widgets/feed_comments_sheet.dart';

class FeedAlunoScreen extends ConsumerStatefulWidget {
  const FeedAlunoScreen({super.key});

  @override
  ConsumerState<FeedAlunoScreen> createState() => _FeedAlunoScreenState();
}

class _FeedAlunoScreenState extends ConsumerState<FeedAlunoScreen> {
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
          await FeedRepository(ref.read(apiClientProvider)).listarAluno();
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
    final aluno = ref.read(alunoMeProvider).valueOrNull;
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
            currentAlunoId: aluno?.id,
            currentAlunoFotoUrl: aluno?.fotoUrl,
            onComentou:
                (novoTotal) =>
                    setState(() => _comentariosLocais[postId] = novoTotal),
          ),
    );
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
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      body: SafeArea(
        child:
            _loading
                ? Center(child: CircularProgressIndicator(color: primary))
                : _posts.isEmpty
                ? Center(
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
                        child: Icon(
                          Icons.article_outlined,
                          color: primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Nenhuma publicação disponível.',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
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
                          padding: const EdgeInsets.all(16),
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
                                p.tipoPost == 'VIDEO'
                                    ? _VideoAttachmentTile(primary: primary)
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        mUrl,
                                        fit: BoxFit.cover,
                                        height: 130,
                                        width: double.infinity,
                                        errorBuilder:
                                            (_, __, ___) => _ImagePlaceholder(
                                              primary: primary,
                                            ),
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

class _VideoAttachmentTile extends StatelessWidget {
  final Color primary;

  const _VideoAttachmentTile({required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [BrandPalette.deep(primary), primary.withValues(alpha: 0.74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }
}
