import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_sheet_frame.dart';

void main() {
  testWidgets('lista dentro da folha aparece, sem erro de altura', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FxSheetFrame(
              title: 'Escolher exercício',
              expand: true,
              rolar: false,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: const [ListTile(title: Text('Supino reto'))],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Supino reto'), findsOneWidget);
  });
}
