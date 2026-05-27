import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/design_tokens.dart';
import '../theme/theme_provider.dart';
import 'focux_official_logo.dart';

/// Logo/wordmark que respeita white-label do aluno (Enterprise).
class BrandedAppIdentity extends ConsumerWidget {
  const BrandedAppIdentity({
    super.key,
    this.size = 40,
    this.showLabel = true,
    this.light = true,
  });

  final double size;
  final bool showLabel;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hideFocux = ref.watch(hideFocuxBrandingProvider);
    final appName = ref.watch(appDisplayNameProvider);
    final personalName = ref.watch(personalNameProvider);
    final logoUrl = ref.watch(logoUrlProvider);

    final displayName = (appName != null && appName.trim().isNotEmpty)
        ? appName.trim()
        : (personalName != null && personalName.trim().isNotEmpty)
            ? personalName.trim()
            : 'Meu Personal';

    if (hideFocux) {
      Widget mark;
      if (logoUrl != null && logoUrl.trim().isNotEmpty) {
        mark = ClipOval(
          child: Image.network(
            logoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                FocuxOfficialLogo.icon(size: size),
          ),
        );
      } else {
        mark = CircleAvatar(
          radius: size / 2,
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            Icons.fitness_center_rounded,
            size: size * 0.48,
            color: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      if (!showLabel) return mark;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          SizedBox(width: size * 0.28),
          Flexible(
            child: Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w700,
                color: light ? Colors.white : EagleTokens.ink,
                height: 1.1,
              ),
            ),
          ),
        ],
      );
    }

    if (!showLabel) {
      return FocuxOfficialLogo.icon(size: size, logoUrl: logoUrl);
    }

    return FocuxOfficialLogo.compact(
      height: size,
      logoUrl: logoUrl,
    );
  }
}

class BrandedAppIcon extends ConsumerWidget {
  const BrandedAppIcon({super.key, this.size = 40, this.light = true});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(logoUrlProvider);
    return FocuxOfficialLogo.icon(size: size, logoUrl: logoUrl);
  }
}
