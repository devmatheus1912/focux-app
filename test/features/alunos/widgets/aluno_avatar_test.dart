import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/widgets/aluno_avatar.dart';

void main() {
  group('AlunoAvatar sizes', () {
    test('identity strip avatars stay within readable bounds', () {
      expect(AlunoAvatar.stripSize, 40);
      expect(AlunoAvatar.heroSize, 44);
      expect(AlunoAvatar.listSize, 48);
      expect(AlunoAvatar.heroSize, greaterThanOrEqualTo(AlunoAvatar.stripSize));
    });
  });
}
