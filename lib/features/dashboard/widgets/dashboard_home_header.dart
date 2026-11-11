import '../../../core/theme/tokens_strip.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import '../constants/dashboard_layout.dart';
import '../utils/dashboard_microcopy.dart';
import '../utils/dashboard_readability.dart';
import '../utils/dashboard_screen_helpers.dart';
import 'dashboard_header_profile_avatar.dart';
import '../../../core/theme/fx_icons.dart';

/// Header Home 10/10 — identidade limpa + chrome soft; «Foco» só no banner.
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({
    super.key,
    required this.nomePersonal,
    required this.logoUrl,
    required this.isDark,
    required this.primary,
    required this.onProfileTap,
    this.notificacoesCountOverride,
    this.onQuickSearch,
    this.freshnessLabel,
    this.onCopiloto,
  });

  final String? nomePersonal;
  final String? logoUrl;
  final bool isDark;
  final Color primary;
  final VoidCallback onProfileTap;
  final int? notificacoesCountOverride;
  final VoidCallback? onQuickSearch;
  final String? freshnessLabel;

  /// Abre a caixa de entrada; o selo mostra as conversas sem resposta.
  /// Botão do Copiloto de IA no topo (era Conversas, que virou aba).
  final VoidCallback? onCopiloto;

  static const double _chrome = FxHelpChrome.iconSize;
  static const double _chromeGap = FxHelpChrome.gap;

  @override
  Widget build(BuildContext context) {
    final sobre = fxPaletaSobreMarca(context, accent: primary);
    final mute = sobre.mute;
    final firstName = dashboardPersonalFirstName(nomePersonal);
    final fullName = (nomePersonal ?? '').trim();
    final a11yName =
        fullName.isEmpty
            ? dashboardPersonalDisplayName(nomePersonal)
            : fxTitleCaseName(fullName);
    final width = MediaQuery.sizeOf(context).width;
    final compactChrome = DashboardLayout.isCompact(width);
    // Ajuda fica no fim da Hoje ("Como usar a Hoje"): três botões no topo.
    final botoes = _HeaderChromeCluster(
      // <360: busca cai (catálogo/tools cobrem).
      onQuickSearch: compactChrome ? null : onQuickSearch,
      notificacoesCountOverride: notificacoesCountOverride,
      onCopiloto: onCopiloto,
    );
    // Letra do sistema acima de 1,3: os botões descem para a linha de baixo.
    final letraGrande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final freshness =
        (freshnessLabel != null && freshnessLabel!.isNotEmpty)
            ? freshnessLabel!
            : DashboardMicrocopy.painelAtualizado;

    return Padding(
      padding: DashboardLayout.foldFirst,
      child: DecoratedBox(
        decoration: fxMarcaDecoration(
          context,
          accent: primary,
          radius: FxSettingsLayout.groupRadius,
        ),
        child: Theme(
          data: fxTemaSobreMarca(context, accent: primary),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: _ComBotoesEmbaixo(
              mostrar: letraGrande,
              botoes: botoes,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Semantics(
                    button: true,
                    label: '$a11yName. Abrir perfil',
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DashboardHeaderProfileAvatar(
                          primary: primary,
                          isDark: isDark,
                          photoUrl: logoUrl,
                          initials: fxInitials(nomePersonal ?? 'F'),
                          size: 44,
                          onTap: onProfileTap,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: sobre.ink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Linha de identidade, não título: papel de seção (17).
                        // O que se lê primeiro na Hoje é o "Agora".
                        Text(
                          'Olá, $firstName',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.sectionTitle(
                            context,
                            color: sobre.ink,
                          ).copyWith(fontWeight: FontWeight.w600, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            freshness,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: dashboardCardSubtitleStyle(
                              context,
                              isDark: isDark,
                            ).copyWith(color: mute, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!letraGrande) ...[const SizedBox(width: 4), botoes],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderChromeCluster extends StatelessWidget {
  const _HeaderChromeCluster({
    this.onQuickSearch,
    this.notificacoesCountOverride,
    this.onCopiloto,
  });

  /// Botão do Copiloto de IA no topo (era Conversas, que virou aba).
  final VoidCallback? onCopiloto;
  final VoidCallback? onQuickSearch;
  final int? notificacoesCountOverride;

  @override
  Widget build(BuildContext context) {
    const size = DashboardHomeHeader._chrome;
    const gap = DashboardHomeHeader._chromeGap;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onQuickSearch != null) ...[
          ShellHeaderIconButton(
            icon: FxIcons.buscar,
            size: size,
            tooltip: DashboardMicrocopy.buscaRapida,
            onTap: onQuickSearch!,
          ),
          const SizedBox(width: gap),
        ],
        if (onCopiloto != null) ...[
          ShellHeaderIconButton(
            icon: FxIcons.ia,
            size: size,
            tooltip: 'Copiloto de IA',
            onTap: onCopiloto!,
          ),
          const SizedBox(width: gap),
        ],
        NotificacaoBadgeButton(
          size: size,
          countOverride: notificacoesCountOverride,
        ),
      ],
    );
  }
}

class _ComBotoesEmbaixo extends StatelessWidget {
  const _ComBotoesEmbaixo({
    required this.mostrar,
    required this.botoes,
    required this.child,
  });

  final bool mostrar;
  final Widget botoes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!mostrar) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: TokensStrip.s2),
        Align(alignment: AlignmentDirectional.centerEnd, child: botoes),
      ],
    );
  }
}
