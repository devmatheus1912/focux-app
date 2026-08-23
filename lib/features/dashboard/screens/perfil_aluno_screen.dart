import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../anamnese/data/anamnese_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../utils/birth_date_api_format.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'perfil_aluno_screen_state.part.dart';
part 'perfil_aluno_screen_widgets.part.dart';

class PerfilAlunoScreen extends ConsumerStatefulWidget {
  const PerfilAlunoScreen({super.key});

  @override
  ConsumerState<PerfilAlunoScreen> createState() => _PerfilAlunoScreenState();
}
