import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/core/widgets/fx_lazy_indexed_stack.dart';

void main() {
  testWidgets('FxLazyIndexedStack only mounts visited tabs', (tester) async {
    var builtA = 0;
    var builtB = 0;
    var builtC = 0;

    Widget tab(String name, void Function() onBuild) {
      return Builder(
        builder: (context) {
          onBuild();
          return Text(name);
        },
      );
    }

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FxLazyIndexedStack(
          index: 0,
          children: [
            tab('A', () => builtA++),
            tab('B', () => builtB++),
            tab('C', () => builtC++),
          ],
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(builtA, greaterThan(0));
    expect(builtB, 0);
    expect(builtC, 0);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: FxLazyIndexedStack(
          index: 2,
          children: [
            tab('A', () => builtA++),
            tab('B', () => builtB++),
            tab('C', () => builtC++),
          ],
        ),
      ),
    );

    expect(find.text('C'), findsOneWidget);
    expect(builtB, 0);
    expect(builtC, greaterThan(0));
  });
}
