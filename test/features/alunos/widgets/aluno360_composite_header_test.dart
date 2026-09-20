import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/features/alunos/constants/aluno_360_layout.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_composite_header.dart';

import '../../../support/tolerant_golden_comparator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    useTolerantGoldens();
  });

  testWidgets('hero strip aligns flush with tab bar at 390px width', (tester) async {
    const topInset = 44.0;
    const heroBodyHeight = 52.0;
    const heroKey = ValueKey('hero_strip_probe');
    final tabController = TabController(length: 3, vsync: const TestVSync());

    addTearDown(tabController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: topInset),
            ),
            child: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: Aluno360CompositeHeaderDelegate(
                    topInset: topInset,
                    heroBodyHeight: heroBodyHeight,
                    heroChild: Container(
                      key: heroKey,
                      height: 48,
                      color: const Color(0xFF12A3A3),
                    ),
                    tabController: tabController,
                    primary: const Color(0xFF12A3A3),
                    mute: Colors.grey,
                    line: Colors.grey,
                    displayName: 'Beatriz',
                    ink: Colors.black,
                    isDark: false,
                    onBack: () {},
                    actionsEnabled: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final heroBox = tester.renderObject<RenderBox>(find.byKey(heroKey));
    final tabBarBox = tester.renderObject<RenderBox>(
      find.byType(Aluno360DetailTabBar),
    );

    final heroBottom = heroBox.localToGlobal(Offset.zero).dy + heroBox.size.height;
    final tabTop = tabBarBox.localToGlobal(Offset.zero).dy;
    final gap = tabTop - heroBottom;

    expect(gap, lessThanOrEqualTo(1.0));
    expect(Aluno360Layout.tabContentGap, TokensStrip.s4);

    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('goldens/aluno360_composite_header_390.png'),
    );
  });
}

class TestVSync implements TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
