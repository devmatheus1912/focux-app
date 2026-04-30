import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_media_import_parser.dart';

void main() {
  test('parseExerciseMediaCsv accepts quoted commas and escaped quotes', () {
    final rows = parseExerciseMediaCsv(
      'importKey,videoUrl,thumbnailUrl,videoSource,licenseStatus\n'
      '"supino, reto","https://cdn.exemplo/video,1.mp4",'
      '"https://cdn.exemplo/thumb ""premium"".jpg",FOCUX_LIBRARY,LICENSED',
    );

    expect(rows, hasLength(1));
    expect(rows.first['importKey'], 'supino, reto');
    expect(rows.first['videoUrl'], 'https://cdn.exemplo/video,1.mp4');
    expect(
      rows.first['thumbnailUrl'],
      'https://cdn.exemplo/thumb "premium".jpg',
    );
    expect(rows.first['videoSource'], 'FOCUX_LIBRARY');
  });

  test('parseExerciseMediaCsv accepts semicolon separated spreadsheets', () {
    final rows = parseExerciseMediaCsv(
      'importKey;videoUrl;thumbnailUrl;videoSource;licenseStatus\n'
      'agachamento;https://cdn.exemplo/ag.mp4;;FOCUX_LIBRARY;LICENSED',
    );

    expect(rows.single['importKey'], 'agachamento');
    expect(rows.single['videoUrl'], 'https://cdn.exemplo/ag.mp4');
    expect(rows.single.containsKey('thumbnailUrl'), isFalse);
  });

  test('parseExerciseMediaImportPayload accepts json wrapper', () {
    final rows = parseExerciseMediaImportPayload(
      '{"midias":[{"importKey":"remada","videoUrl":"https://cdn/remada.mp4"}]}',
    );

    expect(rows.single['importKey'], 'remada');
    expect(rows.single['videoUrl'], 'https://cdn/remada.mp4');
  });

  test('parseExerciseMediaCsv converts editorial approval values', () {
    final rows = parseExerciseMediaCsv(
      'importKey,videoUrl,thumbnailUrl,videoSource,licenseStatus,aprovarEditorial,editorialNotes\n'
      'supino,https://cdn/supino.mp4,https://cdn/supino.jpg,FOCUX_LIBRARY,LICENSED,true,Revisado',
    );

    expect(rows.single['aprovarEditorial'], isTrue);
    expect(rows.single['editorialNotes'], 'Revisado');
  });

  test('exerciseMediaImportTemplate includes editorial approval columns', () {
    expect(exerciseMediaImportTemplate, contains('aprovarEditorial'));
    expect(exerciseMediaImportTemplate, contains('editorialNotes'));
  });
}
