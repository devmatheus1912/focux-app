import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';
import 'package:focux_app/features/feedback/data/feedback_video_repository.dart';
import 'package:focux_app/features/feedback/screens/aluno_feedback_video_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class _FakeRepo implements FeedbackVideoRepository {
  _FakeRepo(this.items);

  final List<FeedbackVideo> items;
  String? subiuArquivo;
  Map<String, Object?>? enviado;

  @override
  Future<Pagina<FeedbackVideo>> listarMeus({int page = 0, int size = 20}) async =>
      Pagina(
        content: items,
        page: 0,
        size: size,
        totalElements: items.length,
        hasNext: false,
      );

  @override
  Future<List<ExercicioOpcao>> meusExercicios() async => [
    ExercicioOpcao(id: 7, nome: 'Agachamento'),
  ];

  @override
  Future<String> subirVideo({
    required String filename,
    String? path,
    List<int>? bytes,
  }) async {
    subiuArquivo = filename;
    return 'https://cdn.example.com/v.mp4';
  }

  @override
  Future<FeedbackVideo> enviarMeu({
    required int exercicioId,
    required String videoUrl,
    String comentario = '',
  }) async {
    enviado = {
      'exercicioId': exercicioId,
      'videoUrl': videoUrl,
      'comentario': comentario,
    };
    return FeedbackVideo(
      id: 99,
      alunoId: 1,
      exercicioId: exercicioId,
      exercicioNome: 'Agachamento',
      videoUrl: videoUrl,
      comentario: comentario,
      criadoEm: DateTime(2026, 10, 1),
      status: 'ENVIADO',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePicker extends ImagePicker {
  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
  }) async => XFile.fromData(
    Uint8List.fromList(List.filled(1024, 1)),
    name: 'serie.mov',
    length: 1024,
  );
}

FeedbackVideo _respondido() => FeedbackVideo(
  id: 1,
  alunoId: 1,
  exercicioId: 7,
  exercicioNome: 'Supino',
  videoUrl: 'https://cdn.example.com/a.mp4',
  comentario: 'Senti o ombro',
  criadoEm: DateTime(2026, 9, 30),
  respostaPersonal: 'Desça a barra mais devagar.',
  respondidoEm: DateTime(2026, 9, 30, 18),
  status: 'RESPONDIDO',
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<_FakeRepo> pump(WidgetTester tester, List<FeedbackVideo> items) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final repo = _FakeRepo(items);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [feedbackVideoRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(home: AlunoFeedbackVideoScreen(picker: _FakePicker())),
      ),
    );
    await _settle(tester);
    return repo;
  }

  testWidgets('sem vídeos mostra o convite para gravar', (tester) async {
    await pump(tester, []);
    expect(find.byKey(const ValueKey('aluno-feedback-vazio')), findsOneWidget);
    expect(find.text('Nenhum vídeo ainda'), findsOneWidget);
  });

  testWidgets('toque no vídeo respondido abre a correção', (tester) async {
    await pump(tester, [_respondido()]);
    expect(find.text('Supino'), findsOneWidget);
    expect(find.text('Respondido'), findsOneWidget);

    await tester.tap(find.text('Supino'));
    await _settle(tester);

    expect(find.text('Desça a barra mais devagar.'), findsOneWidget);
    expect(find.text('Senti o ombro'), findsOneWidget);
    expect(find.text('Assistir meu vídeo'), findsOneWidget);
  });

  testWidgets('enviar: exercício, galeria, recado e entra na lista', (
    tester,
  ) async {
    final repo = await pump(tester, []);

    await tester.tap(find.byKey(const ValueKey('aluno-feedback-enviar')));
    await _settle(tester);
    await tester.tap(find.text('Agachamento'));
    await _settle(tester);
    await tester.tap(find.text('Escolher da galeria'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Joelho na descida');
    await tester.tap(find.text('Enviar vídeo').last);
    await _settle(tester);

    expect(repo.subiuArquivo, startsWith('feedback_'));
    expect(repo.enviado, {
      'exercicioId': 7,
      'videoUrl': 'https://cdn.example.com/v.mp4',
      'comentario': 'Joelho na descida',
    });
    expect(find.text('Agachamento'), findsOneWidget);
    expect(find.text('Enviado'), findsOneWidget);
  });
}
