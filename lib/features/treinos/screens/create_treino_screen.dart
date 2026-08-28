import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../providers/treinos_provider.dart';
import '../utils/create_treino_logic.dart';
import '../widgets/create_treino_help_sheet.dart';

part 'create_treino_screen_state.part.dart';
part 'create_treino_screen_widgets.part.dart';

class CreateTreinoScreen extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const CreateTreinoScreen({super.key, this.alunoId, this.alunoNome});

  @override
  ConsumerState<CreateTreinoScreen> createState() => _CreateTreinoScreenState();
}
