import '../../../l10n/pt.dart';
import '../../../core/money/fx_money.dart';
import '../../../core/utils/fx_utils.dart';
import '../data/command_center_data.dart';
import 'dashboard_command_copy.dart';

/// O que o botão da linha diz que vai acontecer.
enum HojeVerbo {
  chamar('Chamar'),
  cobrar('Cobrar'),
  renovar('Renovar'),
  responder('Responder'),
  revisar('Revisar'),
  abrir('Abrir');

  const HojeVerbo(this.rotulo);

  final String rotulo;
}

/// Uma linha do "Agora": uma pessoa (ou um grupo), um motivo e um verbo.
class HojeAgoraItem {
  const HojeAgoraItem({
    required this.verbo,
    required this.titulo,
    required this.motivo,
    required this.rota,
    this.verboRotulo,
    this.actionKey,
  });

  final HojeVerbo verbo;
  final String titulo;
  final String motivo;
  final String rota;

  /// Rótulo próprio vindo do servidor (ex.: "Conferir"). Sem ele usa o do verbo.
  final String? verboRotulo;

  /// Chave da ação da fila; algumas se concluem ao abrir (ex.: conferir agenda).
  final String? actionKey;

  String get rotulo => verboRotulo ?? verbo.rotulo;
}

/// Quantas linhas aparecem antes de "Ver todas".
const int kHojeAgoraVisiveis = 3;

const _chaveRisco = 'RISK_STUDENTS';
const _chaveCobranca = 'BILLING_PENDING';
const _prefixoFicha = 'FICHA_VENCENDO_';
const _prefixoTituloFicha = 'Renovar a ficha de ';
const _rotaCopiloto = '/dashboard/command-center/copiloto';

bool _filaRisco(FilaAcaoResumo a) =>
    a.actionKey == _chaveRisco || a.tipo == 'RISCO';
bool _filaCobranca(FilaAcaoResumo a) =>
    a.actionKey == _chaveCobranca || a.tipo == 'COBRANCA';
bool _filaFicha(FilaAcaoResumo a) => a.actionKey.startsWith(_prefixoFicha);

/// Ordem: aluno sumido, cobrança vencida, ficha que venceu ou vence hoje,
/// conversas sem resposta e o resto da fila.
///
/// Cobrança só entra quando venceu (`diasAtraso > 0`); em aberto e no prazo
/// fica de fora. Ficha que ainda vai vencer (P1) não é urgência: conta só em
/// "A base" ([fichasAVencer]).
List<HojeAgoraItem> hojeAgora({
  required List<AlertaResumo> risco,
  required List<MensalidadeResumo> cobrancas,
  required List<FilaAcaoResumo> fila,
  required int conversasSemResposta,
}) {
  final itens = <HojeAgoraItem>[];

  for (final aluno in risco) {
    final motivo = aluno.motivo.trim();
    itens.add(
      HojeAgoraItem(
        verbo: HojeVerbo.chamar,
        titulo: fxTitleCaseName(aluno.nomeAluno),
        motivo: motivo.isEmpty ? 'Precisa de contato' : motivo,
        rota: '/alunos/${aluno.id}',
      ),
    );
  }

  final vencidas =
      cobrancas.where((m) => m.diasAtraso > 0).toList()
        ..sort((a, b) => b.diasAtraso.compareTo(a.diasAtraso));
  for (final m in vencidas) {
    itens.add(
      HojeAgoraItem(
        verbo: HojeVerbo.cobrar,
        titulo: fxTitleCaseName(m.nomeAluno),
        motivo: '${_dinheiro(m.valor)} vencida há ${_dias(m.diasAtraso)}',
        rota: m.alunoId == null ? '/financeiro' : '/alunos/${m.alunoId}',
      ),
    );
  }

  for (final a in fila.where(_filaFicha)) {
    if (a.prioridade.toUpperCase() != 'P0') continue;
    itens.add(
      HojeAgoraItem(
        verbo: HojeVerbo.renovar,
        titulo: _nomeDaFicha(a),
        motivo: 'Ficha: ${_minuscula(a.descricao)}',
        rota: a.acaoUrl,
      ),
    );
  }

  if (conversasSemResposta > 0) {
    itens.add(
      HojeAgoraItem(
        verbo: HojeVerbo.responder,
        titulo:
            conversasSemResposta == 1
                ? '1 conversa'
                : '$conversasSemResposta conversas',
        motivo: 'Sem resposta',
        rota: '/chat/inbox',
      ),
    );
  }

  for (final a in fila) {
    if (_filaRisco(a) || _filaCobranca(a) || _filaFicha(a)) continue;
    // Boa notícia (evolução, recorde) não é pendência: vai para "Boas notícias".
    if (hojeEhBoaNoticia(a)) continue;
    // "Radar Focux: Nome" repete o aluno sumido que já tem linha.
    final radar = dashboardRadarStudentName(a.titulo);
    if (radar != null && itens.any((i) => i.titulo == radar)) continue;
    final copiloto = a.tipo == 'IA_COPILOTO';
    final cta = a.ctaLabel.trim();
    itens.add(
      HojeAgoraItem(
        verbo: copiloto ? HojeVerbo.revisar : HojeVerbo.abrir,
        verboRotulo:
            !copiloto && cta.isNotEmpty && cta.length <= 12 ? cta : null,
        titulo: a.titulo.trim().isEmpty ? 'Prioridade' : a.titulo.trim(),
        motivo: a.descricao.trim(),
        rota: copiloto ? _rotaCopiloto : _rotaDaFila(a),
        actionKey: a.actionKey.isEmpty ? null : a.actionKey,
      ),
    );
  }
  return itens;
}

