import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/fx_wizard_chrome.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../data/migracao_magica_draft_cache.dart';
import '../utils/migracao_magica_display.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
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

class _MigracaoImportacaoResumoBody extends StatelessWidget {
  const _MigracaoImportacaoResumoBody({required this.data});

  final MigracaoImportacaoResumo data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;

    Widget stat(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(TokensStrip.rSm),
          ),
          child: Column(
            children: [
              Text('$value', style: FocuxTypography.headline(color: color)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: mute, height: 1.3),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            stat('Importados', data.importados, brand),
            const SizedBox(width: 8),
            stat('Duplicados', data.duplicados, EagleTokens.warn),
            const SizedBox(width: 8),
            stat('Erros', data.erros, EagleTokens.bad),
          ],
        ),
        if (data.detalhes.isNotEmpty) ...[
          SizedBox(height: TokensStrip.s4),
          for (final item in data.detalhes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: switch (item.status) {
                        'IMPORTADO' => brand,
                        'DUPLICADO' => EagleTokens.warn,
                        _ => EagleTokens.bad,
                      },
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: ink,
                            fontSize: 13,
                          ),
                        ),
                        if (item.motivo.isNotEmpty)
                          Text(
                            item.motivo,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: mute,
                              height: 1.35,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
