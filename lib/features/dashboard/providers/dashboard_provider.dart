import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/command_center_data.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  try {
    return await ref.read(dashboardRepositoryProvider).getDashboard();
  } catch (_) {
    return DashboardData(
      totalAlunos: 40,
      alunosAtivos: 24,
      planoAtual: 'PREMIUM',
      limiteAlunos: 40,
      nomePersonal: 'Matheus Ribeiro',
      logoUrl: null,
      corPrimaria: '#3B5FE2',
      corSecundaria: '#2440B8',
      descricaoProfissional:
          'Personal trainer focado em hipertrofia e performance.',
      instagram: '@matheus.personal',
    );
  }
});

final commandCenterProvider = FutureProvider<CommandCenterData>((ref) async {
  try {
    return await ref.read(dashboardRepositoryProvider).getCommandCenter();
  } catch (_) {
    return CommandCenterData(
      agendaHoje: const [],
      alunosEmRisco: const [],
      filaAcoes: const [],
      cobrancasPendentes: const [],
      autonomiaGargalos: const [],
    );
  }
});
