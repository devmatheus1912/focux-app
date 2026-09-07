import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/design_system/focux_surfaces.dart';

void main() {
  test('interpolates :id parent from a nested aluno route', () {
    expect(
      FocuxSurfaces.interpolateParent(
        '/alunos/:id/editar',
        '/alunos/42/editar',
        '/alunos/:id',
      ),
      '/alunos/42',
    );
  });

  test('keeps static parent when the pattern has no params', () {
    expect(
      FocuxSurfaces.interpolateParent(
        '/alertas/config',
        '/alertas/config',
        '/alertas',
      ),
      '/alertas',
    );
  });

  test('resolves catalog type and parent for a concrete aluno path', () {
    final match = FocuxSurfaces.resolve('/alunos/9/editar');
    expect(match, isNotNull);
    expect(match!.spec.type, FocuxSurfaceType.s5);
    expect(match.spec.hasInput, isTrue);
    expect(FocuxSurfaces.resolveParent(match), '/alunos/9');
  });

  test('wallet is S3 with keyboard input', () {
    final match = FocuxSurfaces.resolve('/perfil/wallet');
    expect(match, isNotNull);
    expect(match!.spec.type, FocuxSurfaceType.s3);
    expect(match.spec.hasInput, isTrue);
    expect(FocuxSurfaces.resolveParent(match), '/perfil');
  });

  test('progressao de carga is S3 with keyboard input', () {
    final match = FocuxSurfaces.resolve('/alunos/9/ia/progressao');
    expect(match, isNotNull);
    expect(match!.spec.type, FocuxSurfaceType.s3);
    expect(match.spec.hasInput, isTrue);
    expect(FocuxSurfaces.resolveParent(match), '/alunos/9');
  });

  test('shell tabs do not show a back affordance', () {
    final match = FocuxSurfaces.resolve('/dashboard/personal');
    expect(match!.spec.shellTab, isTrue);
    expect(match.spec.showsBack, isFalse);
    expect(FocuxSurfaces.resolveParent(match), isNull);
  });

  test('wizards S9 têm pai e etapa', () {
    final setup = FocuxSurfaces.resolve('/onboarding/wizard');
    expect(setup!.spec.type, FocuxSurfaceType.s9);
    expect(FocuxSurfaces.resolveParent(setup), '/dashboard/personal');

    final biblioteca = FocuxSurfaces.resolve('/exercicios/biblioteca-wizard');
    expect(biblioteca!.spec.type, FocuxSurfaceType.s9);
    expect(FocuxSurfaces.resolveParent(biblioteca), '/exercicios');

    final alunoEditar = FocuxSurfaces.resolve('/aluno/perfil/editar');
    expect(alunoEditar!.spec.type, FocuxSurfaceType.s5);
    expect(FocuxSurfaces.resolveParent(alunoEditar), '/aluno/perfil');

    final ativacao = FocuxSurfaces.resolve('/aluno/ativacao');
    expect(ativacao!.spec.type, FocuxSurfaceType.s9);
    expect(FocuxSurfaces.resolveParent(ativacao), '/dashboard/aluno');

    final migracao = FocuxSurfaces.resolve('/migracao-magica');
    expect(migracao!.spec.type, FocuxSurfaceType.s9);
    expect(FocuxSurfaces.resolveParent(migracao), '/perfil');
    expect(
      FocuxSurfaces.resolve('/migracao-focux')!.spec.redirectTo,
      '/migracao-magica',
    );
    expect(
      FocuxSurfaces.resolve('/growth/migracao')!.spec.redirectTo,
      '/migracao-magica',
    );
  });

  test('setup identidade é S5, não wizard', () {
    final identidade = FocuxSurfaces.resolve('/setup/identidade');
    expect(identidade!.spec.type, FocuxSurfaceType.s5);
    expect(identidade.spec.hasInput, isTrue);
    expect(FocuxSurfaces.resolveParent(identidade), '/perfil');
  });

  test('checkin executar e presencial são S8', () {
    final checkin = FocuxSurfaces.resolve('/checkin/executar');
    expect(checkin!.spec.type, FocuxSurfaceType.s8);
    expect(FocuxSurfaces.resolveParent(checkin), '/checkin/treinos');

    final presencial = FocuxSurfaces.resolve('/treino-presencial/12');
    expect(presencial!.spec.type, FocuxSurfaceType.s8);
    expect(FocuxSurfaces.resolveParent(presencial), '/treinos/12');

    final feedback = FocuxSurfaces.resolve('/alunos/9/feedback-video');
    expect(feedback!.spec.type, FocuxSurfaceType.s4);
    expect(feedback.spec.hasInput, isTrue);
  });

  test('auth recovery parent is login', () {
    final match = FocuxSurfaces.resolve('/esqueci-senha');
    expect(match!.spec.type, FocuxSurfaceType.s6);
    expect(FocuxSurfaces.resolveParent(match), '/login');
  });
}
