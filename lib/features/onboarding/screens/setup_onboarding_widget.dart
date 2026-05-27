import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../providers/onboarding_provider.dart';
import '../../perfil/providers/perfil_provider.dart';

class SetupOnboardingWidget extends ConsumerWidget {
  const SetupOnboardingWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(onboardingStatusProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkSoft;

    return statusAsync.when(
      loading: () => _ActivationSkeleton(isDark: isDark, primary: primary),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.ativacaoCompleta) return const SizedBox.shrink();

        final progress = data.progressoExibido;
        final feitos = data.etapasFeitas;
        final total = data.etapasTotal;

        return Container(
          margin: const EdgeInsets.only(bottom: TokensStrip.s4),
          padding: const EdgeInsets.all(TokensStrip.s4),
          decoration: fxStripCardDecoration(
            context,
            accent: primary,
            radius: TokensStrip.rCard,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sua ativação',
                    style: TokensStrip.h2(
                      color: primary,
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                    ),
                  ),
                  Text(
                    '$progress%',
                    style: TokensStrip.body(
                      color: primary,
                      fontFamily:
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                '$feitos de $total passos · complete para liberar todo o fluxo.',
                style: TokensStrip.bodyMuted(color: mute),
              ),
              const SizedBox(height: TokensStrip.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rInput),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  color: primary,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _StepTile(
                title: 'Configure seu perfil',
                isDone: data.perfilCompleto,
                onTap: () async {
                  try {
                    final perfil = await ref.read(perfilProvider.future);
                    if (context.mounted) {
                      context.push('/perfil/editar', extra: perfil);
                    }
                  } catch (_) {
                    if (context.mounted) context.push('/perfil');
                  }
                },
              ),
              _StepTile(
                title: 'Adicione o primeiro aluno',
                isDone: data.primeiroAlunoAdicionado,
                onTap: () => context.push('/alunos/novo'),
              ),
              _StepTile(
                title: 'Crie um treino',
                isDone: data.primeiroTreinoCriado,
                onTap: () => context.push('/treinos/novo'),
              ),
              _StepTile(
                title: 'Monte seu primeiro pacote',
                isDone: data.pacoteCriado,
                onTap: () => context.push('/pacotes'),
              ),
              _StepTile(
                title: 'Configure hábitos',
                isDone: data.habitoConfigurado,
                onTap: () => context.push('/habitos'),
              ),
              _StepTile(
                title: 'Configure pagamentos',
                isDone: data.pagamentoConfigurado,
                onTap: () => context.push('/perfil/wallet'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActivationSkeleton extends StatelessWidget {
  const _ActivationSkeleton({required this.isDark, required this.primary});

  final bool isDark;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight = isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        margin: const EdgeInsets.only(bottom: TokensStrip.s4),
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 3; i++) ...[
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String title;
  final bool isDone;
  final VoidCallback onTap;

  const _StepTile({
    required this.title,
    required this.isDone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkSoft;
    final doneColor = isDark
        ? TokensStrip.badgeSuccess.withValues(alpha: 0.85)
        : TokensStrip.badgeSuccess;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDone ? null : onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rInput),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      isDone
                          ? TokensStrip.badgeSuccessBg
                          : primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDone
                            ? TokensStrip.badgeSuccess.withValues(alpha: 0.45)
                            : primary.withValues(alpha: 0.28),
                  ),
                ),
                child: Center(
                  child:
                      isDone
                          ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: doneColor,
                          )
                          : Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: mute, width: 1.6),
                            ),
                          ),
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDone ? doneColor : ink,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!isDone)
                FxIcon(name: 'chevron-right', size: 14, color: mute),
            ],
          ),
        ),
      ),
    );
  }
}
