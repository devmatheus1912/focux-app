import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';
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
