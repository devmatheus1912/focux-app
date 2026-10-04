import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import 'api_error.dart';

/// Abre a sheet de upgrade para erro de plano. `context` nulo = navigator raiz.
typedef PlanUpgradePresenter =
    Future<bool> Function(BuildContext? context, Object error);

/// Ponto único para erros de plano que merecem sheet de upgrade em vez de
/// toast: interceptor do [ApiClient], `FeedbackHelper.showApiFailure` e
/// `UpgradePromptSheet.showFromError` passam por aqui, e só uma sheet abre.
abstract final class PlanUpgradeErrorHub {
  static const upgradeCodes = ApiErrorCodes.upgradeSheet;

  static const limiteAlunos = 'PLANO_LIMITE_ALUNOS_ATINGIDO';

  /// Registrado no boot do app (precisa de navigator + sheet da feature).
  static PlanUpgradePresenter? presenter;

  /// Requisição que já trata o erro de plano na própria tela.
  static const skipExtra = 'fxSkipPlanUpgradeSheet';

  static bool _showing = false;

  static bool get isShowing => _showing;

  static bool isUpgradeError(Object error) {
    final codigo = ApiError.from(error)?.codigo;
    return codigo != null && upgradeCodes.contains(codigo);
  }

  /// Executa [show] se nenhuma sheet de upgrade estiver aberta. Retorna `true`
  /// quando o erro ficou com o usuário (nesta chamada ou numa anterior).
  static Future<bool> run(Future<void> Function() show) async {
    if (_showing) return true;
    _showing = true;
    try {
      await show();
    } finally {
      _showing = false;
    }
    return true;
  }

  static Future<bool> present(Object error, {BuildContext? context}) {
    final p = presenter;
    if (p == null || !isUpgradeError(error)) return Future.value(false);
    if (_showing) return Future.value(true);
    return p(context, error);
  }

  /// Interceptor: mutações (não-GET) com erro de plano abrem a sheet já.
  /// GET de fundo não abre paywall sozinho — a tela decide.
  static void onDioError(DioException e) {
    final options = e.requestOptions;
    if (options.method.toUpperCase() == 'GET') return;
    if (options.extra[skipExtra] == true) return;
    if (!isUpgradeError(e)) return;
    unawaited(present(e));
  }

  @visibleForTesting
  static void resetForTest() {
    presenter = null;
    _showing = false;
  }
}
