import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/hero_teal.dart';
import '../theme/tokens_strip.dart';
import 'focux_brand_tagline.dart';
import 'focux_official_logo.dart';

/// Lockup S6: logo oficial + tagline. Sem inset, sem chevron.
class FxConversionLockup extends StatelessWidget {
  const FxConversionLockup({
    super.key,
    required this.width,
    this.logoUrl,
    this.semanticLabel = 'Focux Personal',
    this.tagline,
    this.showTagline = true,
    this.taglineSize = 13.5,
    this.aluno = false,
  });

  final double width;
  final String? logoUrl;
  final String semanticLabel;
  final Widget? tagline;
  final bool showTagline;
  final double taglineSize;
  final bool aluno;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: semanticLabel,
          image: true,
          child: FocuxOfficialLogo.full(width: width, logoUrl: logoUrl),
        ),
        if (tagline != null) ...[
          const SizedBox(height: TokensStrip.s3),
          tagline!,
        ] else if (showTagline) ...[
          const SizedBox(height: TokensStrip.s3),
          FocuxBrandTagline(center: true, fontSize: taglineSize, aluno: aluno),
        ],
      ],
    );
  }
}

/// Alternativa S6 em texto — nunca compete com [FxLiquidPrimaryButton].
class FxConversionTextLink extends StatelessWidget {
  const FxConversionTextLink({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
    this.textColor,
    this.actionColor,
    this.fontSize = 14,
  });

  final String text;
  final String actionText;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? actionColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final primary = actionColor ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      link: onTap != null,
      button: onTap != null,
      enabled: onTap != null,
      label: '$text$actionText',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Align(
            alignment: Alignment.center,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: FocuxHubTypography.body(
                  color: textColor ?? heroTealSurface(0.82),
                ).copyWith(fontSize: fontSize),
                children: [
                  TextSpan(text: text),
                  TextSpan(
                    text: actionText,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Separador "ou" entre o P0 e o caminho Google (§9 S6).
class FxConversionDivider extends StatelessWidget {
  const FxConversionDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = heroTealSurface(0.2);
    return Row(
      children: [
        Expanded(child: Divider(color: line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
          child: Text(
            label,
            style: FocuxHubTypography.bodyMuted(
              color: heroTealSurface(0.82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: line, height: 1)),
      ],
    );
  }
}
