import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/data/auth_repository.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/auth/screens/login_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/dynamic_type_harness.dart';

class _AuthOffline implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('offline'));
}

Future<void> _pumpLogin(WidgetTester tester, Size tela, String rota) async {
  await tester.binding.setSurfaceSize(tela);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: rota,
    routes: [GoRoute(path: '/login', builder: (_, __) => const LoginScreen())],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(_AuthOffline())],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final tela in kDynamicTypeTelas) {
    for (final rota in ['/login?role=personal', '/login?role=aluno&p=ana']) {
      testWidgets('login $rota aguenta ${descreverTela(tela)}', (tester) async {
        usarDynamicTypeMaximo(tester, tela);
        await _pumpLogin(tester, tela, rota);
        expect(find.text('E-mail'), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
