import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno_avatar.dart';

void main() {
  group('AlunoAvatar sizes', () {
    test('hero avatar is at least list size for human recognition', () {
      expect(AlunoAvatar.heroSize, greaterThanOrEqualTo(AlunoAvatar.listSize));
      expect(AlunoAvatar.heroSize, 48);
      expect(AlunoAvatar.listSize, 48);
    });
  });
}
