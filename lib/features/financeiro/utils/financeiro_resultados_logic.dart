import '../../../core/utils/pt_br_display.dart';
import '../data/financeiro_repository.dart';

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
