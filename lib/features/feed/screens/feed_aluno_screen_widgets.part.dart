part of 'feed_aluno_screen.dart';

class _AlunoFeedPostCard extends StatelessWidget {
  const _AlunoFeedPostCard({
    required this.post,
    required this.primary,
    required this.curtidas,
    required this.comentarios,
    required this.onCurtir,
    required this.onComentar,
  });

  final FeedPost post;
  final Color primary;
  final int curtidas;
  final int comentarios;
  final VoidCallback onCurtir;
  final VoidCallback onComentar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mUrl = post.midiaUrl ?? post.imagemUrl;
    final badgeColor = _feedBadgeColor(post.tipoPost, primary);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: chrome.listCard(primary: post.fixado ? primary : null),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PostAuthorHeader(post: post, primary: primary),
            const SizedBox(height: 12),
            Row(
              children: [
                if (post.fixado) ...[
                  Icon(Icons.push_pin, color: primary, size: 18),
                  const SizedBox(width: 8),
                ],
                Icon(_iconForTipo(post.tipoPost), size: 20, color: badgeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    post.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: chrome.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _TypeBadge(tipo: post.tipoPost, color: badgeColor),
            const SizedBox(height: 8),
            Text(
              post.conteudo,
              style: TextStyle(fontSize: 14, color: chrome.ink),
            ),
            if (mUrl != null && mUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              post.tipoPost == 'VIDEO'
                  ? _VideoAttachmentTile(primary: primary)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        mUrl,
                        fit: BoxFit.cover,
                        height: 130,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) =>
                            _ImagePlaceholder(primary: primary),
                      ),
                    ),
            ] else if (post.tipoPost == 'IMAGEM') ...[
              const SizedBox(height: 12),
              _ImagePlaceholder(primary: primary),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: onCurtir,
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  label: Text('$curtidas Curtir'),
                ),
                TextButton.icon(
                  onPressed: onComentar,
                  icon: const Icon(Icons.comment_outlined, size: 18),
                  label: Text('$comentarios Comentar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForTipo(String? tipo) {
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

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.tipo, required this.color});

  final String? tipo;
  final Color color;

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
    final name = post.autorNome?.trim().isNotEmpty == true
        ? post.autorNome!.trim()
        : 'Personal';
    final avatarUrl = post.autorAvatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: primary.withValues(alpha: 0.14),
          backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
          child: hasAvatar
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
                style: FocuxHubTypography.bodyMuted(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                fxTimeAgo(DateTime.parse(post.criadoEm)),
                style: FocuxHubTypography.bodyMuted(color: mute),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.primary});

  final Color primary;

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
  const _VideoAttachmentTile({required this.primary});

  final Color primary;

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
