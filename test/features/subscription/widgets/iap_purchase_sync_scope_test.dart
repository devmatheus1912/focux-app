import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/subscription/services/iap_purchase_coordinator.dart';
import 'package:focux_app/features/subscription/services/iap_store.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';
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

  @override
  Future<void> buyNonConsumable(
    ProductDetails product, {
    String? accountToken,
    PurchaseDetails? replacing,
  }) async {}

  @override
  Future<PurchaseDetails?> activeAndroidSubscription(
    bool Function(String productId) isSupported,
  ) async => null;

  @override
  Future<bool?> introOfferEligible(String productId) async => null;
}

PurchaseDetails _compra(String id) => PurchaseDetails(
  purchaseID: id,
  productID: SubscriptionProducts.proMonthly,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'recibo',
    source: 'app_store',
  ),
  transactionDate: '1700000000000',
  status: PurchaseStatus.purchased,
);

Future<({_FakeAuth auth, _FakeStore store, List<int> refreshes})> _pump(
  WidgetTester tester, {
  AuthStatus status = AuthStatus.authenticated,
  UserRole? papel = UserRole.personal,
  bool refreshFalha = false,
}) async {
  final auth = _FakeAuth(status, papel);
  final store = _FakeStore();
  final refreshes = <int>[];
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
        builder:
            (context, child) => IapPurchaseSyncScope(
              refreshPlan: (_) async {
                refreshes.add(1);
                if (refreshFalha) throw StateError('sem rede');
              },
              child: child!,
            ),
        home: const Scaffold(body: Text('hoje')),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return (auth: auth, store: store, refreshes: refreshes);
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

  testWidgets('N compras validadas no mesmo lote: 1 refresh do plano', (
    tester,
  ) async {
    final h = await _pump(tester);

    h.store.controller.add([_compra('a'), _compra('b'), _compra('c')]);
    await tester.pump(const Duration(milliseconds: 50));

    expect(h.refreshes, hasLength(1));
  });

  testWidgets('lote sem compra validada não faz refresh', (tester) async {
    final h = await _pump(tester);

    h.store.controller.add(const []);
    await tester.pump(const Duration(milliseconds: 50));

    expect(h.refreshes, isEmpty);
  });

  testWidgets('erro no refresh do plano não quebra nem avisa', (tester) async {
    final h = await _pump(tester, refreshFalha: true);

    h.store.controller.add([_compra('a')]);
    await tester.pump(const Duration(milliseconds: 50));

    expect(h.refreshes, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('logout cancela o listener da loja', (tester) async {
    final h = await _pump(tester);
    expect(h.store.listeners, 1);

    h.auth.sair();
    await tester.pump(const Duration(milliseconds: 50));
    expect(h.store.listeners, 0);
  });
}
