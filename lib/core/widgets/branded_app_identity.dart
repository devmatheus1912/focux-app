import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/theme_provider.dart';
import '../../features/perfil/utils/brand_slogan_display.dart';
import 'focux_official_logo.dart';

class BrandedAppIcon extends ConsumerWidget {
  const BrandedAppIcon({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoUrl = ref.watch(logoUrlProvider);
    return FocuxOfficialLogo.icon(size: size, logoUrl: logoUrl);
  }
}

/// Nome + slogan da marca ativa (white-label / personal logado).
class BrandedAppWordmark extends ConsumerWidget {
  const BrandedAppWordmark({
    super.key,
    this.compact = false,
    this.maxLines = 2,
  });

  final bool compact;
  final int maxLines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mute = Theme.of(context).colorScheme.onSurfaceVariant;
    final ink = Theme.of(context).colorScheme.onSurface;
    final hideFocux = ref.watch(hideFocuxBrandingProvider);
    final appName = ref.watch(appDisplayNameProvider)?.trim();
    final personalName = ref.watch(personalNameProvider)?.trim();
    final slogan = ref.watch(sloganProvider)?.trim();

    final title =
        hideFocux
            ? ((appName != null && appName.isNotEmpty)
                ? appName
                : (personalName != null && personalName.isNotEmpty)
                ? personalName
                : 'Meu Personal')
            : (personalName != null && personalName.isNotEmpty)
            ? personalName
            : 'Focux';

    final sloganText =
        (slogan != null && slogan.isNotEmpty)
            ? formatBrandSloganForDisplay(slogan)
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.cardTitle(color: ink).copyWith(
            fontSize: compact ? 15 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (sloganText != null) ...[
          const SizedBox(height: 2),
          Text(
            sloganText,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(
              color: mute,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ).copyWith(fontSize: compact ? 11.5 : 12.5),
          ),
        ],
      ],
    );
  }
}
