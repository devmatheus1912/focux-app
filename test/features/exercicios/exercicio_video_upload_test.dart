import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? pedido;
  int bytesLidos = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    pedido = options;
    // Consumir o corpo é o que faz o Dio chamar o onSendProgress.
    if (requestStream != null) {
      await for (final parte in requestStream) {
        bytesLidos += parte.length;
      }
    }
    return ResponseBody.fromString(
      jsonEncode({'id': 9, 'nome': 'Supino'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory pasta;
  setUp(() => pasta = Directory.systemTemp.createTempSync('fx_video_'));
  tearDown(() => pasta.deleteSync(recursive: true));

  test(
    'upload do vídeo manda tipo e nome, informa o progresso e espera a conversão',
    () async {
      final arquivo = File('${pasta.path}/supino.mov')
        ..writeAsBytesSync(List.filled(256 * 1024, 7));
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter;
      final repo = ExercicioRepository(_FakeApiClient(dio));
      final progresso = <double>[];

      final ex = await repo.uploadVideoExercicio(
        9,
        arquivo.path,
        onProgresso: progresso.add,
      );

      expect(ex.id, 9);
      final pedido = adapter.pedido!;
      expect(pedido.path, '/api/exercicios/9/video');
      expect(pedido.receiveTimeout, ExercicioRepository.videoRespostaTimeout);
      final form = pedido.data as FormData;
      final file = form.files.single.value;
      expect(file.filename, 'supino.mov');
      expect(file.contentType.toString(), 'video/quicktime');
      expect(adapter.bytesLidos, greaterThan(256 * 1024));
      expect(progresso, isNotEmpty);
      expect(progresso.last, 1.0);
      for (var i = 1; i < progresso.length; i++) {
        expect(progresso[i], greaterThanOrEqualTo(progresso[i - 1]));
      }
    },
  );

  test('cancelar o envio interrompe o pedido', () async {
    final arquivo = File('${pasta.path}/supino.mp4')
      ..writeAsBytesSync(List.filled(1024, 1));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = _Adapter();
    final repo = ExercicioRepository(_FakeApiClient(dio));
    final cancel = CancelToken()..cancel();

    await expectLater(
      repo.uploadVideoExercicio(9, arquivo.path, cancelToken: cancel),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
  });
}
