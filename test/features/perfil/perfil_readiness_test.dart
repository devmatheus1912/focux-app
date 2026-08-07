import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/utils/perfil_readiness.dart';

void main() {
  test('PerfilReadinessView resolves next step for missing photo', () {
    final view = PerfilReadinessView.from(
      perfil: _perfilFixture,
      dashboard: _dashboardFixture,
    );

    expect(view.score, 88);
    expect(view.items, hasLength(8));
    expect(view.nextStep?.label, 'Foto');
    expect(view.nextStep?.buttonLabel, 'Adicionar foto');
    expect(view.nextStep?.action, PerfilChecklistAction.photo);
  });

  test('PerfilReadinessView flags missing telefone locally', () {
    final view = PerfilReadinessView.from(
      perfil: _perfilCompleteExceptPhone,
      dashboard: _dashboardFixture,
    );

    expect(view.score, 88);
    expect(view.nextStep?.label, 'Telefone');
    expect(view.nextStep?.buttonLabel, 'Adicionar telefone');
    expect(view.nextStep?.action, PerfilChecklistAction.editProfile);
  });

  test('perfilReadinessGapCopy pluralizes correctly', () {
    expect(perfilReadinessGapCopy(0), contains('pronto'));
    expect(perfilReadinessGapCopy(1), 'Falta 1 passo para fechar o perfil comercial.');
    expect(perfilReadinessGapCopy(2), 'Faltam 2 passos para fechar o perfil comercial.');
  });

  test('PIX status stays consistent between checklist and wallet helper', () {
    final withPix = PerfilReadinessView.from(
      perfil: _perfilCompleteExceptPhone,
      dashboard: _dashboardFixture,
    );
    expect(withPix.isPixDone, isTrue);
    expect(perfilHasWallet(_perfilCompleteExceptPhone), isTrue);

    final noPix = PerfilReadinessView.from(
      perfil: PerfilPersonal(
        id: 1,
        nome: 'QA',
        email: 'qa@example.com',
        logoUrl: 'https://cdn.example/logo.png',
        telefone: '11999998888',
        cref: '123456-G/SP',
        especialidade: 'Hipertrofia',
        especialidades: 'Hipertrofia',
        corPrimaria: '#2D4FB7',
        corSecundaria: '#3F63E4',
        plano: 'ENTERPRISE',
        descricaoProfissional: 'Bio',
        instagram: '@qa',
      ),
      dashboard: _dashboardFixture,
    );
    expect(noPix.isPixDone, isFalse);
    expect(noPix.nextStep?.label, 'PIX');
  });
}

final _perfilFixture = PerfilPersonal(
  id: 7,
  nome: 'QA Coach',
  email: 'qa@example.com',
  telefone: '11999998888',
  cref: '123456-G/SP',
  especialidade: 'Hipertrofia',
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  slug: 'qa-demo-coach',
  plano: 'ENTERPRISE',
  chavePix: 'qa@example.com',
  descricaoProfissional: 'Especializado em biomecanica.',
  especialidades: 'Hipertrofia',
  instagram: '@qacoach',
  readinessPercent: 88,
  readinessMissing: const ['Foto'],
);

final _perfilCompleteExceptPhone = PerfilPersonal(
  id: 7,
  nome: 'QA Coach',
  email: 'qa@example.com',
  logoUrl: 'https://cdn.example/logo.png',
  cref: '123456-G/SP',
  especialidade: 'Hipertrofia',
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  slug: 'qa-demo-coach',
  plano: 'ENTERPRISE',
  chavePix: 'qa@example.com',
  descricaoProfissional: 'Especializado em biomecanica.',
  especialidades: 'Hipertrofia',
  instagram: '@qacoach',
);

final _dashboardFixture = DashboardData(
  totalAlunos: 6,
  alunosAtivos: 5,
  planoAtual: 'ENTERPRISE',
  limiteAlunos: 120,
  nomePersonal: 'QA Coach',
  logoUrl: null,
  corPrimaria: '#2D4FB7',
  corSecundaria: '#3F63E4',
  descricaoProfissional: 'Especializado em biomecanica.',
  instagram: '@qacoach',
);
