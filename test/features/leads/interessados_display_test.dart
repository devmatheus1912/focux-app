import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/leads/data/lead_repository.dart';
import 'package:focux_app/features/leads/utils/interessados_display.dart';

Lead _l(
  int id,
  String status, {
  String criadoEm = '2026-11-01',
  String? proximo,
  String? origem,
  String? objetivo,
}) => Lead(
  id: id,
  nome: 'P$id',
  status: status,
  criadoEm: criadoEm,
  proximoContato: proximo,
  origem: origem,
  objetivo: objetivo,
);

void main() {
  final hoje = DateTime(2026, 11, 11);

  test('etapas com o texto novo', () {
    expect(interessadoEtapaLabel('LEAD'), 'Para responder');
    expect(interessadoEtapaLabel('TESTE'), 'Em conversa');
    expect(interessadoEtapaLabel('ATIVO'), 'Virou aluno');
    expect(interessadoEtapaLabel('CANCELADO'), 'Sem interesse');
    expect(interessadoOrigemLabel('Página pública'), 'Pela sua página');
  });

  test('grupos e ordem', () {
    final g = interessadosAgrupar([
      _l(1, 'LEAD', criadoEm: '2026-11-09'),
      _l(2, 'LEAD', criadoEm: '2026-11-02'),
      _l(3, 'TESTE', criadoEm: '2026-11-08'),
      _l(4, 'TESTE', criadoEm: '2026-11-01', proximo: '2026-11-10'),
      _l(5, 'CONVERTIDO'),
      _l(6, 'CANCELADO'),
    ], hoje: hoje);
    // Quem espera há mais tempo primeiro.
    expect(g.paraResponder.map((l) => l.id), [2, 1]);
    // Retorno atrasado na frente.
    expect(g.emConversa.map((l) => l.id), [4, 3]);
    expect(g.viraramAlunos.map((l) => l.id), [5]);
    expect(g.semInteresse.map((l) => l.id), [6]);
  });

  test('tempo e retorno na linha', () {
    expect(
      interessadoTempo(_l(1, 'TESTE', proximo: '2026-11-11'), hoje: hoje).texto,
      'Retornar hoje',
    );
    final atrasado = interessadoTempo(
      _l(1, 'TESTE', proximo: '2026-11-08'),
      hoje: hoje,
    );
    expect(atrasado.texto, 'Retornar desde 08/11');
    expect(atrasado.alerta, isTrue);
    expect(
      interessadoTempo(_l(1, 'LEAD', criadoEm: '2026-11-09'), hoje: hoje).texto,
      'há 2 dias',
    );
    expect(
      interessadoLinha(
        _l(1, 'LEAD', origem: 'Instagram', objetivo: 'hipertrofia'),
      ),
      'Instagram · hipertrofia',
    );
  });

  test('subtítulo, página em 30 dias e busca', () {
    expect(interessadosSubtitulo(2), '2 para responder');
    expect(interessadosSubtitulo(0), 'Ninguém esperando resposta');
    final leads = [
      _l(1, 'LEAD', origem: 'Página pública', criadoEm: '2026-11-01'),
      _l(2, 'LEAD', origem: 'Página pública', criadoEm: '2026-09-01'),
      _l(3, 'LEAD', origem: 'Instagram', criadoEm: '2026-11-05'),
    ];
    expect(interessadosDaPagina30Dias(leads, hoje: hoje), 1);
    expect(
      interessadosPaginaCartao(4),
      '4 pessoas chegaram pela página nos últimos 30 dias',
    );
    expect(interessadosMostraBusca(total: 6, query: ''), isFalse);
    expect(interessadosMostraBusca(total: 7, query: ''), isTrue);
  });

  test('"Conversou?" só depois de WhatsApp ou Ligar; e o funil anda', () {
    expect(interessadoPerguntarConversa(saiuPor: 'WHATSAPP'), isTrue);
    expect(interessadoPerguntarConversa(saiuPor: 'LIGACAO'), isTrue);
    expect(interessadoPerguntarConversa(saiuPor: null), isFalse);
    expect(interessadoEtapaDepoisDoContato('LEAD'), 'TESTE');
    expect(interessadoEtapaDepoisDoContato('TESTE'), isNull);
  });

  test('histórico junta contatos, página e e-mails, mais novo em cima', () {
    final lead = Lead(
      id: 1,
      nome: 'Thales',
      status: 'TESTE',
      criadoEm: '2026-11-01',
      origem: 'Página pública',
      emailsAutomaticos: [
        LeadEmailAutomatico(etapa: 'D1', enviadoEm: DateTime(2026, 11, 2, 9)),
      ],
    );
    final h = interessadoHistorico(lead, [
      LeadInteracao(
        id: 1,
        leadId: 1,
        tipo: 'WHATSAPP',
        descricao: 'Quer 3x',
        dataInteracao: '2026-11-03T10:00:00',
      ),
    ]);
    expect(h.map((e) => e.titulo), [
      'WhatsApp',
      'E-mail automático enviado · 1 dia depois',
      'Chegou pela sua página',
    ]);
  });
}
