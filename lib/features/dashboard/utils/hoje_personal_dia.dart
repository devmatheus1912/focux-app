/// Uma linha do dia na primeira tela do personal. Some quando o número é zero.
class HojePersonalLinha {
  const HojePersonalLinha({required this.texto, required this.rota});

  final String texto;
  final String rota;
}

/// O que está acontecendo agora. Dia quieto, com aluno na base, mostra a base.
List<HojePersonalLinha> hojePersonalDia({
  required int agendaHoje,
  required int alunosContato,
  required int mensalidades,
  required int conversas,
  required int alunosNaBase,
}) {
  final linhas = <HojePersonalLinha>[
    if (agendaHoje > 0)
      HojePersonalLinha(
        texto: agendaHoje == 1
            ? '1 compromisso hoje'
            : '$agendaHoje compromissos hoje',
        rota: '/agenda',
      ),
    if (alunosContato > 0)
      HojePersonalLinha(
        texto: alunosContato == 1
            ? '1 aluno para contato'
            : '$alunosContato alunos para contato',
        rota: '/alunos?filtro=contato',
      ),
    if (mensalidades > 0)
      HojePersonalLinha(
        texto: mensalidades == 1
            ? '1 mensalidade em aberto'
            : '$mensalidades mensalidades em aberto',
        rota: '/financeiro',
      ),
    if (conversas > 0)
      HojePersonalLinha(
        texto: conversas == 1
            ? '1 conversa sem resposta'
            : '$conversas conversas sem resposta',
        rota: '/chat/inbox',
      ),
  ];
  if (linhas.isEmpty && alunosNaBase > 0) {
    linhas.add(
      HojePersonalLinha(
        texto: alunosNaBase == 1
            ? '1 aluno na base'
            : '$alunosNaBase alunos na base',
        rota: '/alunos',
      ),
    );
  }
  return linhas;
}
