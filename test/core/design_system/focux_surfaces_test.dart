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

  test('shell tabs do not show a back affordance', () {
    final match = FocuxSurfaces.resolve('/dashboard/personal');
    expect(match!.spec.shellTab, isTrue);
    expect(match.spec.showsBack, isFalse);
    expect(FocuxSurfaces.resolveParent(match), isNull);
  });

  test('auth recovery parent is login', () {
    final match = FocuxSurfaces.resolve('/esqueci-senha');
    expect(match!.spec.type, FocuxSurfaceType.s6);
    expect(FocuxSurfaces.resolveParent(match), '/login');
  });
}
