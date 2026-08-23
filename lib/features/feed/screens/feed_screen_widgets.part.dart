part of 'feed_screen.dart';

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
    final name =
        post.autorNome?.trim().isNotEmpty == true
            ? post.autorNome!.trim()
            : 'Personal';
    final avatarUrl = post.autorAvatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final mute = ShellChrome.of(context).mute;

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

class _FeedListHeader extends StatelessWidget {
  const _FeedListHeader({
    required this.freshnessLabel,
    required this.chrome,
    required this.primary,
    required this.primaryDeep,
    required this.onNovaPublicacao,
  });

  final String? freshnessLabel;
  final ShellPalette chrome;
  final Color primary;
  final Color primaryDeep;
  final VoidCallback onNovaPublicacao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feed',
                  style: TextStyle(
                    color: chrome.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (freshnessLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    freshnessLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: chrome.mute,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          InkWell(
            onTap: onNovaPublicacao,
            borderRadius: BorderRadius.circular(44),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primary, primaryDeep]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    required this.index,
    required this.primary,
    required this.curtidas,
    required this.comentarios,
    required this.onCurtir,
    required this.onComentar,
    required this.onFixar,
    required this.onExcluir,
  });

  final FeedPost post;
  final int index;
  final Color primary;
  final int curtidas;
  final int comentarios;
  final VoidCallback onCurtir;
  final VoidCallback onComentar;
  final VoidCallback onFixar;
  final VoidCallback onExcluir;

  @override
  Widget build(BuildContext context) {
    final mUrl = post.midiaUrl ?? post.imagemUrl;
    final badgeColor = _feedBadgeColor(post.tipoPost, primary);

    return FxStaggerItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: fxListCardDecoration(
          context,
          accent: post.fixado ? primary : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 14, 16, 12),
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
                  Icon(
                    _getIconForTipo(post.tipoPost),
                    size: 20,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Ações',
                    onSelected: (val) {
                      if (val == 'fixar') {
                        onFixar();
                      }
                      if (val == 'excluir') {
                        onExcluir();
                      }
                    },
                    itemBuilder:
                        (ctx) => [
                          PopupMenuItem(
                            value: 'fixar',
                            child: Row(
                              children: [
                                Icon(
                                  post.fixado
                                      ? Icons.push_pin_outlined
                                      : Icons.push_pin,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(post.fixado ? 'Desafixar' : 'Fixar no topo'),
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
                                  style: TextStyle(color: EagleTokens.bad),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _TypeBadge(tipo: post.tipoPost, color: badgeColor),
              const SizedBox(height: 8),
              Text(
                post.conteudo,
                style: FocuxHubTypography.body(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                        errorBuilder:
                            (_, __, ___) => _ImagePlaceholder(primary: primary),
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
                crossAxisAlignment: WrapCrossAlignment.center,
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
      ),
    );
  }
}
