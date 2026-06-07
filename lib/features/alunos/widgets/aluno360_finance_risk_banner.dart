import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../constants/aluno_360_layout.dart';

/// Finance delinquency banner on the Operação tab.
class Aluno360FinanceRiskBanner extends StatelessWidget {
  const Aluno360FinanceRiskBanner({
    super.key,
    required this.alunoId,
    required this.isDark,
  });

  final int alunoId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    return Semantics(
      button: true,
      label: 'Pendência financeira. Abrir mensalidades deste aluno',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/financeiro?alunoId=$alunoId'),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: EagleTokens.bad.withValues(alpha: isDark ? 0.16 : 0.08),
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_outlined, color: EagleTokens.bad, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendência financeira',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          'Abrir mensalidades deste aluno',
                          style: Aluno360Layout.captionStyle(context).copyWith(
                            color: mute,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
