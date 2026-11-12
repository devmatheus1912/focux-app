import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_video_rede.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';

/// Cartão de publicação do feed (personal e aluno).
///
/// O "⋯" abre uma folha montada pela tela ([onMais]): Editar/Fixar/Excluir
/// para o personal, Denunciar/Bloquear para o aluno. Nada de menu popup.
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
    this.curtido = false,
    this.onQuemCurtiu,
    this.onMais,
  });

  final FeedPost post;
  final int index;
  final Color primary;
  final int curtidas;
  final int comentarios;

  /// Aluno curte; o personal não (o coração dele só mostra o número).
  final VoidCallback? onCurtir;
  final bool curtido;
  final VoidCallback onComentar;

  /// Personal: o número de curtidas abre "Quem curtiu".
  final VoidCallback? onQuemCurtiu;
  final VoidCallback? onMais;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = Theme.of(context).colorScheme.onSurface;
    final mUrl = post.midiaUrl ?? post.imagemUrl;
    final temMidia = mUrl != null && mUrl.trim().isNotEmpty;
    final ehVideo = post.tipoPost == 'VIDEO';
    final ehDica = post.tipoPost == 'DICA';

    return FxStaggerItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: TokensStrip.s3),
        decoration: fxListCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s3,
            TokensStrip.s2,
            TokensStrip.s1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FeedPostAuthorHeader(post: post, primary: primary),
                  ),
                  if (onMais != null)
                    IconButton(
                      tooltip: 'Mais opções',
                      onPressed: onMais,
                      icon: Icon(FxIcons.mais, color: chrome.mute),
                    ),
                ],
              ),
              if (post.fixado || ehDica) ...[
                const SizedBox(height: TokensStrip.s2),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s1,
                  children: [
                    if (post.fixado)
                      FeedSelo(
                        icone: FxIcons.fixadoPequeno,
                        texto: 'Fixado',
                        cor: primary,
                      ),
                    if (ehDica)
                      const FeedSelo(
                        icone: FxIcons.ideiaPequeno,
                        texto: 'Dica',
                        cor: EagleTokens.warn,
                      ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(right: TokensStrip.s2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.titulo.trim().isNotEmpty) ...[
                      const SizedBox(height: TokensStrip.s3),
                      Text(
                        post.titulo.trim(),
                        style: FocuxHubTypography.cardTitle(color: ink),
                      ),
                    ],
                    if (post.conteudo.trim().isNotEmpty) ...[
                      SizedBox(
                        height:
                            post.titulo.trim().isEmpty
                                ? TokensStrip.s3
                                : TokensStrip.s1,
                      ),
                      Text(
                        post.conteudo.trim(),
                        style: FocuxHubTypography.body(color: ink),
                      ),
                    ],
                    if (temMidia) ...[
                      const SizedBox(height: TokensStrip.s3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(TokensStrip.rCard),
                        child:
                            ehVideo
                                ? FxVideoRede(url: mUrl)
                                : FeedFoto(url: mUrl, primary: primary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: TokensStrip.s1),
              Row(
                children: [
                  _FeedAcao(
                    icon: curtido ? FxIcons.favoritoAtivo : FxIcons.favorito,
                    cor: curtido ? EagleTokens.bad : null,
                    total: curtidas,
                    rotulo:
                        onCurtir != null
                            ? (curtido ? 'Descurtir' : 'Curtir')
                            : 'Quem curtiu',
                    onTap: onCurtir ?? (curtidas > 0 ? onQuemCurtiu : null),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  _FeedAcao(
                    icon: FxIcons.chat,
                    total: comentarios,
                    rotulo: 'Comentários',
                    onTap: onComentar,
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

class _FeedAcao extends StatelessWidget {
  const _FeedAcao({
    required this.icon,
    required this.total,
    required this.rotulo,
    this.cor,
    this.onTap,
  });

  final IconData icon;
  final int total;
  final String rotulo;
  final Color? cor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return Semantics(
      button: onTap != null,
      label: '$rotulo, $total',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: TokensStrip.s1),
              Icon(icon, size: 22, color: cor ?? mute),
              if (total > 0) ...[
                const SizedBox(width: TokensStrip.s1),
                Text('$total', style: FocuxHubTypography.rotulo(color: mute)),
              ],
              const SizedBox(width: TokensStrip.s1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selo pequeno do cabeçalho ("Fixado", "Dica").
class FeedSelo extends StatelessWidget {
  const FeedSelo({
    super.key,
    required this.icone,
    required this.texto,
    required this.cor,
  });

  final IconData icone;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: cor),
          const SizedBox(width: TokensStrip.s1),
          Text(texto, style: FocuxHubTypography.minimo(color: cor)),
        ],
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
    final name =
        post.autorNome?.trim().isNotEmpty == true
            ? post.autorNome!.trim()
            : 'Personal';
    final avatarUrl = post.autorAvatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final mute = ShellChrome.of(context).mute;
    final criado = DateTime.tryParse(post.criadoEm);

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: primary.withValues(alpha: 0.14),
          backgroundImage:
              hasAvatar
                  ? fxCachedNetworkImageProvider(avatarUrl, maxWidth: 72)
                  : null,
          child:
              hasAvatar
                  ? null
                  : Text(
                    fxInitials(name),
                    style: FocuxHubTypography.rotulo(color: primary),
                  ),
        ),
        const SizedBox(width: TokensStrip.s3),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (criado != null)
                Text(
                  feedQuando(criado),
                  style: FocuxHubTypography.bodyMuted(color: mute),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Foto na proporção dela (de 4:5 a 1,91:1). Fora disso, inteira sobre um
/// fundo desfocado da própria imagem: nunca corta rosto nem texto.
class FeedFoto extends StatefulWidget {
  const FeedFoto({super.key, required this.url, required this.primary});

  final String url;
  final Color primary;

  @override
  State<FeedFoto> createState() => _FeedFotoState();
}

class _FeedFotoState extends State<FeedFoto> {
  ImageStream? _stream;
  late final _ouvinte = ImageStreamListener(_recebeu, onError: (_, __) {});
  double? _proporcao;

  ImageProvider get _provider =>
      fxCachedNetworkImageProvider(widget.url, maxWidth: 1080);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolver();
  }

  @override
  void didUpdateWidget(FeedFoto old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _proporcao = null;
      _resolver();
    }
  }

  void _resolver() {
    final novo = _provider.resolve(createLocalImageConfiguration(context));
    if (novo.key == _stream?.key) return;
    _stream?.removeListener(_ouvinte);
    _stream = novo..addListener(_ouvinte);
  }

  void _recebeu(ImageInfo info, bool _) {
    final w = info.image.width.toDouble();
    final h = info.image.height.toDouble();
    if (!mounted || w <= 0 || h <= 0) return;
    setState(() => _proporcao = w / h);
  }

  @override
  void dispose() {
    _stream?.removeListener(_ouvinte);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final real = _proporcao ?? 1;
    final fundo = _proporcao != null && feedPrecisaFundo(real);
    Widget imagem(BoxFit fit) => Image(
      image: _provider,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: true,
      errorBuilder:
          (_, __, ___) => FeedImagePlaceholder(primary: widget.primary),
    );
    return AspectRatio(
      aspectRatio: feedProporcaoCartao(real),
      child:
          fundo
              ? Stack(
                fit: StackFit.expand,
                children: [
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: imagem(BoxFit.cover),
                  ),
                  ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
                  imagem(BoxFit.contain),
                ],
              )
              : imagem(BoxFit.cover),
    );
  }
}

class FeedImagePlaceholder extends StatelessWidget {
  const FeedImagePlaceholder({super.key, required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.18),
            BrandPalette.deep(primary).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(FxIcons.imagem, color: primary, size: 28)),
    );
  }
}
