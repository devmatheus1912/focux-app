import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../auth/utils/auth_layout.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_wizard_chrome.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../onboarding/utils/onboarding_wizard_display.dart';
import '../providers/dashboard_provider.dart';
import '../utils/aluno_activation_display.dart';

class AlunoActivationScreen extends ConsumerWidget {
  const AlunoActivationScreen({super.key});

  Future<void> _markSeen(int alunoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aluno_activation_seen_$alunoId', true);
  }

  Future<void> _sair(BuildContext context, int alunoId) async {
    final leave = await showFxConfirmSheet(
      context,
      title: alunoActivationLeaveTitle(),
      message: alunoActivationLeaveMessage(),
      confirmLabel: alunoActivationLeaveConfirm(),
    );
    if (!leave) return;
    await _markSeen(alunoId);
    if (context.mounted) {
      safePopOrGo(context, '/dashboard/aluno');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(alunoDashboardHomeProvider);

    return homeAsync.when(
      loading:
          () => fxScreenA11yScope(
            label: 'Boas-vindas',
            child: const FxShellScaffold(
              useMesh: true,
              constrainWidth: false,
              appBar: FxShellAppBar(title: 'Boas-vindas'),
              body: SkeletonList(count: 4),
            ),
          ),
      error:
          (e, _) => fxScreenA11yScope(
            label: 'Boas-vindas',
            child: FxShellScaffold(
              useMesh: true,
              constrainWidth: false,
              appBar: const FxShellAppBar(title: 'Boas-vindas'),
              body: FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                title: FocuxMicrocopy.naoFoiPossivelCarregar,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(alunoDashboardHomeProvider),
              ),
            ),
          ),
      data: (home) {
        final aluno = home.aluno;
        final progress = alunoActivationProgress(
          profileCompletion: alunoActivationProfileCompletion(
            telefone: aluno.telefone,
            whatsapp: aluno.whatsapp,
            objetivo: aluno.objetivo,
            genero: aluno.genero,
            peso: aluno.peso?.toString(),
            altura: aluno.altura?.toString(),
            dataNascimento: aluno.dataNascimento,
            fotoUrl: aluno.fotoUrl,
          ),
          hasMedidas: home.medidas.isNotEmpty,
          hasTreinoConcluido: home.historico.any(
            (item) => item.status.toUpperCase() == 'CONCLUIDO',
          ),
          hasChat: home.chat.possuiMensagemDoAluno,
        );
        final step = progress.current;

        return FxWizardPopGuard(
          onLeave: () => _sair(context, aluno.id),
          child: fxScreenA11yScope(
            label: 'Boas-vindas',
            child: FxShellScaffold(
              useMesh: true,
              constrainWidth: false,
              appBar: FxShellAppBar(
                title: 'Boas-vindas',
                subtitle: progress.etapaLabel,
                leadingWidth: 108,
                leading: TextButton(
                  onPressed: () => _sair(context, aluno.id),
                  style: TextButton.styleFrom(
                    foregroundColor: chrome.mute,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    wizardFazerDepoisLabel(),
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: FxWizardStickyBar(
                primary: FxLiquidPrimaryButton(
                  icon: Icons.arrow_forward,
                  label:
                      progress.allDone
                          ? 'Entrar no app'
                          : step.cta,
                  onPressed: () async {
                    await _markSeen(aluno.id);
                    if (!context.mounted) return;
                    if (progress.allDone) {
                      safePopOrGo(context, '/dashboard/aluno');
                    } else {
                      context.go(step.route);
                    }
                  },
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s5,
                ),
                children: [
                  Center(
                    child: FxConversionLockup(
                      width: authLogoWidthFor(context, withTagline: true),
                      semanticLabel: 'Focux ALUNO',
                      aluno: true,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  FxWizardStepDots(
                    current: progress.allDone
                        ? progress.totalCount
                        : (progress.doneCount + 1).clamp(
                          1,
                          progress.totalCount,
                        ),
                    total: progress.totalCount,
                    color: primary,
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  Text(
                    'Olá, ${aluno.nome.split(' ').first}',
                    style: FocuxHubTypography.pageTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  Text(
                    progress.allDone
                        ? FocuxBrandCopy.alunoActivationReadyTitle
                        : alunoActivationQuestion(allDone: false),
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  Text(
                    progress.allDone
                        ? FocuxBrandCopy.alunoActivationReadyBody
                        : step.description,
                    style: FocuxHubTypography.bodyMuted(
                      color: chrome.mute,
                    ),
                  ),
                  if (!progress.allDone) ...[
                    const SizedBox(height: TokensStrip.s4),
                    Text(
                      step.title,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
