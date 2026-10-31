import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/perfil/data/perfil_repository.dart';
import 'package:focux_app/features/perfil/utils/perfil_readiness.dart';

void main() {
  test('falta de foto vem primeiro', () {
    final view = PerfilReadinessView.from(_perfil(logoUrl: null));

    expect(view.score, 83);
    expect(view.items.map((i) => i.label), [
      'Foto',
      'CREF',
      'Especialidade',
      'Bio',
      'Telefone',
      'Instagram',
    ]);
    expect(view.nextStep?.buttonLabel, 'Adicionar foto');
    expect(view.nextStep?.action, PerfilChecklistAction.photo);
  });

  test('telefone abre a edição do perfil', () {
    final view = PerfilReadinessView.from(_perfil(telefone: null));

    expect(view.nextStep?.label, 'Telefone');
    expect(view.nextStep?.buttonLabel, 'Adicionar telefone');
    expect(view.nextStep?.action, PerfilChecklistAction.editProfile);
  });

  test('Free fecha 100% sem cor nem PIX, e o número do backend não manda', () {
    final view = PerfilReadinessView.from(
      _perfil(
        readinessPercent: 13,
        readinessMissing: const ['Paleta', 'PIX'],
      ),
    );

    expect(view.score, 100);
    expect(view.nextStep, isNull);
  });

  test('perfilReadinessGapCopy pluraliza', () {
    expect(perfilReadinessGapCopy(0), 'Seu perfil está pronto.');
    expect(perfilReadinessGapCopy(1), 'Falta 1 passo no seu perfil.');
    expect(perfilReadinessGapCopy(2), 'Faltam 2 passos no seu perfil.');
  });

  test('carteira aceita PIX ou banco completo', () {
    expect(perfilHasWallet(_perfil()), isFalse);
    expect(
      perfilHasWallet(
        PerfilPersonal(
          id: 1,
          nome: 'QA',
          email: 'qa@example.com',
          plano: 'FREE',
          chavePix: 'qa@example.com',
        ),
      ),
      isTrue,
    );
  });
}

const _semValor = Object();

PerfilPersonal _perfil({
  Object? logoUrl = _semValor,
  Object? telefone = _semValor,
  int? readinessPercent,
  List<String>? readinessMissing,
}) => PerfilPersonal(
  id: 7,
  nome: 'QA Coach',
  email: 'qa@example.com',
  logoUrl:
      identical(logoUrl, _semValor)
          ? 'https://cdn.example/logo.png'
          : logoUrl as String?,
  telefone: identical(telefone, _semValor) ? '11999998888' : telefone as String?,
  cref: '123456-G/SP',
  especialidades: 'Hipertrofia',
  plano: 'FREE',
  descricaoProfissional: 'Bio',
  instagram: '@qacoach',
  readinessPercent: readinessPercent,
  readinessMissing: readinessMissing,
);
