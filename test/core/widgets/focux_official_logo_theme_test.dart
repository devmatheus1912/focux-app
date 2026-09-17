import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/focux_official_logo.dart';

void main() {
  testWidgets('escolhe asset claro no tema light', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: FocuxOfficialLogo.full(width: 120),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    expect(
      (image.image as AssetImage).assetName,
      FocuxOfficialLogo.assetLight,
    );
  });

  testWidgets('escolhe asset escuro no tema dark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: FocuxOfficialLogo.full(width: 120),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      FocuxOfficialLogo.assetDark,
    );
  });
}
