import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_calendario_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/lead_repository.dart';
import '../providers/leads_provider.dart';
import '../utils/interessados_display.dart';
import '../utils/lead_display.dart';
import '../widgets/interessado_contato_mixin.dart';
import '../widgets/interessado_sheets.dart';

part 'lead_detail_screen_state.part.dart';

/// Ficha de um interessado: etapa, contato, próximo contato e o histórico.
class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead? lead;
  final int? leadId;

  const LeadDetailScreen({super.key, this.lead, this.leadId})
    : assert(lead != null || leadId != null);

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}
