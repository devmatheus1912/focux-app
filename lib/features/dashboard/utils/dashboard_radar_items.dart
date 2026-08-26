import '../data/command_center_data.dart';

/// Recorte do Hoje: 2 no fold, até 5 no BFF. Cadastro não estica a lista.
const int dashboardRadarFoldLimit = 2;
const int dashboardRadarCap = 5;

/// Ficha incompleta / onboarding — job do aluno, não do Hoje.
/// Vale mesmo com risco alto: aluno recém-cadastrado ainda não treinou.
bool dashboardRadarIsCadastroGap(String proximaAcao) {
  final action = proximaAcao.toLowerCase();
  return action.contains('mapa corporal') ||
      action.contains('completar perfil') ||
      action.contains('completar cadastro') ||
      action.contains('completar ficha') ||
      action.contains('anamnese');
}

bool dashboardRadarIsOperationalRisk(String risco) {
  final normalized = risco.toLowerCase();
  return normalized.contains('alto') ||
      normalized.contains('moderado') ||
      normalized.contains('médio') ||
      normalized.contains('medio');
}

/// Contato / retenção / financeiro. Pendência de ficha e P1 de higiene saem.
bool dashboardRadarBelongsOnHome(AlunoScoreResumo item) {
  if (dashboardRadarIsCadastroGap(item.proximaAcao)) return false;
  if (dashboardRadarIsOperationalRisk(item.risco)) return true;
  final action = item.proximaAcao.toLowerCase();
  if (action.contains('financeiro') || action.contains('retomar')) {
    return true;
  }
  return item.prioridade.trim().toUpperCase() == 'P0';
}

bool dashboardRadarVisibleOnHome(List<AlunoScoreResumo> scores) =>
    dashboardRadarSplit(scores).fold.isNotEmpty;

class DashboardRadarSplit {
  const DashboardRadarSplit({required this.fold, required this.more});

  final List<AlunoScoreResumo> fold;
  final List<AlunoScoreResumo> more;

  int get total => fold.length + more.length;
  bool get hasMore => more.isNotEmpty;
  List<AlunoScoreResumo> get pool => [...fold, ...more];
}

DashboardRadarSplit dashboardRadarSplit(List<AlunoScoreResumo> scores) {
  final pool = scores
      .where(dashboardRadarBelongsOnHome)
      .take(dashboardRadarCap)
      .toList(growable: false);
  if (pool.isEmpty) {
    return const DashboardRadarSplit(fold: [], more: []);
  }
  if (pool.length <= dashboardRadarFoldLimit) {
    return DashboardRadarSplit(fold: pool, more: const []);
  }
  return DashboardRadarSplit(
    fold: pool.sublist(0, dashboardRadarFoldLimit),
    more: pool.sublist(dashboardRadarFoldLimit),
  );
}

/// Ícone leading do radar — triângulo só no risco alto.
String dashboardRadarIcon(String risco) {
  final normalized = risco.toLowerCase();
  if (normalized.contains('alto')) return 'alert-triangle';
  if (dashboardRadarIsOperationalRisk(risco)) return 'trend';
  return 'target';
}

String dashboardRadarCaption({required int fold, required int total}) {
  if (total <= 0) return '';
  if (total == 1) return 'Contato hoje · toque para abrir a ficha';
  if (fold >= total) return '$total pedem contato hoje';
  return '$fold no Hoje · $total pedem contato';
}
