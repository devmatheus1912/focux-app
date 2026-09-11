import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_aluno_display.dart';

void main() {
  test('aluno IA hub is chat-only', () {
    expect(IaAlunoHubView.values, [IaAlunoHubView.chat]);
    expect(iaAlunoHubViewLabel(IaAlunoHubView.chat), 'Chat');
    expect(
      iaAlunoHubSubtitle(IaAlunoHubView.chat),
      'Pergunte sobre treino ou saúde',
    );
    expect(iaAlunoComoCalculamos, contains('personal'));
  });
}
