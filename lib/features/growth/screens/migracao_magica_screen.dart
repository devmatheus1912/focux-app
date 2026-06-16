import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../models/migracao_aluno_linha.dart';
import '../models/migracao_importacao_resumo.dart';
import '../utils/migracao_file_parser.dart';
import '../utils/migracao_foto_limits.dart';
import '../utils/migracao_ocr_service.dart';

part 'migracao_magica_screen_actions.part.dart';
part 'migracao_magica_screen_state.part.dart';

class MigracaoMagicaScreen extends ConsumerStatefulWidget {
  const MigracaoMagicaScreen({super.key});

  @override
  ConsumerState<MigracaoMagicaScreen> createState() =>
      _MigracaoMagicaScreenState();
}
