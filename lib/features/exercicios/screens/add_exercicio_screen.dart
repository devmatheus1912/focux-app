import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/enums.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';
import '../widgets/add_exercicio_enum_picker_sheet.dart';
import '../widgets/add_exercicio_filters_sheet.dart';

part 'add_exercicio_screen_state.part.dart';
part 'add_exercicio_screen_widgets_form.part.dart';
part 'add_exercicio_screen_widgets_misc.part.dart';

class AddExercicioScreen extends ConsumerStatefulWidget {
  const AddExercicioScreen({super.key, this.exercicioId});

  /// Quando informado, abre em modo edição com o mesmo fold do cadastro.
  final int? exercicioId;

  @override
  ConsumerState<AddExercicioScreen> createState() => _AddExercicioScreenState();
}
