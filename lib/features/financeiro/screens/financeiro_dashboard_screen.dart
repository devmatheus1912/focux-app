import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/financeiro_repository.dart';
import '../providers/financeiro_provider.dart';
import '../../pricing/widgets/smart_pricing_card.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'financeiro_dashboard_screen_state.part.dart';
part 'financeiro_dashboard_screen_widgets.part.dart';

class FinanceiroDashboardScreen extends ConsumerStatefulWidget {
  const FinanceiroDashboardScreen({super.key});

  @override
  ConsumerState<FinanceiroDashboardScreen> createState() =>
      _FinanceiroDashboardScreenState();
}
