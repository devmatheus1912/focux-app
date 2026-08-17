import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../data/enums.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'exercicio_detail_screen_state.part.dart';
part 'exercicio_detail_screen_widgets.part.dart';

class ExercicioDetailScreen extends ConsumerStatefulWidget {
  final int exercicioId;
  const ExercicioDetailScreen({super.key, required this.exercicioId});

  @override
  ConsumerState<ExercicioDetailScreen> createState() =>
      _ExercicioDetailScreenState();
}
