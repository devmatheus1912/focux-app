import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/config/env.dart';
import 'package:focux_app/core/observability/sentry_performance.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString('{}', 200);
  }

  @override
  void close({bool force = false}) {}
}

class _NoOpTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => null;
}

void main() {
  late _CaptureAdapter adapter;
  late Dio dio;
  SentryTransaction? sent;

  setUp(() async {
    sent = null;
    await Sentry.init((o) {
      o.dsn = 'https://key@o0.ingest.sentry.io/0';
      o.tracesSampleRate = 1.0;
      o.transport = _NoOpTransport();
      o.beforeSendTransaction = (tx) => sent = stripRouteArguments(tx);
    });
    adapter = _CaptureAdapter();
    dio = Dio(BaseOptions(baseUrl: Env.apiUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(SentryHttpSpanInterceptor());
  });

  tearDown(() => Sentry.close());

  test('remove args da rota antes de enviar a transação', () async {
    final tx = Sentry.startTransaction('/alunos', 'ui.load');
    tx.setData('route_settings_arguments', {'q': 'texto'});
    tx.setData('outro', 1);
    await tx.finish();

    expect(sent, isNotNull);
    final data = sent!.contexts.trace!.data!;
    expect(data, isNot(contains('route_settings_arguments')));
    expect(data, contains('outro'));
    // ignore: deprecated_member_use
    expect(sent!.extra, isNot(contains('route_settings_arguments')));
  });

  test('sem transação ativa não envia headers de trace', () async {
    await dio.get('/api/x');
    expect(adapter.requests.single.headers, isNot(contains('sentry-trace')));
  });

  test('com transação propaga só para o host da API, sem query no span', () async {
    final tx = Sentry.startTransaction('t', 'ui.load', bindToScope: true);

    await dio.get('/api/x?q=texto');
    await dio.get('https://outro.example.com/arquivo');
    await tx.finish();

    final api = adapter.requests[0].headers;
    expect(api['sentry-trace'], startsWith(tx.context.traceId.toString()));
    expect(adapter.requests[1].headers, isNot(contains('sentry-trace')));
    final spans = sent!.spans.map((s) => s.context.description).toList();
    expect(spans, contains('GET /api/x'));
  });
}
