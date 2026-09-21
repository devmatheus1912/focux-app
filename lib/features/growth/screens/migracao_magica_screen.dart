import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/fx_wizard_chrome.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../data/migracao_magica_draft_cache.dart';
import '../utils/migracao_magica_display.dart';
import '../utils/migracao_vagas_logic.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/utils/aluno_invite_copy.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../models/migracao_aluno_linha.dart';
import '../models/migracao_importacao_resumo.dart';
import '../utils/migracao_file_parser.dart';
import '../utils/migracao_foto_limits.dart';
import '../utils/migracao_ocr_service.dart';
import 'package:url_launcher/url_launcher.dart';

part 'migracao_magica_screen_actions.part.dart';
part 'migracao_magica_screen_state.part.dart';
part 'migracao_magica_screen_build.part.dart';

class MigracaoMagicaScreen extends ConsumerStatefulWidget {
  const MigracaoMagicaScreen({super.key});

  @override
  ConsumerState<MigracaoMagicaScreen> createState() =>
      _MigracaoMagicaScreenState();
}
