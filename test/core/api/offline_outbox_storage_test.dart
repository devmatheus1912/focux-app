import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_outbox_storage.dart';
import 'package:focux_app/core/api/offline_sync_service.dart';

/// Cofre falso: guarda só em memória, como o Keychain/Keystore guardaria fora do SharedPreferences.
class _CofreFalso implements OfflineOutboxStorage {
  final dados = <String, String>{};

  @override
  Future<String?> read(String key) async => dados[key];

  @override
  Future<void> write(String key, String value) async => dados[key] = value;

  @override
  Future<void> remove(String key) async => dados.remove(key);
}

void main() {
  late _CofreFalso cofre;
  late OfflineOutboxStorage original;

  setUp(() {
    original = OfflineSyncService.storage;
    cofre = _CofreFalso();
    OfflineSyncService.storage = cofre;
  });

  tearDown(() => OfflineSyncService.storage = original);

  test('a fila vai para o cofre e não para o SharedPreferences', () async {
    final ok = await OfflineSyncService.enqueueRequest(
      RequestOptions(
        path: '/api/agenda',
        method: 'POST',
        data: {'titulo': 'Aula'},
      ),
    );
    expect(ok, isTrue);
    expect(cofre.dados.keys, contains('offline_outbox_queue'));
    final fila = jsonDecode(cofre.dados['offline_outbox_queue']!) as List;
    expect(fila, hasLength(1));
    expect(await OfflineSyncService.getPendingCount(), 1);
  });

  test('limpar a fila (logout) esvazia o cofre', () async {
    await OfflineSyncService.enqueueRequest(
      RequestOptions(
        path: '/api/agenda',
        method: 'POST',
        data: {'titulo': 'Aula'},
      ),
    );
    await OfflineSyncService.clearQueue();
    expect(cofre.dados, isEmpty);
    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('o armazenamento padrão do teste não usa cofre nativo', () {
    expect(OfflineOutboxStorage.padrao(), isA<PrefsOutboxStorage>());
  });
}
