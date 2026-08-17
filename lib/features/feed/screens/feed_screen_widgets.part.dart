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
