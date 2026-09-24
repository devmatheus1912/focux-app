import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../utils/checkin_sessao_aberta.dart';

/// Conflito de sessão aberta — estado de decisão, não de falha.
class CheckinSessaoAbertaState extends StatelessWidget {
  const CheckinSessaoAbertaState({
    super.key,
    required this.sessao,
    required this.onContinuar,
    required this.onDescartar,
    required this.onVoltar,
    this.descartando = false,
  });

  final CheckinSessaoAberta sessao;
  final VoidCallback onContinuar;
  final VoidCallback? onDescartar;
  final VoidCallback onVoltar;
  final bool descartando;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s5,
          vertical: TokensStrip.s4,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 30,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              Semantics(
                header: true,
                child: Text(
                  'Você tem um treino em andamento',
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.body(
                    color: scheme.onSurface,
                  ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                sessao.mensagem,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensStrip.s5),
              FxLiquidPrimaryButton(
                label: 'Continuar treino em andamento',
                icon: Icons.play_arrow_rounded,
                onPressed: descartando ? null : onContinuar,
              ),
              if (onDescartar != null) ...[
                const SizedBox(height: TokensStrip.s3),
                FxLiquidSecondaryButton(
                  label:
                      descartando ? 'Descartando…' : 'Descartar e iniciar este',
                  onPressed: descartando ? null : onDescartar,
                ),
              ],
              const SizedBox(height: TokensStrip.s2),
              TextButton(
                onPressed: descartando ? null : onVoltar,
                child: const Text('Voltar aos treinos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
