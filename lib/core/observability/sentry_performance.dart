import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';

const _kRouteArgs = 'route_settings_arguments';
const _kSpanExtra = 'fxSentrySpan';

/// Inicializa o Sentry com: erros, tracing, session replay (só em crashes),
/// logs estruturados e captura de falhas HTTP 5xx.
Future<void> initSentryPerformance() async {
  if (Env.sentryDsn.isEmpty) return;

  await SentryFlutter.init((o) {
    o.dsn = Env.sentryDsn;
    o.environment = Env.isProd ? 'production' : 'development';

    // ── Tracing ──────────────────────────────────────────────────────────────
    o.tracesSampleRate = Env.sentryTracesSampleRate;
    o.tracePropagationTargets
      ..clear()
      ..add(Uri.parse(Env.apiUrl).host);

    // ── Erros HTTP (5xx capturados como issues no Sentry) ────────────────────
    o.captureFailedRequests = true;
    o.maxRequestBodySize = MaxRequestBodySize.small;

    // ── Session Replay: só grava 30s antes de um crash (sem custo contínuo) ──
    // sessionSampleRate = 0 → não grava sessão inteira.
    // onErrorSampleRate = 1.0 → sempre grava quando houver erro.
    // Não disponível em Web — ignorado automaticamente pelo SDK.
    if (!kIsWeb) {
      o.replay.sessionSampleRate = 0.0;
      o.replay.onErrorSampleRate = 1.0;
    }

    // ── Logs estruturados ─────────────────────────────────────────────────────
    // Habilitados por padrão no SDK v10. beforeSendLog filtra níveis de dev.
    if (Env.isProd) {
      o.beforeSendLog = (log, hint) {
        // Descartar debug/trace em produção para não inflar cota de logs.
        if (log.level == SentryLogLevel.debug ||
            log.level == SentryLogLevel.trace) {
          return null;
        }
        return log;
      };
    }

    // ── Preservar comportamento de crashes: Crashlytics continua como handler ─
    // enableNativeCrashHandling = false evita duplicata com Crashlytics.
    o.enableNativeCrashHandling = false;

    o.beforeSendTransaction = (tx, hint) => stripRouteArguments(tx);
  });
}

/// Args do go_router trazem query string (ex.: busca por nome de aluno).
/// Remove dados sensíveis antes de enviar a transação ao Sentry.
@visibleForTesting
SentryTransaction stripRouteArguments(SentryTransaction tx) {
  final trace = tx.contexts.trace;
  final data = trace?.data;
  if (trace != null && data != null && data.containsKey(_kRouteArgs)) {
    tx.contexts.trace = SentryTraceContext.fromJson(
      trace.toJson()..['data'] = (Map.of(data)..remove(_kRouteArgs)),
    );
  }
  return tx;
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
