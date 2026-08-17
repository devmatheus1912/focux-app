import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/alunos/widgets/aluno_outreach_message_sheet.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/relatorio_repository.dart';
import '../utils/relatorio_pdf_export.dart';
import '../../alunos/constants/aluno_360_layout.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';

part 'relatorio_screen_state.part.dart';
part 'relatorio_screen_widgets.part.dart';

class RelatorioScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const RelatorioScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<RelatorioScreen> createState() => _RelatorioScreenState();
}
