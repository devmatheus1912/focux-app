import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';

const _kRouteArgs = 'route_settings_arguments';
const _kSpanExtra = 'fxSentrySpan';

/// Sentry só para desempenho. Erros e crashes continuam no Crashlytics:
/// os handlers de erro do main sobrescrevem os do Sentry.
Future<void> initSentryPerformance() async {
  if (Env.sentryDsn.isEmpty) return;
  await SentryFlutter.init((o) {
    o.dsn = Env.sentryDsn;
    o.environment = Env.isProd ? 'production' : 'development';
    o.tracesSampleRate = Env.sentryTracesSampleRate;
    o.tracePropagationTargets
      ..clear()
      ..add(Uri.parse(Env.apiUrl).host);
    o.enableNativeCrashHandling = false;
    o.captureFailedRequests = false;
    o.beforeSendTransaction = stripRouteArguments;
  });
}

/// Args do go_router trazem query string (ex.: busca por nome de aluno).
@visibleForTesting
SentryTransaction stripRouteArguments(SentryTransaction tx) {
  final trace = tx.contexts.trace;
  final data = trace?.data;
  if (trace != null && data != null && data.containsKey(_kRouteArgs)) {
    tx.contexts.trace = SentryTraceContext.fromJson(
      trace.toJson()..['data'] = (Map.of(data)..remove(_kRouteArgs)),
    );
  }
  // ignore: deprecated_member_use
  final extra = tx.extra;
  if (extra == null || !extra.containsKey(_kRouteArgs)) return tx;
  // ignore: deprecated_member_use
  return tx.copyWith(extra: Map.of(extra)..remove(_kRouteArgs));
}

/// Um observer por Navigator (raiz, shells e cada branch).
List<NavigatorObserver> sentryNavObservers() => [
  SentryNavigatorObserver(
    routeNameExtractor: (s) => s == null ? null : RouteSettings(name: s.name),
  ),
];

/// Span por request + headers `sentry-trace`/`baggage` para o backend.
/// Interceptor (não sentry_dio): o app troca o httpClientAdapter no resume.
class SentryHttpSpanInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final parent = Sentry.getSpan();
    if (parent != null) {
      final span = parent.startChild(
        'http.client',
        description: '${options.method} ${options.path.split('?').first}',
      );
      options.extra[_kSpanExtra] = span;
      if (options.uri.host == Uri.parse(Env.apiUrl).host) {
        options.headers['sentry-trace'] = span.toSentryTrace().value;
        final baggage = span.toBaggageHeader();
        if (baggage != null) options.headers['baggage'] = baggage.value;
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _finish(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _finish(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _finish(RequestOptions options, int? status) {
    final span = options.extra.remove(_kSpanExtra);
    if (span is! ISentrySpan) return;
    if (status != null) span.setData('http.response.status_code', status);
    span.finish(
      status:
          status == null
              ? const SpanStatus.unknownError()
              : SpanStatus.fromHttpStatusCode(status),
    );
  }
}
