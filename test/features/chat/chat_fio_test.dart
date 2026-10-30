import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';
import 'package:focux_app/features/chat/utils/chat_fio.dart';

ChatMsg _msg(String texto, DateTime em, {String remetente = 'SISTEMA'}) => ChatMsg.fromJson({
  'remetente': remetente,
  'conteudo': texto,
  'enviadoEm': em.toIso8601String(),
  'tipoMidia': remetente == 'SISTEMA' ? 'TREINO_RESUMO' : 'TEXTO',
});

const _treino = 'Treino registrado: Treino A. 8/8 séries.';
const _vazio = 'Treino registrado: Treino B. Sem séries registradas.';
const _evolucao = 'Boa, Julio! Você evoluiu neste treino.\n\n- Carga em Supino: 40 kg -> 45 kg';

void main() {
  final dia = DateTime(2026, 10, 28, 9);

  test('treinos seguidos no mesmo dia viram um item', () {
    final fio = montarFioDoChat([
      _msg(_treino, dia),
      _msg(_treino, dia.add(const Duration(minutes: 1))),
    ], alunoMode: false);
    expect(fio.length, 1);
    expect(fio.single.msgs.length, 2);
  });

  test('mensagem humana no meio e dia diferente separam', () {
    final fio = montarFioDoChat([
      _msg(_treino, dia),
      _msg('Oi', dia.add(const Duration(minutes: 1)), remetente: 'PERSONAL'),
      _msg(_treino, dia.add(const Duration(minutes: 2))),
      _msg(_treino, dia.add(const Duration(days: 1))),
    ], alunoMode: false);
    expect(fio.length, 4);
  });

  test('sessão vazia nunca aparece e não separa o grupo', () {
    final fio = montarFioDoChat([
      _msg(_treino, dia),
      _msg(_vazio, dia.add(const Duration(minutes: 1))),
      _msg(_treino, dia.add(const Duration(minutes: 2))),
    ], alunoMode: false);
    expect(fio.single.msgs.length, 2);
  });

  test('aluno não vê treino, mas vê evolução e conversa', () {
    final fio = montarFioDoChat([
      _msg(_treino, dia),
      _msg(_evolucao, dia.add(const Duration(minutes: 1))),
      _msg('Oi', dia.add(const Duration(minutes: 2)), remetente: 'PERSONAL'),
    ], alunoMode: true);
    expect(fio.length, 2);
  });
}
