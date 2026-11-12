import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/data/ia_chat_store.dart';
import 'package:focux_app/features/ia/utils/ia_texto_formatado.dart';

void main() {
  test('limpa <br>, tabela e emojis numerados', () {
    const bruto = '**Passos:**\n\n| O que observar | Como agir |\n|---|---|\n'
        '| **Tipo de dor** | Pergunte ao aluno. |\n'
        'Aquecimento: <br>1️⃣ cardio <br>2️⃣ mobilidade';
    final t = iaTextoLimpo(bruto);
    expect(t, isNot(contains('<br>')));
    expect(t, isNot(contains('|---')));
    expect(t, contains('- O que observar: Como agir'));
    expect(t, contains('- **Tipo de dor**: Pergunte ao aluno.'));
    expect(t, contains('1. cardio'));
  });

  test('negrito vira peso e asterisco sem par some', () {
    const n = TextStyle(fontWeight: FontWeight.w400);
    const b = TextStyle(fontWeight: FontWeight.w600);
    final spans = iaSpans('Reduza a **carga** agora', n, b);
    expect(spans.map((s) => s.text), ['Reduza a ', 'carga', ' agora']);
    expect(spans[1].style, b);
    expect(iaSpans('fim **sem par', n, b).single.text, 'fim sem par');
  });

  test('histórico para envio: as últimas 12 mensagens', () {
    final msgs = [
      for (var i = 0; i < 20; i++)
        IaChatMsg(autor: i.isEven ? 'PERSONAL' : 'IA', texto: 'm$i'),
    ];
    final h = iaHistoricoParaEnvio(msgs);
    expect(h, hasLength(12));
    expect(h.first['texto'], 'm8');
    expect(h.last['autor'], 'IA');
  });

  test('título da conversa é a primeira pergunta', () {
    final c = IaConversa(
      id: '1',
      atualizadaEm: DateTime(2026, 11, 12),
      mensagens: const [
        IaChatMsg(autor: 'PERSONAL', texto: 'Aluno com dor no peito'),
        IaChatMsg(autor: 'IA', texto: 'Pare o exercício.'),
      ],
    );
    expect(c.titulo, 'Aluno com dor no peito');
    expect(IaConversa.fromJson(c.toJson()).mensagens, hasLength(2));
  });
}
