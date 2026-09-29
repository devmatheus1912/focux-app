import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/checkin_execucao_display.dart';

class CheckinPreparandoView extends StatelessWidget {
  const CheckinPreparandoView({super.key});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxLoading(color: brand, size: 32),
          const SizedBox(height: TokensStrip.s3),
          Text(
            S.of(context).checkinPreparando,
            style: TextStyle(color: chrome.mute, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CheckinIniciarErroView extends StatelessWidget {
  const CheckinIniciarErroView({
    super.key,
    required this.mensagem,
    required this.onRetry,
    required this.onVoltar,
  });

  final String mensagem;
  final VoidCallback onRetry;
  final VoidCallback onVoltar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final brand = chrome.isDark ? BrandPalette.accent(primary) : primary;
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FxErrorState(
              chromeOnDark: chrome.isDark,
              primary: brand,
              title: s.checkinIniciarErro,
              message: mensagem,
              onRetry: onRetry,
            ),
            TextButton(
              onPressed: onVoltar,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                s.checkinVoltarAosTreinos,
                style: TextStyle(color: chrome.mute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Séries salvas no aparelho esperando rede.
class CheckinPendentesAviso extends StatelessWidget {
  const CheckinPendentesAviso({
    super.key,
    required this.pendentes,
    required this.onTentar,
  });

  final int pendentes;
  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: FxSettingsLayout.pageInset,
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, size: 18, color: chrome.mute),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: Text(
                s.checkinPendentes(pendentes),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
            TextButton(
              onPressed: onTentar,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(s.checkinPendentesTentar),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rodapé fixo na zona do polegar: a próxima ação do treino.
class CheckinRodapeBar extends StatelessWidget {
  const CheckinRodapeBar({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s2,
          TokensStrip.s4,
          TokensStrip.s3,
        ),
        // Soma de padding + botão = checkinRodapeReserva.
        child: SizedBox(
          height: checkinExecutionControlMin,
          child: Semantics(
            liveRegion: loading,
            child: FxLiquidPrimaryButton(
              label: label,
              icon: icon,
              onPressed: loading ? null : onPressed,
              loading: loading,
              loadingLabel: loadingLabel,
            ),
          ),
        ),
      ),
    );
  }
}

/// Finalizar com exercício faltando: texto discreto abaixo do card, que
/// confirma antes de encerrar.
class CheckinFinalizarLink extends StatelessWidget {
  const CheckinFinalizarLink({
    super.key,
    required this.concluindo,
    required this.onFinalizar,
  });

  final bool concluindo;
  final VoidCallback onFinalizar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return TextButton(
      onPressed: concluindo ? null : onFinalizar,
      style: TextButton.styleFrom(
        foregroundColor: chrome.mute,
        minimumSize: const Size(double.infinity, checkinExecutionControlMin),
      ),
      child: Text(concluindo ? s.checkinFinalizando : s.checkinFinalizarTreino),
    );
  }
}
