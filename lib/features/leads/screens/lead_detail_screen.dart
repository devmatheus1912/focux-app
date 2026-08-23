import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'lead_detail_screen_state.part.dart';
part 'lead_detail_screen_widgets.part.dart';

const _statusOpcoes = ['LEAD', 'TESTE', 'ATIVO', 'INADIMPLENTE', 'CANCELADO'];
const _statusLabels = {
  'LEAD': 'Lead',
  'TESTE': 'Teste',
  'ATIVO': 'Ativo',
  'INADIMPLENTE': 'Inadimplente',
  'CANCELADO': 'Cancelado',
};
Color _statusColor(String status, Color fallback) {
  if (status == 'LEAD') return fallback;
  if (status == 'TESTE') return EagleTokens.warn;
  if (status == 'ATIVO') return EagleTokens.good;
  if (status == 'INADIMPLENTE') return EagleTokens.bad;
  return TokensStrip.textSecondary;
}

const _tiposInteracao = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
const _tipoIcons = {
  'WHATSAPP': Icons.chat,
  'LIGACAO': Icons.phone,
  'EMAIL': Icons.email,
  'PRESENCIAL': Icons.handshake,
  'OUTRO': Icons.note,
};

class LeadDetailScreen extends ConsumerStatefulWidget {
  final Lead? lead;
  final int? leadId;

  const LeadDetailScreen({super.key, this.lead, this.leadId})
    : assert(lead != null || leadId != null);

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}
