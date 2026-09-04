import '../../alunos/data/aluno_repository.dart';
import '../../financeiro/data/financeiro_repository.dart';
import 'dashboard_screen_helpers.dart';

const int dashboardAttentionFoldLimit = 2;

class DashboardAttentionEntry {
  const DashboardAttentionEntry({
    required this.nome,
    required this.titulo,
    required this.subt,
    required this.acao,
    required this.route,
    required this.icon,
  });

  final String nome;
  final String titulo;
  final String subt;
  final String acao;
  final String route;
  final String icon;
}

class DashboardAttentionSplit {
  const DashboardAttentionSplit({required this.fold, required this.more});

  final List<DashboardAttentionEntry> fold;
  final List<DashboardAttentionEntry> more;

  int get total => fold.length + more.length;
  bool get hasMore => more.isNotEmpty;
  List<DashboardAttentionEntry> get pool => [...fold, ...more];
}

List<DashboardAttentionEntry> dashboardAttentionEntries({
  required List<Aluno> riskItems,
  required List<VencimentoItem> vencItems,
}) {
  return [
    for (final aluno in riskItems)
      DashboardAttentionEntry(
        nome: aluno.nome,
        titulo: attentionSignalLabel(aluno),
        subt: attentionSignalSub(aluno),
        acao: 'Revisar',
        route: '/alunos/${aluno.id}',
        icon: aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE'
            ? 'dollar-sign'
            : 'alert-triangle',
      ),
    for (final venc in vencItems)
      DashboardAttentionEntry(
        nome: venc.alunoNome,
        titulo: 'Inadimplente',
        subt: '${venc.valor.format(showDecimals: false)} pendente',
        acao: 'Cobrar',
        route: '/financeiro',
        icon: 'dollar-sign',
      ),
  ];
}

DashboardAttentionSplit dashboardAttentionSplit(
  List<DashboardAttentionEntry> items,
) {
  if (items.isEmpty) {
    return const DashboardAttentionSplit(fold: [], more: []);
  }
  if (items.length <= dashboardAttentionFoldLimit) {
    return DashboardAttentionSplit(fold: items, more: const []);
  }
  return DashboardAttentionSplit(
    fold: items.sublist(0, dashboardAttentionFoldLimit),
    more: items.sublist(dashboardAttentionFoldLimit),
  );
}
