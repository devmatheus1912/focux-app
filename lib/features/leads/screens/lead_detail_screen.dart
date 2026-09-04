import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/utils/aluno360_followup_dates.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/lead_repository.dart';
import '../utils/lead_display.dart';
import '../widgets/lead_detail_help_sheet.dart';

part 'lead_detail_screen_state.part.dart';
part 'lead_detail_screen_widgets.part.dart';

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead? lead;
  final int? leadId;

  const LeadDetailScreen({super.key, this.lead, this.leadId})
    : assert(lead != null || leadId != null);

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}
