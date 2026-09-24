import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';
import 'package:focux_app/features/chat/utils/chat_bubble_grouping.dart';

ChatMsg _msg({
  required int id,
  required String remetente,
  required DateTime enviadoEm,
}) {
  return ChatMsg(
    id: id,
    alunoId: 1,
    remetente: remetente,
    conteudo: 'oi',
    enviadoEm: enviadoEm,
    tipoMidia: null,
    reactions: const [],
  );
}

void main() {
  test('agrupa mensagens consecutivas do mesmo remetente', () {
    final t0 = DateTime(2026, 1, 1, 10, 0);
    final t1 = t0.add(const Duration(minutes: 1));
    final t2 = t0.add(const Duration(minutes: 2));
    final a = _msg(id: 1, remetente: 'PERSONAL', enviadoEm: t0);
    final b = _msg(id: 2, remetente: 'PERSONAL', enviadoEm: t1);
    final c = _msg(id: 3, remetente: 'PERSONAL', enviadoEm: t2);

    bool isMine(ChatMsg m) => m.remetente == 'PERSONAL';
    bool isSystem(ChatMsg m) => false;

    expect(
      resolveChatBubbleGroupSlot(
        msg: a,
        older: null,
        newer: b,
        isMine: isMine,
        isSystem: isSystem,
      ),
      ChatBubbleGroupSlot.first,
    );
    expect(
      resolveChatBubbleGroupSlot(
        msg: b,
        older: a,
        newer: c,
        isMine: isMine,
        isSystem: isSystem,
      ),
      ChatBubbleGroupSlot.middle,
    );
    expect(
      resolveChatBubbleGroupSlot(
        msg: c,
        older: b,
        newer: null,
        isMine: isMine,
        isSystem: isSystem,
      ),
      ChatBubbleGroupSlot.last,
    );
    expect(chatBubbleShowsTimestampMeta(ChatBubbleGroupSlot.last), isTrue);
    expect(chatBubbleShowsTimestampMeta(ChatBubbleGroupSlot.middle), isFalse);
  });
}
