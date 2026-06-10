import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../widgets/coach_proativo_card.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return fxScreenA11yScope(
      label: 'Coach proativo',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Coach proativo',
          subtitle: 'Mensagens e orientações automáticas',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(TokensStrip.s4),
          children: [
            CoachProativoCard(isDark: isDark),
          ],
        ),
      ),
    );
  }
}
