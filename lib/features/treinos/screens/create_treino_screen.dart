import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../providers/treinos_provider.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../../../core/theme/tokens_strip.dart';

part 'create_treino_screen_state.part.dart';
part 'create_treino_screen_widgets.part.dart';

const _niveis = ['INICIANTE', 'INTERMEDIARIO', 'AVANCADO'];
const _niveisLabel = ['Iniciante', 'Intermediário', 'Avançado'];
const _niveisIcon = [
  Icons.eco_rounded,
  Icons.speed_rounded,
  Icons.local_fire_department_rounded,
];
const _niveisCor = [EagleTokens.good, EagleTokens.warn, EagleTokens.bad];

const _objetivoPresets = [
  _TreinoPreset('Hipertrofia', 'Volume e carga', Icons.trending_up_rounded),
  _TreinoPreset('Emagrecimento', 'Ritmo e aderência', Icons.bolt_rounded),
  _TreinoPreset('Força', 'Base e progressão', Icons.fitness_center_rounded),
  _TreinoPreset('Condicionamento', 'Capacidade geral', Icons.speed_rounded),
];

class CreateTreinoScreen extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const CreateTreinoScreen({super.key, this.alunoId, this.alunoNome});

  @override
  ConsumerState<CreateTreinoScreen> createState() => _CreateTreinoScreenState();
}
