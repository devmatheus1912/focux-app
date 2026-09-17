import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../financeiro_hub_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/financeiro_repository.dart';
import '../providers/financeiro_provider.dart';
import '../../pricing/widgets/smart_pricing_card.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../utils/financeiro_hub_display.dart';
import 'financeiro_resumo_screen.dart';

part 'financeiro_dashboard_screen_state.part.dart';
part 'financeiro_dashboard_screen_widgets.part.dart';

class FinanceiroDashboardScreen extends ConsumerStatefulWidget {
  const FinanceiroDashboardScreen({super.key});

  @override
  ConsumerState<FinanceiroDashboardScreen> createState() =>
      _FinanceiroDashboardScreenState();
}
