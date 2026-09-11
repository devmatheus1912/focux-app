import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo =
      File('lib/features/chat/data/chat_repository.dart').readAsStringSync();

  test('historico de chat so e lido pelos endpoints paginados', () {
    // O backend esta liberado para apagar as listas cruas; voltar a chamar
    // qualquer uma delas quebra o chat quando isso acontecer.
    expect(repo, isNot(contains("'/api/chat/historico/\$alunoId'")));
    expect(repo, isNot(contains("'/api/chat/aluno/historico'")));

    expect(repo, contains("'/api/chat/historico/\$alunoId/page'"));
    expect(repo, contains("'/api/chat/aluno/historico/page'"));
  });

  test('nenhuma tela do app chama o historico cru', () {
    final ofensores = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();
      if (src.contains('.historicoAluno()') || src.contains('.historico(')) {
        // `historico()` de check-in e outro endpoint, sem relacao com chat.
        if (entity.path.contains('checkin')) continue;
        ofensores.add(entity.path);
      }
    }
    expect(ofensores, isEmpty);
  });

  test('conversa aluno usa historico paginado', () {
    final tela =
        File('lib/features/chat/screens/conversation_screen.dart')
            .readAsStringSync();
    expect(tela, contains('historicoAlunoPage'));
    expect(tela, isNot(contains('.historicoAluno()')));
  });
}
