import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/progressao_aceitar_route_args.dart';

void main() {
  test('fromExtra parses aluno context for revisão pós-360', () {
    final args = ProgressaoAceitarRouteArgs.fromExtra({
      'returnTo': '/alunos/12',
      'alunoId': 12,
      'alunoNome': 'Nathalia',
    });

    expect(args.returnTo, '/alunos/12');
    expect(args.alunoId, 12);
    expect(args.alunoNome, 'Nathalia');
    expect(args.toExtra(), containsPair('alunoId', 12));
  });

  test('fromExtra returns empty args for null extra', () {
    final args = ProgressaoAceitarRouteArgs.fromExtra(null);
    expect(args.alunoId, isNull);
    expect(args.returnTo, isNull);
  });
}
