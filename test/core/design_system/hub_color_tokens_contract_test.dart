import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hubs S+ não devem usar hex cru — tokens vivem em EagleTokens / BrandPalette.
void main() {
  const hubFiles = [
    'lib/features/alunos/utils/aluno_display_utils.dart',
    'lib/features/alunos/utils/aluno_hero_signal.dart',
    'lib/features/alunos/utils/alunos_list_utils.dart',
    'lib/features/alunos/utils/aluno360_timeline_logic.dart',
    'lib/features/alunos/widgets/aluno360_operational_status_section.dart',
    'lib/features/alunos/widgets/aluno_detail_hero_card.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
    'lib/features/ia/widgets/ia_copilot_shell_widgets.dart',
    'lib/features/chat/widgets/conversation_message_widgets.dart',
    'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
  ];

  test('hubs S+ evitam Color(0x literais', () {
    final failures = <String>[];
    for (final path in hubFiles) {
      final source = File(path).readAsStringSync();
      if (source.contains('Color(0x')) {
        failures.add(path);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
