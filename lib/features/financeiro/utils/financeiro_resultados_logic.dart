import '../../../core/utils/pt_br_display.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';

/// Números de coorte (receita mantida, média por aluno, valor do aluno e saída)
/// só dizem alguma coisa com base suficiente. Abaixo disso viram ruído, e
/// 0,0% em vermelho assusta quem acabou de começar.
const resultadosMinPagantes = 10;
const resultadosMinMeses = 3;

bool resultadosDetalhesVisiveis({
  required int pagantes,
  required int mesesComCobranca,
}) => pagantes >= resultadosMinPagantes && mesesComCobranca >= resultadosMinMeses;

/// O recebido (por data de pagamento) passou do lançado (por mês da cobrança):
/// a tela explica a diferença em vez de deixar parecer erro.
bool resultadosRecebidoMaiorQueLancado(ResumoMensal r) =>
    r.totalRecebido > r.totalPrevisto;

/// Mês da coorte = mês atual. Para outro mês, só os números do próprio mês.
bool resultadosEhMesAtual(int ano, int mes, DateTime hoje) =>
    ano == hoje.year && mes == hoje.month;

String resultadosPct(double? pct) => pct == null ? '—' : formatBrPercent(pct);

/// "12" ou "7,5": meses de permanência com uma casa só quando precisa.
String resultadosMesesLabel(double meses) => meses
    .toStringAsFixed(meses == meses.roundToDouble() ? 0 : 1)
    .replaceAll('.', ',');

/// Resultados só olham para trás: mês futuro não tem o que mostrar.
List<FinanceiroMesOpcao> resultadosMesOpcoes(DateTime agora) => [
  for (final o in financeiroMesOpcoes(agora: agora))
    if (!resultadosMesFuturo(o.ano, o.mes, agora)) o,
];

bool resultadosMesFuturo(int ano, int mes, DateTime agora) =>
    ano > agora.year || (ano == agora.year && mes > agora.month);

/// Parte do lançado que já entrou, de 0 a 1.
double resultadosProgresso(ResumoMensal r) {
  if (!r.totalPrevisto.isPositive) return 0;
  return (r.totalRecebido.cents / r.totalPrevisto.cents).clamp(0.0, 1.0);
}

/// `2026-10` em ano e mês; nulo se não vier nesse formato.
({int ano, int mes})? resultadosMesDoItem(String raw) {
  final partes = raw.split('-');
  if (partes.length < 2) return null;
  final ano = int.tryParse(partes[0]);
  final mes = int.tryParse(partes[1]);
  return ano == null || mes == null ? null : (ano: ano, mes: mes);
}

/// Variação do recebido contra o mês anterior; nula fora do histórico.
int? resultadosVariacaoPct(List<EvolucaoMensalItem> itens, int ano, int mes) {
  final i = itens.indexWhere((e) {
    final m = resultadosMesDoItem(e.mes);
    return m?.ano == ano && m?.mes == mes;
  });
  if (i < 1) return null;
  final antes = itens[i - 1].recebido.cents;
  if (antes <= 0) return null;
  return ((itens[i].recebido.cents - antes) / antes * 100).round();
}
