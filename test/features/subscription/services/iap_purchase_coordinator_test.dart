import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/services/iap_purchase_coordinator.dart';
import 'package:focux_app/features/subscription/services/iap_purchase_event.dart';
import 'package:focux_app/features/subscription/services/iap_store.dart';
import 'package:focux_app/features/subscription/subscription_products.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class _FakeStore implements IapStore {
  bool available = true;
  int listeners = 0;
  int restoreCalls = 0;
  final completed = <PurchaseDetails>[];
  void Function()? onRestore;

  late final StreamController<List<PurchaseDetails>> controller =
      StreamController<List<PurchaseDetails>>.broadcast(
        onListen: () => listeners++,
        onCancel: () => listeners--,
      );

  void entregar(List<PurchaseDetails> compras) => controller.add(compras);

  @override
  Future<bool> isAvailable() async => available;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls++;
    onRestore?.call();
  }

  final bought = <ProductDetails>[];

  @override
  Future<void> buyNonConsumable(ProductDetails product) async {
    bought.add(product);
  }
}

DioException _dio({int? status, DioExceptionType? type}) {
  final req = RequestOptions(path: '/api/iap/verify');
  return DioException(
    requestOptions: req,
    type:
        type ??
        (status == null
            ? DioExceptionType.connectionError
            : DioExceptionType.badResponse),
    response:
        status == null
            ? null
            : Response(requestOptions: req, statusCode: status),
  );
}

final _produto = ProductDetails(
  id: SubscriptionProducts.proMonthly,
  title: 'PRO',
  description: 'PRO mensal',
  price: r'R$ 49,90',
  rawPrice: 49.9,
  currencyCode: 'BRL',
);

PurchaseDetails _compra({
  String id = 'tx-1',
  String produto = SubscriptionProducts.proMonthly,
  PurchaseStatus status = PurchaseStatus.purchased,
  bool pendente = true,
}) {
  return PurchaseDetails(
    purchaseID: id,
    productID: produto,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'recibo',
      source: 'app_store',
    ),
    transactionDate: '1700000000000',
    status: status,
  )..pendingCompletePurchase = pendente;
}

