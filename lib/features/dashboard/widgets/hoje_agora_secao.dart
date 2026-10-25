import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../constants/dashboard_layout.dart';
import '../data/command_action_item.dart';
import '../utils/hoje_agora.dart';
import '../utils/open_dashboard_command_action.dart';
import 'dashboard_section_header.dart';

/// "Agora": até [kHojeAgoraVisiveis] pessoas com verbo; o resto abre no lugar.
/// Dia quieto mostra "Tudo em dia" e a saída para crescer.
class HojeAgoraSecao extends ConsumerStatefulWidget {
  const HojeAgoraSecao({super.key, required this.itens, required this.temAluno});

  final List<HojeAgoraItem> itens;
  final bool temAluno;

  @override
  ConsumerState<HojeAgoraSecao> createState() => _HojeAgoraSecaoState();
}

class _HojeAgoraSecaoState extends ConsumerState<HojeAgoraSecao> {
  var _todas = false;

  Future<void> _abrir(HojeAgoraItem item) {
    AnalyticsService.instance.track(
      ProductEvents.hojeAgoraAberto,
      props: {'verbo': item.verbo.name},
    );
    return openDashboardCommandAction(
      context: context,
      ref: ref,
      item: CommandActionItem(
        icon: 'zap',
        title: item.titulo,
        subtitle: item.motivo,
        route: item.rota,
        tone: CommandActionTone.primary,
        actionKey: item.actionKey,
      ),
      source: 'hoje_agora',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final itens = widget.itens;
    final excedente = itens.length - kHojeAgoraVisiveis;
    final visiveis = _todas || excedente <= 0
        ? itens
        : itens.take(kHojeAgoraVisiveis).toList(growable: false);

    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: s.hojePersonalAgora,
            actionLabel: excedente <= 0
                ? null
                : _todas
                ? s.hojeVerMenos
                : s.hojeVerTodas(itens.length),
            onAction: excedente <= 0 ? null : () => setState(() => _todas = !_todas),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          if (itens.isEmpty) ...[
            FxTapRow(
              title: s.hojePersonalEmDiaTitulo,
              subtitle: s.hojePersonalEmDiaFrase,
              leading: const Icon(Icons.check_circle_outline_rounded),
              trailing: const SizedBox.shrink(),
              onTap: null,
            ),
            if (widget.temAluno) ...[
              const SizedBox(height: FxSettingsLayout.headerToGroup),
              FxTapRow(
                title: s.hojeConvidarAluno,
                vazio: true,
                onTap: () => openPersonalRoute(context, '/alunos/novo'),
              ),
            ],
          ] else
            for (final (i, item) in visiveis.indexed) ...[
              if (i > 0) const SizedBox(height: TokensStrip.s2),
              FxActionRow(
                titulo: item.titulo,
                motivo: item.motivo,
                verbo: item.rotulo,
                onTap: () => _abrir(item),
              ),
            ],
        ],
      ),
    );
  }
}
