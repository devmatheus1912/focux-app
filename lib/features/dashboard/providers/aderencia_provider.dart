import '../data/dashboard_repository.dart';

class AderenciaAlunoResumo {
  final int alunoId;
  final String nome;
  final String? objetivo;
  final List<double> sparkline;
  final int totalCheckinsSemana;
  final int aderenciaPercent;

  const AderenciaAlunoResumo({
    required this.alunoId,
    required this.nome,
    required this.objetivo,
    required this.sparkline,
    required this.totalCheckinsSemana,
    required this.aderenciaPercent,
  });

  factory AderenciaAlunoResumo.fromHomeItem(DashboardAderenciaTopItem item) {
    return AderenciaAlunoResumo(
      alunoId: item.alunoId,
      nome: item.nome,
      objetivo: item.objetivo,
      sparkline: item.sparkline,
      totalCheckinsSemana: item.totalCheckinsSemana,
      aderenciaPercent: item.aderenciaPercent,
    );
  }
}
