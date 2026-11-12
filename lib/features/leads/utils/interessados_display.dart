import '../data/lead_repository.dart';

/// Etapas de Interessados (só o texto muda; os status do backend ficam).
String interessadoEtapaLabel(String? status) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'TESTE':
      return 'Em conversa';
    case 'CONVERTIDO':
    case 'ATIVO':
      return 'Virou aluno';
    case 'CANCELADO':
      return 'Sem interesse';
    default:
      return 'Para responder';
  }
}

/// Etapas que o personal escolhe à mão ("Virou aluno" vem do cadastro).
const interessadoEtapasManuais = ['LEAD', 'TESTE', 'CANCELADO'];

bool interessadoVirouAluno(String status) {
  final s = status.trim().toUpperCase();
  return s == 'CONVERTIDO' || s == 'ATIVO';
}

bool interessadoDaPagina(String? origem) =>
    (origem ?? '').trim().toLowerCase() == 'página pública';

/// "Pagina pública" aparece como "Pela sua página".
String interessadoOrigemLabel(String? origem) {
  final v = origem?.trim() ?? '';
  if (v.isEmpty) return '';
  return interessadoDaPagina(v) ? 'Pela sua página' : v;
}

/// Embaixo do nome: "Instagram · hipertrofia".
String interessadoLinha(Lead lead) => [
  interessadoOrigemLabel(lead.origem),
  if ((lead.objetivo ?? '').trim().isNotEmpty) lead.objetivo!.trim(),
].where((p) => p.isNotEmpty).join(' · ');

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime? _data(String? iso) =>
    iso == null || iso.isEmpty ? null : DateTime.tryParse(iso);

/// Próximo contato hoje ou atrasado (só para quem ainda está no funil).
bool interessadoRetornoPendente(Lead lead, {DateTime? hoje}) {
  if (interessadoVirouAluno(lead.status) ||
      lead.status.toUpperCase() == 'CANCELADO') {
    return false;
  }
  final p = _data(lead.proximoContato);
  if (p == null) return false;
  return !_dia(p).isAfter(_dia(hoje ?? DateTime.now()));
}

/// À direita na linha: "Retornar hoje", "Retornar desde 08/11" ou "há 2 dias".
({String texto, bool alerta}) interessadoTempo(Lead lead, {DateTime? hoje}) {
  final h = _dia(hoje ?? DateTime.now());
  final p = _data(lead.proximoContato);
  final noFunil =
      !interessadoVirouAluno(lead.status) &&
      lead.status.toUpperCase() != 'CANCELADO';
  if (noFunil && p != null) {
    final d = _dia(p);
    if (d == h) return (texto: 'Retornar hoje', alerta: true);
    if (d.isBefore(h)) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return (texto: 'Retornar desde $dd/$mm', alerta: true);
    }
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return (texto: 'Retornar em $dd/$mm', alerta: false);
  }
  final c = _data(lead.criadoEm);
  if (c == null) return (texto: '', alerta: false);
  final dias = h.difference(_dia(c)).inDays;
  if (dias <= 0) return (texto: 'hoje', alerta: false);
  if (dias == 1) return (texto: 'ontem', alerta: false);
  return (texto: 'há $dias dias', alerta: false);
}

/// Grupos da lista, cada um já na ordem certa.
({
  List<Lead> paraResponder,
  List<Lead> emConversa,
  List<Lead> viraramAlunos,
  List<Lead> semInteresse,
})
interessadosAgrupar(List<Lead> leads, {DateTime? hoje}) {
  int porCriacao(Lead a, Lead b) => a.criadoEm.compareTo(b.criadoEm);
  final para =
      leads
          .where((l) => interessadoEtapaLabel(l.status) == 'Para responder')
          .toList()
        ..sort(porCriacao); // quem espera há mais tempo primeiro
  final conversa =
      leads.where((l) => l.status.toUpperCase() == 'TESTE').toList()
        ..sort((a, b) {
          final pa = interessadoRetornoPendente(a, hoje: hoje);
          final pb = interessadoRetornoPendente(b, hoje: hoje);
          if (pa != pb) return pa ? -1 : 1;
          if (pa && pb) {
            return (a.proximoContato ?? '').compareTo(b.proximoContato ?? '');
          }
          return b.criadoEm.compareTo(a.criadoEm);
        });
  final viraram =
      leads.where((l) => interessadoVirouAluno(l.status)).toList()
        ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  final sem =
      leads.where((l) => l.status.toUpperCase() == 'CANCELADO').toList()
        ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
  return (
    paraResponder: para,
    emConversa: conversa,
    viraramAlunos: viraram,
    semInteresse: sem,
  );
}

