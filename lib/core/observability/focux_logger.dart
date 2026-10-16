/// Logger estruturado do Focux — envia logs para o Sentry com atributos.
///
/// Uso simples:
///   FocuxLogger.info('Checkin iniciado', attrs: {'treino_id': '123'});
///   FocuxLogger.error('Falha ao salvar', error: e, attrs: {'aluno_id': id});
///
/// Em debug: imprime no console. Em produção: envia ao Sentry Logs.
/// Níveis debug/trace são filtrados em produção (ver sentry_performance.dart).
library;

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/env.dart';

abstract final class FocuxLogger {
  // ── Níveis ────────────────────────────────────────────────────────────────

  static void trace(String message, {Map<String, String>? attrs}) =>
      _log(SentryLogLevel.trace, message, attrs: attrs);

  static void debug(String message, {Map<String, String>? attrs}) =>
      _log(SentryLogLevel.debug, message, attrs: attrs);

  static void info(String message, {Map<String, String>? attrs}) =>
      _log(SentryLogLevel.info, message, attrs: attrs);

  static void warn(String message, {Map<String, String>? attrs}) =>
      _log(SentryLogLevel.warn, message, attrs: attrs);

  static void error(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, String>? attrs,
  }) {
    _log(SentryLogLevel.error, message, attrs: attrs);
    if (error != null && Env.sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stack);
    }
  }

  static void fatal(
    String message, {
    Object? error,
    StackTrace? stack,
    Map<String, String>? attrs,
  }) {
    _log(SentryLogLevel.fatal, message, attrs: attrs);
    if (error != null && Env.sentryDsn.isNotEmpty) {
      Sentry.captureException(error, stackTrace: stack);
    }
  }

  // ── Interno ───────────────────────────────────────────────────────────────

  static void _log(
    SentryLogLevel level,
    String message, {
    Map<String, String>? attrs,
  }) {
    if (kDebugMode) {
      debugPrint('[Focux/${level.name.toUpperCase()}] $message'
          '${attrs != null ? ' | $attrs' : ''}');
    }
    if (Env.sentryDsn.isEmpty) return;
    final sentryAttrs = attrs?.map(
      (k, v) => MapEntry(k, SentryAttribute.string(v)),
    );
    switch (level) {
      case SentryLogLevel.trace:
        Sentry.logger.trace(message, attributes: sentryAttrs);
      case SentryLogLevel.debug:
        Sentry.logger.debug(message, attributes: sentryAttrs);
      case SentryLogLevel.info:
        Sentry.logger.info(message, attributes: sentryAttrs);
      case SentryLogLevel.warn:
        Sentry.logger.warn(message, attributes: sentryAttrs);
      case SentryLogLevel.error:
        Sentry.logger.error(message, attributes: sentryAttrs);
      case SentryLogLevel.fatal:
        Sentry.logger.fatal(message, attributes: sentryAttrs);
    }
  }
}
