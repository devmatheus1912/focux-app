import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/focux_hierarchy.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  const ink = Color(0xFF1A1A2E);

  test('type scale preserves visual hierarchy ordering', () {
    final page = FocuxHierarchy.pageTitle(color: ink);
    final section = FocuxHierarchy.sectionTitle(color: ink);
    final card = FocuxHierarchy.cardTitle(color: ink);
    final caption = FocuxHierarchy.caption(color: ink);

    expect(page.fontSize, greaterThan(section.fontSize!));
    expect(section.fontSize, greaterThan(card.fontSize!));
    expect(card.fontSize, greaterThanOrEqualTo(caption.fontSize!));
    expect(page.fontSize, TokensStrip.fontH1);
    expect(section.fontSize, TokensStrip.fontH2);
    expect(caption.fontSize, TokensStrip.fontBodySm);
  });

  test('elevation layers are monotonically ordered', () {
    expect(FocuxHierarchy.layerBase, lessThan(FocuxHierarchy.layerRaised));
    expect(FocuxHierarchy.layerRaised, lessThan(FocuxHierarchy.layerSticky));
    expect(FocuxHierarchy.layerSticky, lessThan(FocuxHierarchy.layerOverlay));
    expect(FocuxHierarchy.layerOverlay, lessThan(FocuxHierarchy.layerModal));
  });

  test('elevation layers delegate to TokensStrip shadows', () {
    expect(
      FocuxHierarchy.elevationLayer(FocuxHierarchy.layerBase, dark: false),
      isEmpty,
    );
    expect(
      FocuxHierarchy.elevationLayer(FocuxHierarchy.layerSticky, dark: false),
      isNotEmpty,
    );
  });
}
