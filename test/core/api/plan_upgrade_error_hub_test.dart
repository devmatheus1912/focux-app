import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/plan_upgrade_error_hub.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/features/subscription/widgets/upgrade_prompt_sheet.dart';
import 'package:focux_app/l10n/app_localizations.dart';

DioException _erro(
  String codigo, {
  String method = 'POST',
  Map<String, dynamic> extra = const {},
}) {
  final options = RequestOptions(path: '/api/x', method: method, extra: extra);
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: 403,
      data: {
        'erro': 'Recurso indisponível no seu plano.',
        'codigo': codigo,
        'upgradePlano': 'PRO',
      },
    ),
  );
}

Future<BuildContext> _pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  late BuildContext ctx;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox.expand();
          },
        ),
      ),
    ),
  );
  return ctx;
}

void main() {
  setUp(PlanUpgradeErrorHub.resetForTest);
  tearDown(PlanUpgradeErrorHub.resetForTest);

  group('interceptor', () {
    late List<Object> apresentados;

    setUp(() {
      apresentados = [];
      PlanUpgradeErrorHub.presenter = (context, error) async {
        apresentados.add(error);
        return true;
      };
    });

    test('mutação com erro de plano abre a sheet', () async {
      PlanUpgradeErrorHub.onDioError(_erro('PLANO_LIMITE_ALUNOS_ATINGIDO'));
      PlanUpgradeErrorHub.onDioError(_erro('PLANO_FEATURE_REQUER_UPGRADE'));
      await Future<void>.delayed(Duration.zero);
      expect(apresentados, hasLength(2));
    });

    test('GET de fundo, opt-out e outros códigos não abrem', () async {
      PlanUpgradeErrorHub.onDioError(
        _erro('PLANO_FEATURE_REQUER_UPGRADE', method: 'GET'),
      );
      PlanUpgradeErrorHub.onDioError(
        _erro(
          'PLANO_FEATURE_REQUER_UPGRADE',
          extra: {PlanUpgradeErrorHub.skipExtra: true},
        ),
      );
      PlanUpgradeErrorHub.onDioError(_erro('VALIDACAO'));
      await Future<void>.delayed(Duration.zero);
      expect(apresentados, isEmpty);
    });
  });

  test('com uma sheet aberta, o segundo erro não abre outra', () async {
    var chamadas = 0;
    PlanUpgradeErrorHub.presenter = (context, error) async {
      chamadas++;
      return true;
    };
    final aberta = Completer<void>();
    final primeira = PlanUpgradeErrorHub.run(() => aberta.future);
    expect(PlanUpgradeErrorHub.isShowing, isTrue);

    expect(
      await PlanUpgradeErrorHub.present(_erro('PLANO_LIMITE_ALUNOS_ATINGIDO')),
      isTrue,
    );
    expect(chamadas, 0);

    aberta.complete();
    await primeira;
    expect(PlanUpgradeErrorHub.isShowing, isFalse);
  });

  testWidgets('limite de alunos abre a sheet com a copy do limite', (
    tester,
  ) async {
    final ctx = await _pumpApp(tester);

    unawaited(
      UpgradePromptSheet.showFromError(
        ctx,
        _erro('PLANO_LIMITE_ALUNOS_ATINGIDO'),
      ),
    );
    unawaited(
      UpgradePromptSheet.showFromError(
        ctx,
        _erro('PLANO_LIMITE_ALUNOS_ATINGIDO'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Você chegou ao limite de alunos do plano'),
      findsOneWidget,
    );
    expect(find.text('Desbloqueie no Pro'), findsOneWidget);
  });

  testWidgets('showApiFailure troca o toast pela sheet', (tester) async {
    final ctx = await _pumpApp(tester);
    UpgradePromptSheet.registerGlobalPresenter(
      isPersonal: () => true,
      rootContext: () => ctx,
    );

    FeedbackHelper.showApiFailure(ctx, _erro('PLANO_FEATURE_REQUER_UPGRADE'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.textContaining('Desbloqueie no'), findsOneWidget);
  });

  testWidgets('aluno recebe o toast, nunca a sheet', (tester) async {
    final ctx = await _pumpApp(tester);
    UpgradePromptSheet.registerGlobalPresenter(
      isPersonal: () => false,
      rootContext: () => ctx,
    );

    FeedbackHelper.showApiFailure(ctx, _erro('PLANO_FEATURE_REQUER_UPGRADE'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Desbloqueie'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
