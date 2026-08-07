import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/utils/perfil_professional_summary.dart';

void main() {
  test('summary highlights missing phone and builds CTA', () {
    final summary = PerfilProfessionalSummary.from(
      perfil: PerfilPersonal(
        id: 1,
        nome: 'QA',
        email: 'qa@example.com',
        cref: '123456-G/SP',
        especialidade: 'Hipertrofia',
        especialidades: 'Hipertrofia',
        instagram: '@qa',
        plano: 'PRO',
      ),
      dashboard: DashboardData(
        totalAlunos: 1,
        alunosAtivos: 1,
        planoAtual: 'PRO',
        limiteAlunos: 10,
        nomePersonal: 'QA',
      ),
    );

    expect(summary.missingPhone, isTrue);
    expect(summary.ctaLabel, 'Completar cadastro');
    expect(summary.lines.first, 'WhatsApp pendente');
    expect(summary.lines, contains('123456-G/SP'));
  });
}