/// Subtítulo: "2 para responder" ou "Ninguém esperando resposta".
String interessadosSubtitulo(int paraResponder) {
  if (paraResponder <= 0) return 'Ninguém esperando resposta';
  return '$paraResponder para responder';
}

/// Quantos chegaram pela página nos últimos 30 dias.
int interessadosDaPagina30Dias(List<Lead> leads, {DateTime? hoje}) {
  final limite = _dia(
    hoje ?? DateTime.now(),
  ).subtract(const Duration(days: 30));
  return leads.where((l) {
    if (!interessadoDaPagina(l.origem)) return false;
    final c = _data(l.criadoEm);
    return c != null && !_dia(c).isBefore(limite);
  }).length;
}

String interessadosPaginaCartao(int n) {
  if (n == 0) return 'Ninguém chegou pela página nos últimos 30 dias';
  if (n == 1) return '1 pessoa chegou pela página nos últimos 30 dias';
  return '$n pessoas chegaram pela página nos últimos 30 dias';
}

/// Busca só com mais de 6 pessoas.
bool interessadosMostraBusca({required int total, required String query}) =>
    total > 6 || query.trim().isNotEmpty;

/// "Conversou com Thales?" só depois de sair por WhatsApp ou Ligar.
bool interessadoPerguntarConversa({required String? saiuPor}) =>
    saiuPor == 'WHATSAPP' || saiuPor == 'LIGACAO';

/// Depois de anotar o contato, "Para responder" passa a "Em conversa".
String? interessadoEtapaDepoisDoContato(String status) =>
    status.trim().toUpperCase() == 'LEAD' ? 'TESTE' : null;

String interessadoInteracaoLabel(String tipo) => switch (tipo.toUpperCase()) {
  'WHATSAPP' => 'WhatsApp',
  'LIGACAO' => 'Ligação',
  'EMAIL' => 'E-mail',
  'PRESENCIAL' => 'Presencial',
  _ => 'Outro',
};

String interessadoEmailEtapa(String etapa) => switch (etapa.toUpperCase()) {
  'H1' => 'E-mail automático enviado · 1 hora depois',
  'D1' => 'E-mail automático enviado · 1 dia depois',
  'D3' => 'E-mail automático enviado · 3 dias depois',
  _ => 'E-mail automático enviado',
};

/// Um item do histórico da ficha (mais novo em cima).
class InteressadoEvento {
  const InteressadoEvento({
    required this.quando,
    required this.titulo,
    this.texto,
  });

  final DateTime quando;
  final String titulo;
  final String? texto;
}

List<InteressadoEvento> interessadoHistorico(
  Lead lead,
  List<LeadInteracao> interacoes,
) {
  final eventos = <InteressadoEvento>[
    for (final i in interacoes)
      if (_data(i.dataInteracao) case final d?)
        InteressadoEvento(
          quando: d,
          titulo: interessadoInteracaoLabel(i.tipo),
          texto: i.descricao.trim().isEmpty ? null : i.descricao.trim(),
        ),
    for (final e in lead.emailsAutomaticos)
      if (e.enviadoEm != null)
        InteressadoEvento(
          quando: e.enviadoEm!,
          titulo: interessadoEmailEtapa(e.etapa),
        ),
    if (interessadoDaPagina(lead.origem))
      if (_data(lead.criadoEm) case final c?)
        InteressadoEvento(quando: c, titulo: 'Chegou pela sua página'),
  ]..sort((a, b) => b.quando.compareTo(a.quando));
  return eventos;
}
