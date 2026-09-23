import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/utils/chat_remetente.dart';

void main() {
  test('SISTEMA e TREINO_RESUMO não viram Personal nem Aluno', () {
    expect(chatIsSistema('SISTEMA'), isTrue);
    expect(chatIsSistema('PERSONAL', 'TREINO_RESUMO'), isTrue);
    expect(chatIsSistema('PERSONAL'), isFalse);
    expect(
      chatRemetenteLabel(remetente: 'SISTEMA', isAlunoMode: true),
      'Sistema',
    );
    expect(
      chatRemetenteLabel(remetente: 'PERSONAL', isAlunoMode: true),
      'Personal',
    );
    expect(
      chatRemetenteLabel(remetente: 'ALUNO', isAlunoMode: false),
      'Aluno',
    );
    expect(
      chatInboxPreview(remetente: 'SISTEMA', mensagem: 'Treino concluído'),
      'Treino concluído',
    );
    expect(
      chatInboxPreview(
        remetente: 'SISTEMA',
        mensagem:
            'Treino registrado: Costa e Braceta. 1/28 series. '
            'Responda no chat se quiser ajustar a próxima sessão.',
      ),
      'Treino registrado · Costa e Braceta · 1 de 28 séries',
    );
    expect(
      chatInboxPreview(remetente: 'PERSONAL', mensagem: 'Bora'),
      'Você: Bora',
    );
    expect(
      chatInboxPreview(remetente: 'ALUNO', mensagem: 'Ok'),
      'Ok',
    );
  });
}
