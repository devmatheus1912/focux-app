import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/api/offline_queued_ack.dart';
import 'package:focux_app/core/api/offline_sync_service.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

const _pendente = 'Sem conexão. Vamos enviar quando a rede voltar.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('excluir sem rede entra na fila e não conta como sucesso', () async {
    final client = ApiClient();
    client.dio.httpClientAdapter = _OfflineAdapter();

    await expectLater(
      AgendaRepository(client).excluir(7),
      throwsA(isA<OfflineQueuedException>()),
    );
    expect(await OfflineSyncService.getPendingCount(), 1);
  });

  testWidgets('exclusão enfileirada mostra o pendente, não o sucesso', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder:
                (context) => TextButton(
                  onPressed:
                      () => FeedbackHelper.showApiFailure(
                        context,
                        const OfflineQueuedException(),
                      ),
                  child: const Text('excluir'),
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('excluir'));
    await tester.pump();

    expect(find.text(_pendente), findsOneWidget);
    expect(find.text('Agendamento excluído.'), findsNothing);
  });
}
