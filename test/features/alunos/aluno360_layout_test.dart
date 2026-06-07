import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/constants/aluno_360_layout.dart';

void main() {
  testWidgets('operacaoTopSnackMargin pins below header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final size = MediaQuery.sizeOf(context);
            final top =
                MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                Aluno360Layout.tabBarHeight +
                8;
            final margin = Aluno360Layout.operacaoTopSnackMargin(context);
            expect(margin.left, Aluno360Layout.screenPadding);
            expect(margin.right, Aluno360Layout.screenPadding);
            expect(
              margin.bottom,
              closeTo(
                size.height - top - Aluno360Layout.operacaoTopSnackHeight,
                1,
              ),
            );
            expect(margin.top, 0);
            return const SizedBox();
          },
        ),
      ),
    );
  });
}
