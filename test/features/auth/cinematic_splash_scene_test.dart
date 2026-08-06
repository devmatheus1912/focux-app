import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_brand_copy.dart';
import 'package:focux_app/core/theme/app_theme.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/focux_brand_tagline.dart';
import 'package:focux_app/core/widgets/focux_official_logo.dart';
import 'package:focux_app/features/auth/widgets/cinematic_splash_scene.dart';

void main() {
  testWidgets('splash compact ainda mostra lockup e tagline', (tester) async {
    final entry = AlwaysStoppedAnimation(1.0);
    final ambient = AlwaysStoppedAnimation(0.0);
    final fadeOut = AlwaysStoppedAnimation(1.0);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildDarkTheme(TokensStrip.neonGlow),
        home: Scaffold(
          body: CinematicSplashScene(
            progress: 0.6,
            ambient: ambient,
            entry: entry,
            fadeOut: fadeOut,
            compact: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FocuxBrandTagline), findsOneWidget);
    expect(find.byType(FocuxOfficialLogo), findsWidgets);
    expect(
      find.text(FocuxBrandCopy.splashLoading.toUpperCase()),
      findsOneWidget,
    );
  });
}
