import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../perfil/utils/lgpd_consent_display.dart';
import '../../perfil/widgets/perfil_lgpd_consent_sheet.dart';
import '../../perfil/widgets/perfil_sticky_bar.dart';
import '../utils/aluno_confirm_logout.dart';
import '../utils/aluno_delete_account.dart';
import '../utils/aluno_perfil_completion.dart';

class PerfilAlunoHubBody extends ConsumerWidget {
  const PerfilAlunoHubBody({super.key, required this.home});

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
                      value: '$score%',
                      mute: chrome.mute,
                      line: chrome.line,
                      onTap: () => context.push('/aluno/perfil/editar'),
                    ),
                    FxSettingsTile(
                      icon: Icons.fact_check_outlined,
                      label: 'Consentimentos',
                      value: 'LGPD',
                      mute: chrome.mute,
                      line: chrome.line,
                      onTap: () => showPerfilLgpdConsentSheet(
                        context,
                        tipos: lgpdConsentTiposAluno,
                      ),
                    ),
                    FxSettingsTile(
                      icon: Icons.assignment_outlined,
                      label: 'Anamnese',
                      value: 'Saúde',
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
                index: 2,
                child: FxSettingsGroup(
                  children: [
                    FxSettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Sair da conta',
                      value: '',
                      mute: chrome.mute,
                      line: chrome.line,
                      danger: true,
                      onTap: () => confirmAlunoLogout(context, ref),
                    ),
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
