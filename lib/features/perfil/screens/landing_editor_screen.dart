import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_celebration_overlay.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/landing_growth_repository.dart';
import '../providers/perfil_provider.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_checklist.dart';
import 'landing_editor_content_tab.dart';
import 'landing_editor_controller.dart';
import 'landing_editor_links_tab.dart';
import 'landing_editor_order_tab.dart';
import 'landing_editor_quality.dart';
import 'landing_editor_sections.dart';
import 'landing_preset_mapper.dart';
import 'landing_section_templates.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'landing_editor_screen_actions.part.dart';
part 'landing_editor_screen_state.part.dart';

class LandingEditorScreen extends ConsumerStatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  ConsumerState<LandingEditorScreen> createState() =>
      _LandingEditorScreenState();
}

