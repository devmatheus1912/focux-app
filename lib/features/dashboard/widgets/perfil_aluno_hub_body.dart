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
import '../../../l10n/app_localizations.dart';
import '../../perfil/utils/lgpd_consent_display.dart';
import '../../perfil/widgets/perfil_lgpd_consent_sheet.dart';
import '../../alunos/data/aluno_home_models.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../utils/aluno_confirm_logout.dart';
import '../utils/aluno_delete_account.dart';
import '../utils/aluno_perfil_completion.dart';
import 'perfil_aluno_completar_card.dart';
import 'perfil_progresso_bloco.dart';
import 'perfil_conquistas_linha.dart';
import '../../evolucao/data/meta_corporal.dart';
import '../../evolucao/providers/evolucao_home_provider.dart';
import '../../evolucao/widgets/evolucao_conquistas.dart';
import '../../perfil/widgets/perfil_topo_marca.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../perfil/widgets/perfil_appearance_section.dart';
import '../../perfil/widgets/perfil_sobre_grupo.dart';
import '../../../core/theme/fx_icons.dart';
import '../providers/dashboard_provider.dart';

/// Identidade e conta. As ferramentas moram em `/aluno/ferramentas`, abertas
/// pela Hoje.
class PerfilAlunoHubBody extends ConsumerWidget {
  const PerfilAlunoHubBody({super.key, required this.home});

  final AlunoPerfilHomeBundle home;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final aluno = home.aluno;
    final personal =
        ref
            .watch(alunoDashboardHomeProvider)
            .value
            ?.personalBrand
            .nomePersonal
            .trim();
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.softened(primary);
    final score = home.completionPercent ?? alunoPerfilCompletionScore(aluno);
    final photo = aluno.fotoUrl?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;
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
            child: PerfilTopoMarca(
              nome: aluno.nome,
              fotoUrl: hasPhoto ? photo : null,
              onEditar: editar,
              editarSemantica: s.alunoPerfilEditar,
              linhas: [
                // Com quem treina; o toque abre a conversa (aba Chat).
                if (personal != null && personal.isNotEmpty)
                  _TreinaCom(personal: personal),
              ],
              rodape: _conquistas(context, ref),
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
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
          PerfilProgressoBloco(medidas: home.medidas),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxStaggerItem(
            index: 2,
            child: FxSettingsGroup(
              header: s.alunoPerfilGrupoConta,
              children: [
                FxSettingsTile(
                  icon: FxIcons.cracha,
                  label: s.alunoPerfilEditar,
                  subtitle: s.alunoPerfilEditarDetalhe,
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  onTap: editar,
                ),
                FxSettingsTile(
                  icon: FxIcons.conferir,
                  label: s.alunoPerfilConsentimentos,
                  subtitle: s.alunoPerfilConsentimentosDetalhe,
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  showDivider: false,
                  onTap:
                      () => showPerfilLgpdConsentSheet(
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
                  icon: FxIcons.prancheta,
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
            child: PerfilAppearanceSection(isDark: chrome.isDark),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxStaggerItem(
            index: 5,
            child: PerfilSobreGrupo(mute: chrome.mute, line: chrome.line),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          // Sair e excluir no fim. Sair não apaga nada: sem vermelho, sem seta.
          FxStaggerItem(
            index: 6,
            child: FxSettingsGroup(
              children: [
                FxSettingsTile(
                  icon: FxIcons.sair,
                  label: s.alunoPerfilSair,
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  accessory: const SizedBox.shrink(),
                  onTap: () => confirmAlunoLogout(context, ref),
                ),
                FxSettingsTile(
                  icon: FxIcons.excluir,
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

/// Conquistas do topo; nula sem conquista (o cartão não ganha a linha).
Widget? _conquistas(BuildContext context, WidgetRef ref) {
  final dados = ref.watch(minhaEvolucaoProvider).value;
  if (dados == null) return null;
  final conquistas = conquistasDe(
    dados.metas,
    dados.recordes,
    medidas: dados.medidas,
    gordura: dados.gordura,
    massa: dados.massa,
  );
  if (conquistas.isEmpty) return null;
  return PerfilConquistasLinha(
    conquistas: conquistas,
    onAbrir: (c) => mostrarConquista(context, c, compartilhar: true),
    onVerTodas: () => context.push('/aluno/progresso'),
  );
}

/// "Treina com {personal}" sobre o cartão de marca; o toque abre o chat.
class _TreinaCom extends StatelessWidget {
  const _TreinaCom({required this.personal});

  final String personal;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sobre = fxPaletaSobreMarca(context);
    return Semantics(
      button: true,
      label: s.alunoPerfilConversarCom(personal),
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        onTap: () => context.go('/chat/aluno'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s2,
            vertical: TokensStrip.s1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  s.alunoPerfilTreinaCom(personal),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                ),
              ),
              const SizedBox(width: TokensStrip.s1),
              Icon(FxIcons.chevronDireitaPequeno, size: 14, color: sobre.mute),
            ],
          ),
        ),
      ),
    );
  }
}
