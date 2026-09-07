import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../perfil/widgets/perfil_sticky_bar.dart';
import '../utils/aluno_delete_account.dart';
import '../utils/aluno_perfil_completion.dart';

class PerfilAlunoScreen extends ConsumerWidget {
  const PerfilAlunoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(alunoPerfilHomeProvider);
    final chrome = ShellChrome.of(context);
    final accent = BrandPalette.softened(Theme.of(context).colorScheme.primary);

    return fxScreenA11yScope(
      label: 'Meu perfil',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Meu perfil',
          subtitle: FxHubFreshness.fromFetchedAt(homeAsync.valueOrNull?.fetchedAt),
        ),
        body: homeAsync.when(
          loading: () => const SkeletonList(count: 4),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: accent,
                message: friendlyError(e),
                title: FocuxMicrocopy.naoFoiPossivelCarregar,
                onRetry: () => ref.invalidate(alunoPerfilHomeProvider),
              ),
          data: (home) => _PerfilAlunoHubBody(home: home),
        ),
      ),
    );
  }
}

class _PerfilAlunoHubBody extends ConsumerWidget {
  const _PerfilAlunoHubBody({required this.home});

  final AlunoPerfilHomeBundle home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aluno = home.aluno;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.softened(primary);
    final score = home.completionPercent ?? alunoPerfilCompletionScore(aluno);
    final photo = aluno.fotoUrl?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Stack(
      children: [
        RefreshIndicator(
          color: accent,
          onRefresh: () async => ref.invalidate(alunoPerfilHomeProvider),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              FxSettingsLayout.pageInset,
              FxSettingsLayout.pageInset,
              score < 100 ? TokensStrip.s9 : FxSettingsLayout.groupGap * 2,
            ),
            children: [
              FxStaggerItem(
                index: 0,
                child: Column(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Editar cadastro',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.push('/aluno/perfil/editar'),
                        child: CircleAvatar(
                          radius: FxSettingsLayout.avatarSize / 2,
                          backgroundImage:
                              hasPhoto ? NetworkImage(photo) : null,
                          backgroundColor: BrandPalette.soft(primary),
                          child:
                              hasPhoto
                                  ? null
                                  : Text(
                                    aluno.nome.isNotEmpty
                                        ? aluno.nome[0].toUpperCase()
                                        : 'A',
                                    style: FxSettingsLayout.avatarInitials(
                                      color: primary,
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    Text(
                      aluno.nome,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FxSettingsLayout.profileName(
                        context,
                        color: chrome.ink,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      '$score%',
                      textAlign: TextAlign.center,
                      style: FxSettingsLayout.rowMetric(color: chrome.mute),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                  ],
                ),
              ),
              FxStaggerItem(
                index: 1,
                child: FxSettingsGroup(
                  header: 'Conta',
                  children: [
                    FxSettingsTile(
                      icon: Icons.badge_outlined,
                      label: 'Editar cadastro',
                      value: '',
                      mute: chrome.mute,
                      line: chrome.line,
                      showDivider: false,
                      onTap: () => context.push('/aluno/perfil/editar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
              FxStaggerItem(
                index: 2,
                child: FxSettingsGroup(
                  header: 'Saúde',
                  children: [
                    FxSettingsTile(
                      icon: Icons.assignment_outlined,
                      label: 'Anamnese',
                      value: '',
                      mute: chrome.mute,
                      line: chrome.line,
                      showDivider: false,
                      onTap: () => context.push('/aluno/anamnese'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
              FxStaggerItem(
                index: 3,
                child: FxSettingsGroup(
                  children: [
                    FxSettingsTile(
                      icon: Icons.delete_forever_outlined,
                      label: 'Excluir minha conta',
                      value: '',
                      mute: chrome.mute,
                      line: chrome.line,
                      danger: true,
                      showDivider: false,
                      onTap: () => confirmDeleteAlunoAccount(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (score < 100)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: PerfilStickyBar(
                accent: accent,
                isDark: chrome.isDark,
                visible: true,
                onComplete: () => context.push('/aluno/perfil/editar'),
              ),
            ),
          ),
      ],
    );
  }
}