/// Fichas que vencem em breve (inclui as que já venceram): é o número de "A base".
int fichasAVencer(List<FilaAcaoResumo> fila) => fila.where(_filaFicha).length;

String _rotaDaFila(FilaAcaoResumo a) =>
    a.acaoUrl.startsWith('/') ? a.acaoUrl : '/dashboard/personal';

String _nomeDaFicha(FilaAcaoResumo a) {
  final titulo = a.titulo.trim();
  final nome =
      titulo.startsWith(_prefixoTituloFicha)
          ? titulo.substring(_prefixoTituloFicha.length)
          : titulo;
  return fxTitleCaseName(nome);
}

String _minuscula(String texto) {
  final t = texto.trim();
  return t.isEmpty ? t : t[0].toLowerCase() + t.substring(1);
}

String _dias(int n) => n == 1 ? '1 dia' : '$n dias';

String _dinheiro(double reais) {
  final cents = (reais * 100).round();
  return formatBrlCents(cents, showDecimals: cents % 100 != 0);
}

/// Linha abaixo do "Olá": o dia, os atendimentos e, só depois de 5 min, o
/// frescor ("Quarta, 12 de nov · 3 atendimentos").
String hojeLinhaUtil({
  required int atendimentos,
  String? freshness,
  DateTime? hoje,
}) {
  final d = hoje ?? DateTime.now();
  const dias = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  const meses = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  final quando = '${dias[d.weekday - 1]}, ${d.day} de ${meses[d.month - 1]}';
  final atend = switch (atendimentos) {
    0 => null,
    1 => ptS.hojeUmAtendimento,
    _ => ptS.hojeNAtendimentos(atendimentos),
  };
  return [
    quando,
    if (atend != null) atend,
    if (freshness != null) freshness,
  ].join(' · ');
}

/// Evolução e recorde: boa notícia, não pendência.
bool hojeEhBoaNoticia(FilaAcaoResumo a) =>
    a.severidade.trim().toUpperCase() == 'POSITIVA' ||
    a.tipo.trim().toUpperCase() == 'EVOLUCAO';

/// Uma boa notícia da Hoje: quem, o quê e a mensagem pronta do parabéns.
class HojeBoaNoticia {
  const HojeBoaNoticia({
    required this.actionKey,
    required this.titulo,
    required this.frase,
    required this.alunoId,
    required this.rascunho,
  });

  final String actionKey;
  final String titulo;
  final String frase;
  final int? alunoId;
  final String rascunho;
}

/// Boas notícias dos últimos 3 dias (depois disso somem sozinhas).
List<HojeBoaNoticia> hojeBoasNoticias(
  List<FilaAcaoResumo> fila, {
  DateTime? agora,
}) {
  final limite = (agora ?? DateTime.now()).subtract(const Duration(days: 3));
  final out = <HojeBoaNoticia>[];
  for (final a in fila) {
    if (!hojeEhBoaNoticia(a)) continue;
    if (a.status.trim().toUpperCase() != 'ABERTO' &&
        a.status.trim().isNotEmpty) {
      continue;
    }
    final quando =
        DateTime.tryParse(a.updatedAt ?? a.createdAt ?? '')?.toLocal();
    if (quando != null && quando.isBefore(limite)) continue;
    final frase = a.descricao.split('\n').first.trim();
    final exercicio = frase.contains(':') ? frase.split(':').first.trim() : '';
    out.add(
      HojeBoaNoticia(
        actionKey: a.actionKey,
        titulo: a.titulo.trim(),
        frase: frase,
        alunoId: a.alunoId,
        rascunho:
            exercicio.isEmpty
                ? 'Vi sua evolução no treino. Parabéns, continua assim!'
                : 'Vi seu recorde no $exercicio. Parabéns, continua assim!',
      ),
    );
  }
  return out;
}
