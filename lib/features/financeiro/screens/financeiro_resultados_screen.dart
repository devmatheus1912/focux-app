import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../pricing/widgets/smart_pricing_card.dart';
import '../../relatorio/data/business_repository.dart';
import '../data/financeiro_repository.dart';
import '../financeiro_hub_scope.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';
import '../utils/financeiro_resultados_logic.dart';

part 'financeiro_resultados_screen_state.part.dart';
part 'financeiro_resultados_screen_widgets.part.dart';

/// Resultados do Financeiro: quanto entrou, quanto falta, quem atrasa e para
/// onde o negócio vai. Junta o que era Panorama e Receita recorrente.
class FinanceiroResultadosScreen extends ConsumerStatefulWidget {
  const FinanceiroResultadosScreen({super.key});

  @override
  ConsumerState<FinanceiroResultadosScreen> createState() =>
      _FinanceiroResultadosScreenState();
}