Future<void> _drenar() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeStore store;
  late List<PurchaseDetails> verificadas;
  late Future<Map<String, dynamic>> Function(PurchaseDetails) verify;
  late IapPurchaseCoordinator coordinator;
  late List<IapPurchaseEvent> eventos;

  setUp(() {
    store = _FakeStore();
    verificadas = [];
    verify = (p) async {
      verificadas.add(p);
      return {'status': 'PROCESSADO'};
    };
    coordinator = IapPurchaseCoordinator(
      store: store,
      verify: (p) => verify(p),
      isAndroid: false,
    );
    eventos = [];
    coordinator.events.listen(eventos.add);
  });

  tearDown(() => coordinator.dispose());

  test('compra entregue: valida 1x no servidor e conclui na loja', () async {
    expect(await coordinator.start(), isTrue);
    final compra = _compra();

    store.entregar([compra]);
    await _drenar();

    expect(verificadas, [compra]);
    expect(store.completed, [compra]);
    expect(eventos.whereType<IapPurchaseVerifying>(), hasLength(1));
    final ok = eventos.whereType<IapPurchaseVerified>().single;
    expect(ok.purchase, compra);
    expect(ok.response['status'], 'PROCESSADO');
  });

  test('Android: start reconsulta compras pendentes', () async {
    await coordinator.dispose();
    coordinator = IapPurchaseCoordinator(
      store: store,
      verify: (p) => verify(p),
      isAndroid: true,
    );
    expect(await coordinator.start(), isTrue);
    expect(store.restoreCalls, 1);
  });

  group('conclusão depois de verify com erro', () {
    Future<void> entregarComErro(Object erro) async {
      verify = (_) async => throw erro;
      await coordinator.start();
      store.entregar([_compra()]);
      await _drenar();
    }

    test('iOS + sem conexão: não conclui (StoreKit reentrega)', () async {
      await entregarComErro(_dio());

      expect(eventos.whereType<IapPurchaseVerifyFailed>(), hasLength(1));
      expect(eventos.whereType<IapPurchaseVerified>(), isEmpty);
      expect(store.completed, isEmpty);
    });

    test('iOS + 5xx / 429 / timeout: não conclui', () async {
      await coordinator.start();
      final erros = <Object>[
        _dio(status: 503),
        _dio(status: 429),
        _dio(type: DioExceptionType.receiveTimeout),
      ];
      for (final (i, erro) in erros.indexed) {
        verify = (_) async => throw erro;
        store.entregar([_compra(id: 'tx-$i')]);
        await _drenar();
      }

      expect(eventos.whereType<IapPurchaseVerifyFailed>(), hasLength(3));
      expect(store.completed, isEmpty);
    });

    test(
      'iOS + 4xx (403 de não-dono): conclui para não entrar em loop',
      () async {
        await entregarComErro(_dio(status: 403));

        expect(eventos.whereType<IapPurchaseVerifyFailed>(), hasLength(1));
        expect(store.completed, hasLength(1));
      },
    );

    test('iOS + erro que não é HTTP: conclui', () async {
      await entregarComErro(Exception('resposta inesperada'));

      expect(store.completed, hasLength(1));
    });

    test('Android + sem conexão: conclui sempre (acknowledge)', () async {
      final android = IapPurchaseCoordinator(
        store: store,
        verify: (_) async => throw _dio(),
        isAndroid: true,
      );
      addTearDown(android.dispose);
      await coordinator.stop();
      await android.start();

      store.entregar([_compra()]);
      await _drenar();

      expect(store.completed, hasLength(1));
    });
  });

  test(
    'mesma compra repetida durante a validação não valida duas vezes',
    () async {
      final liberar = Completer<void>();
      verify = (p) async {
        verificadas.add(p);
        await liberar.future;
        return {'status': 'PROCESSADO'};
      };
      await coordinator.start();

      store.entregar([_compra()]);
      await _drenar();
      store.entregar([_compra()]);
      await _drenar();
      liberar.complete();
      await _drenar();

      expect(verificadas, hasLength(1));
      expect(store.completed, hasLength(1));
    },
  );

  test('start é idempotente: um único listener no stream da loja', () async {
    await Future.wait([coordinator.start(), coordinator.start()]);
    await coordinator.start();

    expect(store.listeners, 1);
    expect(coordinator.isListening, isTrue);
  });

  test('loja indisponível: não ouve o stream', () async {
    store.available = false;

    expect(await coordinator.start(), isFalse);
    expect(store.listeners, 0);
    expect(coordinator.isListening, isFalse);
  });

  test('depois do logout (stop) a compra entregue é ignorada', () async {
    await coordinator.start();
    await coordinator.stop();

    store.entregar([_compra()]);
    await _drenar();

    expect(store.listeners, 0);
    expect(verificadas, isEmpty);
    expect(store.completed, isEmpty);
  });

  test('logout no meio do lote: o restante do lote é ignorado', () async {
    verify = (p) async {
      verificadas.add(p);
      await coordinator.stop();
      return {'status': 'PROCESSADO'};
    };
    await coordinator.start();
    final primeira = _compra(id: 'tx-1');
    final segunda = _compra(id: 'tx-2');

    store.entregar([primeira, segunda]);
    await _drenar();

    expect(verificadas, [primeira]);
    expect(store.completed, [primeira]);
    expect(eventos.whereType<IapPurchaseVerified>(), isEmpty);
  });

  test('stop durante o start não deixa listener pendurado', () async {
    final starting = coordinator.start();
    await coordinator.stop();

    expect(await starting, isFalse);
    expect(store.listeners, 0);
  });

  test('produto desconhecido: não valida, avisa e conclui', () async {
    await coordinator.start();
    final compra = _compra(produto: 'outro_app_sku');

    store.entregar([compra]);
    await _drenar();

    expect(verificadas, isEmpty);
    expect(eventos.whereType<IapPurchaseUnsupported>(), hasLength(1));
    expect(store.completed, [compra]);
  });

  test('SKU premium legado: valida no servidor e conclui', () async {
    await coordinator.start();
    final compra = _compra(
      produto: 'focux_premium_yearly',
      status: PurchaseStatus.restored,
    );

    store.entregar([compra]);
    await _drenar();

    expect(verificadas, [compra]);
    expect(eventos.whereType<IapPurchaseUnsupported>(), isEmpty);
    expect(eventos.whereType<IapPurchaseVerified>(), hasLength(1));
    expect(store.completed, [compra]);
  });

  test('pendente e cancelada não chamam o servidor', () async {
    await coordinator.start();

    store.entregar([
      _compra(id: 'a', status: PurchaseStatus.pending, pendente: false),
      _compra(id: 'b', status: PurchaseStatus.canceled),
    ]);
    await _drenar();

    expect(verificadas, isEmpty);
    expect(eventos.whereType<IapPurchasePending>(), hasLength(1));
    expect(eventos.whereType<IapPurchaseCanceled>(), hasLength(1));
    expect(store.completed.map((p) => p.purchaseID), ['b']);
  });

  test('erro da loja vira evento e conclui a transação pendente', () async {
    await coordinator.start();

    store.entregar([_compra(status: PurchaseStatus.error)]);
    await _drenar();

    expect(verificadas, isEmpty);
    expect(eventos.whereType<IapPurchaseStoreError>(), hasLength(1));
    expect(store.completed, hasLength(1));
  });

  group('restore', () {
    test('valida as compras restauradas pelo mesmo fluxo central', () async {
      store.onRestore =
          () => store.entregar([
            _compra(id: 'r1', status: PurchaseStatus.restored),
            _compra(id: 'r2', status: PurchaseStatus.restored),
          ]);

      final result = await coordinator.restore(
        timeout: const Duration(milliseconds: 200),
        quietPeriod: const Duration(milliseconds: 10),
      );

      expect(result.storeAvailable, isTrue);
      expect(result.verifiedCount, 2);
      expect(result.hasFailures, isFalse);
      expect(verificadas, hasLength(2));
      expect(store.completed, hasLength(2));
      expect(store.listeners, 1, reason: 'sem listener paralelo');
    });

    test('falha de validação conta como falha, sem mensagem crua', () async {
      verify = (_) async => throw Exception('boom');
      store.onRestore =
          () => store.entregar([_compra(status: PurchaseStatus.restored)]);

      final result = await coordinator.restore(
        timeout: const Duration(milliseconds: 200),
        quietPeriod: const Duration(milliseconds: 10),
      );

      expect(result.verifiedCount, 0);
      expect(result.hasFailures, isTrue);
    });

    test('nada a restaurar termina no timeout', () async {
      final result = await coordinator.restore(
        timeout: const Duration(milliseconds: 20),
        quietPeriod: const Duration(milliseconds: 10),
      );

      expect(store.restoreCalls, 1);
      expect(result.storeAvailable, isTrue);
      expect(result.hasVerifiedPurchases, isFalse);
      expect(result.hasFailures, isFalse);
    });

    test('loja indisponível não chama restorePurchases', () async {
      store.available = false;

      final result = await coordinator.restore();

      expect(result.storeAvailable, isFalse);
      expect(store.restoreCalls, 0);
    });

    test('logout (stop) durante o restore encerra o restore', () async {
      final restoring = coordinator.restore(
        timeout: const Duration(minutes: 5),
      );
      await _drenar();
      await coordinator.stop();

      final result = await restoring.timeout(const Duration(seconds: 1));

      expect(result.storeAvailable, isTrue);
      expect(result.hasVerifiedPurchases, isFalse);
      expect(store.listeners, 0);
    });
  });

  group('buy', () {
    test('garante o listener antes de abrir a compra', () async {
      expect(await coordinator.buy(_produto), isTrue);

      expect(store.listeners, 1);
      expect(store.bought, [_produto]);
    });

    test('loja indisponível: não abre a compra e devolve false', () async {
      store.available = false;

      expect(await coordinator.buy(_produto), isFalse);
      expect(store.bought, isEmpty);
    });
  });
}
