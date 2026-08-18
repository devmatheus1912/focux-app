import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/alunos_l10n.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  testWidgets('alunosL10n resolve even without S.delegate', (tester) async {
    late String title;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: const [Locale('pt')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            title = context.alunosL10n.alunosTitle;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(title, 'Alunos');
  });

  testWidgets('alunosL10n uses generated strings when S.delegate is registered', (
    tester,
  ) async {
    late String title;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: Builder(
          builder: (context) {
            title = context.alunosL10n.alunosTitle;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(title, 'Students');
  });
}
