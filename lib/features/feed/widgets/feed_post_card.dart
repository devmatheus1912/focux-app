import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/safe_external_launch.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';

/// Card de publicação do feed (personal + aluno).
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({
    super.key,
    required this.post,
    required this.index,
    required this.primary,
    required this.curtidas,
    required this.comentarios,
    required this.onComentar,
    this.onCurtir,
    this.onFixar,
    this.onExcluir,
  });

  final FeedPost post;
  final int index;
  final Color primary;
  final int curtidas;
  final int comentarios;
  final VoidCallback? onCurtir;
  final VoidCallback onComentar;
  final VoidCallback? onFixar;
  final VoidCallback? onExcluir;

  bool get _canManage => onFixar != null || onExcluir != null;

  @override
  Widget build(BuildContext context) {
    final mUrl = post.midiaUrl ?? post.imagemUrl;
    final badgeColor = feedBadgeColor(post.tipoPost, primary);

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
              FeedPostAuthorHeader(post: post, primary: primary),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (post.fixado) ...[
                    Icon(Icons.push_pin, color: primary, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    feedTipoIcon(post.tipoPost),
                    size: 20,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.titulo,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (_canManage)
                    PopupMenuButton<String>(
                      tooltip: 'Ações',
                      onSelected: (val) {
                        if (val == 'fixar') onFixar?.call();
                        if (val == 'excluir') onExcluir?.call();
                      },
                      itemBuilder: (ctx) => [
                        if (onFixar != null)
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
                                Text(
                                  post.fixado
                                      ? 'Desafixar'
                                      : 'Fixar no topo',
                                ),
                              ],
                            ),
                          ),
                        if (onExcluir != null)
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
              FeedTypeBadge(tipo: post.tipoPost, color: badgeColor),
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
                    ? FeedVideoAttachmentTile(primary: primary, url: mUrl)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(TokensStrip.rCard),
                        child: Image.network(
                          mUrl,
                          fit: BoxFit.cover,
                          height: 168,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              FeedImagePlaceholder(primary: primary),
                        ),
                      ),
              ] else if (post.tipoPost == 'IMAGEM') ...[
                const SizedBox(height: 12),
                FeedImagePlaceholder(primary: primary),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onCurtir != null)
                    TextButton.icon(
                      onPressed: onCurtir,
                      icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                      label: Text('$curtidas Curtir'),
                    )
                  else
                    Text(
                      '$curtidas curtidas',
                      style: FocuxHubTypography.bodyMuted(
                        color: ShellChrome.of(context).mute,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: onComentar,
                    icon: const Icon(Icons.comment_outlined, size: 18),
                    label: Text('$comentarios comentários'),
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

class FeedTypeBadge extends StatelessWidget {
  const FeedTypeBadge({super.key, required this.tipo, required this.color});

  final String? tipo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        feedTipoLabel(tipo),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class FeedPostAuthorHeader extends StatelessWidget {
  const FeedPostAuthorHeader({
    super.key,
    required this.post,
    required this.primary,
  });

  final FeedPost post;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final name = post.autorNome?.trim().isNotEmpty == true
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

class FeedImagePlaceholder extends StatelessWidget {
  const FeedImagePlaceholder({super.key, required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
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

class FeedVideoAttachmentTile extends StatelessWidget {
  const FeedVideoAttachmentTile({
    super.key,
    required this.primary,
    this.url,
  });

  final Color primary;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: url == null || url!.isEmpty
            ? null
            : () => showFxHomeSheet<void>(
                  context,
                  builder: (_) => _FeedVideoPreview(
                    url: url!,
                    primary: primary,
                  ),
                ),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Ink(
          height: 168,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
            gradient: LinearGradient(
              colors: [
                BrandPalette.deep(primary),
                primary.withValues(alpha: 0.74),
              ],
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
        ),
      ),
    );
  }
}

class _FeedVideoPreview extends StatelessWidget {
  const _FeedVideoPreview({required this.url, required this.primary});

  final String url;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxHomeSheetHandle(
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: BrandPalette.deep(primary),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => launchSafeHttpUrl(url),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Abrir vídeo'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData feedTipoIcon(String? tipo) {
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

Color feedBadgeColor(String? tipo, Color primary) {
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
