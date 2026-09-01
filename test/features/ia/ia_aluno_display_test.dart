import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_aluno_display.dart';

void main() {
  test('iaAlunoHubView labels', () {
    expect(iaAlunoHubViewLabel(IaAlunoHubView.chat), 'Chat');
    expect(iaAlunoHubViewLabel(IaAlunoHubView.progressao), 'Progressão');
    expect(
      iaAlunoHubSubtitle(IaAlunoHubView.progressao),
      contains('só se você pedir'),
    );
  });
}
