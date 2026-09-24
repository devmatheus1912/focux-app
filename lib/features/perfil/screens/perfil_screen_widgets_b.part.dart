part of 'perfil_screen.dart';

class _Avatar extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final Color primaryColor;
  final int profileScore;
  final VoidCallback onTap;
  final bool loading;
  final String semanticsLabel;

  const _Avatar({
    required this.nome,
    required this.logoUrl,
    required this.primaryColor,
    required this.profileScore,
    required this.onTap,
    required this.loading,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    const size = FxSettingsLayout.avatarSize;
    final inner = size - TokensStrip.s3;
    final chrome = ShellChrome.of(context);
    final progress = (profileScore.clamp(0, 100)) / 100.0;
    final track = primaryColor.withValues(alpha: chrome.isDark ? 0.22 : 0.16);
    Widget avatarContent() {
      return Text(
        _initials(nome),
        style: FxSettingsLayout.avatarInitials(color: primaryColor),
      );
    }

    return Semantics(
      button: true,
      label: '$semanticsLabel. Perfil $profileScore por cento completo.',
      enabled: !loading,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _ProfileScoreRingPainter(
                progress: progress,
                color: primaryColor,
                trackColor: track,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size - 10,
                height: size - 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: chrome.cardFill,
                  boxShadow: const [
                    BoxShadow(
                      color: EagleTokens.shadowSoft,
                      blurRadius: TokensStrip.blurLight,
                      offset: Offset(0, TokensStrip.s2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child:
                      logoUrl != null && logoUrl!.isNotEmpty
                          ? FxCachedNetworkImage(
                            imageUrl: logoUrl!,
                            width: inner,
                            height: inner,
                            fit: BoxFit.cover,
                            memCacheWidth: (inner * 2).round(),
                            errorBuilder: (_, __, ___) => avatarContent(),
                          )
                          : avatarContent(),
                ),
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 1,
            child: InkWell(
              onTap: loading ? null : onTap,
              borderRadius: BorderRadius.circular(FxSettingsLayout.editBadge),
              child: Container(
                width: FxSettingsLayout.editBadge,
                height: FxSettingsLayout.editBadge,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: chrome.cardFill,
                    width: TokensStrip.s1 / 2,
                  ),
                ),
                child:
                    loading
                        ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: FxLoading(strokeWidth: 2, color: Colors.white),
                        )
                        : const Icon(Icons.edit, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileScoreRingPainter extends CustomPainter {
  _ProfileScoreRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.2;
    final rect = Offset.zero & size;
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round;
    paint.color = trackColor;
    canvas.drawArc(rect.deflate(stroke / 2), 0, 6.283185307179586, false, paint);
    paint.color = color;
    canvas.drawArc(
      rect.deflate(stroke / 2),
      -1.5707963267948966,
      6.283185307179586 * progress.clamp(0.0, 1.0),
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileScoreRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
