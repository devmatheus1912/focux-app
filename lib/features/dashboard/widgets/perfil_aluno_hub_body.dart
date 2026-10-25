import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../perfil/utils/lgpd_consent_display.dart';
import '../../perfil/widgets/perfil_lgpd_consent_sheet.dart';
import '../../alunos/data/aluno_home_models.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../utils/aluno_confirm_logout.dart';
import '../utils/aluno_delete_account.dart';
import '../utils/aluno_perfil_completion.dart';
import 'perfil_aluno_completar_card.dart';

/// Identidade e conta. As ferramentas moram em `/aluno/ferramentas`, abertas
/// pela Hoje.
class PerfilAlunoHubBody extends ConsumerWidget {
  const PerfilAlunoHubBody({super.key, required this.home});

  final AlunoPerfilHomeBundle home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final aluno = home.aluno;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.softened(primary);
    final score = home.completionPercent ?? alunoPerfilCompletionScore(aluno);
    final photo = aluno.fotoUrl?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;
    final raio = FxSettingsLayout.avatarSize / 2;
    void editar() => context.push('/aluno/perfil/editar');

    return RefreshIndicator(
      color: accent,
      onRefresh: () async => ref.invalidate(alunoPerfilHomeProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          FxSettingsLayout.pageInset,
          FxSettingsLayout.pageInset,
          FxSettingsLayout.groupGap * 2,
        ),
        children: [
          FxStaggerItem(
            index: 0,
            child: Column(
              children: [
                Semantics(
                  button: true,
                  label: s.alunoPerfilEditar,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: editar,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: chrome.brand, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: raio,
                        backgroundImage: hasPhoto
                            ? fxCachedNetworkImageProvider(
                                photo,
                                maxWidth:
                                    (FxSettingsLayout.avatarSize * 3).round(),
                              )
                            : null,
                        backgroundColor: BrandPalette.soft(
                          primary,
                          dark: chrome.isDark,
                        ),
                        child: hasPhoto
                            ? null
                            : Text(
                                aluno.nome.isNotEmpty
                                    ? aluno.nome[0].toUpperCase()
                                    : 'A',
                                style: FxSettingsLayout.avatarInitials(
                                  color: chrome.ink,
                                ),
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
                  style: FxSettingsLayout.profileName(context, color: chrome.ink),
                ),
                if (aluno.email.trim().isNotEmpty) ...[
                  const SizedBox(height: TokensStrip.s1),
                  Text(
                    aluno.email,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: perfilAlunoEmailStyle(chrome),
                  ),
                ],
                const SizedBox(height: TokensStrip.s4),
              ],
            ),
          ),
          if (score < 100) ...[
            FxStaggerItem(
              index: 1,
              child: PerfilAlunoCompletarCard(
                score: score,
                queFalta: queFaltaNoPerfil(s, aluno),
                onTap: editar,
              ),
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
          ],
          FxStaggerItem(
            index: 2,
            child: FxSettingsGroup(
              header: s.alunoPerfilGrupoConta,
              children: [
                FxSettingsTile(
                  icon: Icons.badge_outlined,
                  label: s.alunoPerfilEditar,
                  subtitle: s.alunoPerfilEditarDetalhe,
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  onTap: editar,
                ),
                FxSettingsTile(
                  icon: Icons.fact_check_outlined,
                  label: s.alunoPerfilConsentimentos,
                  subtitle: s.alunoPerfilConsentimentosDetalhe,
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  showDivider: false,
                  onTap: () => showPerfilLgpdConsentSheet(
                    context,
                    tipos: lgpdConsentTiposAluno,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxStaggerItem(
            index: 3,
            child: FxSettingsGroup(
              header: s.alunoPerfilGrupoSaude,
              children: [
                FxSettingsTile(
                  icon: Icons.assignment_outlined,
                  label: s.alunoPerfilAnamnese,
                  subtitle: s.alunoPerfilAnamneseDetalhe,
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
            index: 4,
            child: FxSettingsGroup(
              children: [
                FxSettingsTile(
                  icon: Icons.logout_rounded,
                  label: s.alunoPerfilSair,
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  danger: true,
                  onTap: () => confirmAlunoLogout(context, ref),
                ),
                FxSettingsTile(
                  icon: Icons.delete_forever_outlined,
                  label: s.alunoPerfilExcluir,
                  subtitle: s.alunoPerfilExcluirDetalhe,
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
    );
  }
}
