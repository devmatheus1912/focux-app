import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/subscription/services/iap_purchase_coordinator.dart';
import 'package:focux_app/features/subscription/services/iap_store.dart';
import 'package:focux_app/features/subscription/utils/iap_session_gate.dart';
import 'package:focux_app/features/subscription/widgets/iap_purchase_sync_scope.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.inicial, this.papel);

  final AuthStatus inicial;
  UserRole? papel;

  @override
  UserRole? get currentRole => papel;

  @override
  AuthStatus build() => inicial;

  void entrar(UserRole role) {
    papel = role;
    state = AuthStatus.authenticated;
  }

  void sair() {
    papel = null;
    state = AuthStatus.unauthenticated;
  }
}

class _FakeStore implements IapStore {
  int listeners = 0;

  late final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast(
        onListen: () => listeners++,
        onCancel: () => listeners--,
      );

  @override
  Future<bool> isAvailable() async => true;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  Future<void> restorePurchases() async {}
}

Future<({_FakeAuth auth, _FakeStore store})> _pump(
  WidgetTester tester, {
  AuthStatus status = AuthStatus.authenticated,
  UserRole? papel = UserRole.personal,
}) async {
  final auth = _FakeAuth(status, papel);
  final store = _FakeStore();
  final coordinator = IapPurchaseCoordinator(
    store: store,
    verify: (_) async => {'status': 'PROCESSADO'},
  );
  addTearDown(coordinator.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith(() => auth),
        iapPurchaseCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp(
        builder: (context, child) => IapPurchaseSyncScope(child: child!),
        home: const Scaffold(body: Text('hoje')),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return (auth: auth, store: store);
}

void main() {
  group('iapShouldListenForPurchases', () {
    test('só personal autenticado ouve compras', () {
      expect(
        iapShouldListenForPurchases(
          status: AuthStatus.authenticated,
          role: UserRole.personal,
        ),
        isTrue,
      );
      expect(
        iapShouldListenForPurchases(
          status: AuthStatus.authenticated,
          role: UserRole.aluno,
        ),
        isFalse,
      );
      expect(
        iapShouldListenForPurchases(
          status: AuthStatus.authenticated,
          role: null,
        ),
        isFalse,
      );
      expect(
        iapShouldListenForPurchases(
          status: AuthStatus.unknown,
          role: UserRole.personal,
        ),
        isFalse,
      );
      expect(
        iapShouldListenForPurchases(
          status: AuthStatus.unauthenticated,
          role: UserRole.personal,
        ),
        isFalse,
      );
    });
  });

  testWidgets('personal logado: ouve a loja ao abrir o app', (tester) async {
    final h = await _pump(tester);
    expect(h.store.listeners, 1);
  });

  testWidgets('aluno logado: não ouve a loja', (tester) async {
    final h = await _pump(tester, papel: UserRole.aluno);
    expect(h.store.listeners, 0);
  });

  testWidgets('deslogado espera o login do personal', (tester) async {
    final h = await _pump(
      tester,
      status: AuthStatus.unauthenticated,
      papel: null,
    );
    expect(h.store.listeners, 0);

    h.auth.entrar(UserRole.personal);
    await tester.pump(const Duration(milliseconds: 50));
    expect(h.store.listeners, 1);
  });

  testWidgets('logout cancela o listener da loja', (tester) async {
    final h = await _pump(tester);
    expect(h.store.listeners, 1);

    h.auth.sair();
    await tester.pump(const Duration(milliseconds: 50));
    expect(h.store.listeners, 0);
  });
}
