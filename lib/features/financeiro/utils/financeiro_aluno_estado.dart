import '../../../core/money/fx_money.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_hub_display.dart';

enum FinanceiroAlunoSituacao { emDia, emAberto, atrasado }

/// O que o aluno precisa saber ao abrir Mensalidades: deve algo, quanto e quando.
class FinanceiroAlunoEstado {
  const FinanceiroAlunoEstado({
    required this.situacao,
    required this.titulo,
    required this.linha,
    required this.subtituloTopo,
    required this.paraPagar,
  });

  final FinanceiroAlunoSituacao situacao;

  /// "Tudo em dia", "R$ 200,00" ou "R$ 200,00 em atraso".
  final String titulo;

  /// "Última paga: novembro de 2026", "Vence em 05/12 · +1 em aberto"…
  final String linha;

  /// Subtítulo do topo: "Tudo em dia", "1 em aberto", "2 em atraso".
  final String subtituloTopo;

  /// A mais antiga em aberto: é a que o "Pagar com PIX" abre.
  final Mensalidade? paraPagar;
}

bool _aberta(Mensalidade m) => m.status == 'PENDENTE' || m.status == 'ATRASADO';

/// Data que ordena e aparece: o vencimento ou, sem ele, o mês de referência.
DateTime? _quando(Mensalidade m) {
  final venc = financeiroParseIsoDate(m.vencimento?.trim() ?? '');
  if (venc != null) return venc;
  return financeiroParseIsoDate('${m.mesReferencia.trim()}-01');
}

/// "novembro de 2026".
String _mesDeAno(String mesReferencia) {
  final t = financeiroMensalidadeMesPorExtenso(mesReferencia).toLowerCase();
  final i = t.lastIndexOf(' ');
  return i < 0 ? t : '${t.substring(0, i)} de ${t.substring(i + 1)}';
}

String _diaMes(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

/// [parcial]: a lista é paginada e ainda há mais (a soma é das carregadas).
FinanceiroAlunoEstado financeiroAlunoEstado(
  List<Mensalidade> mensalidades, {
  required bool parcial,
}) {
  final recorte = parcial ? ' · nas cobranças carregadas' : '';
  final abertas = mensalidades.where(_aberta).toList()
    ..sort((a, b) {
      final da = _quando(a);
      final db = _quando(b);
      if (da == null || db == null) return 0;
      return da.compareTo(db);
    });
  final atrasadas = abertas.where((m) => m.status == 'ATRASADO').toList();

  if (abertas.isEmpty) {
    final pagas = mensalidades.where((m) => m.status == 'PAGO').toList()
      ..sort((a, b) => b.mesReferencia.compareTo(a.mesReferencia));
    final linha =
        pagas.isEmpty
            ? 'Nenhuma cobrança em aberto'
            : 'Última paga: ${_mesDeAno(pagas.first.mesReferencia)}';
    return FinanceiroAlunoEstado(
      situacao: FinanceiroAlunoSituacao.emDia,
      titulo: 'Tudo em dia',
      linha: '$linha$recorte',
      subtituloTopo: 'Tudo em dia',
      paraPagar: null,
    );
  }

  final total = abertas.fold(FxMoney.zero, (s, m) => s + m.valor);
  final outras = abertas.length - 1;
  final mais = outras > 0 ? ' · +$outras em aberto' : '';

  if (atrasadas.isNotEmpty) {
    final emAtraso = atrasadas.fold(FxMoney.zero, (s, m) => s + m.valor);
    final quando = _quando(atrasadas.first);
    final outrasAlemDasAtrasadas = abertas.length - atrasadas.length;
    final extra =
        outrasAlemDasAtrasadas > 0 ? ' · +$outrasAlemDasAtrasadas em aberto' : '';
    return FinanceiroAlunoEstado(
      situacao: FinanceiroAlunoSituacao.atrasado,
      titulo: '${emAtraso.formatCobranca()} em atraso',
      linha:
          '${quando == null ? 'Vencida' : 'Venceu em ${_diaMes(quando)}'}$extra$recorte',
      subtituloTopo: '${atrasadas.length} em atraso',
      paraPagar: atrasadas.first,
    );
  }

  final quando = _quando(abertas.first);
  return FinanceiroAlunoEstado(
    situacao: FinanceiroAlunoSituacao.emAberto,
    titulo: total.formatCobranca(),
    linha:
        '${quando == null ? 'Em aberto' : 'Vence em ${_diaMes(quando)}'}$mais$recorte',
    subtituloTopo: '${abertas.length} em aberto',
    paraPagar: abertas.first,
  );
}
