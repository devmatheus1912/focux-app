import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_ferramentas_mini_sparkline.dart';
import 'aluno360_help_sheets.dart';

/// Módulos Ferramentas no first paint — header + satellite (S3).
class Aluno360FerramentasModulesGrid extends ConsumerWidget {
  const Aluno360FerramentasModulesGrid({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.primary,
    required this.perfilCompletion,
    this.bf,
    this.massaMagra,
    this.aderenciaSemanal,
  });

  final Aluno aluno;
  final int alunoId;
  final Color primary;
  final int perfilCompletion;
  final String? bf;
  final String? massaMagra;
  final List<Map<String, dynamic>>? aderenciaSemanal;

  void _openGated(
    BuildContext context, {
    required Aluno360FerramentasGatedModule module,
    required String featureName,
    required bool locked,
    required VoidCallback onUnlocked,
  }) {
    if (locked) {
      UpgradePromptSheet.show(
        context: context,
        featureName: featureName,
        capability: Aluno360FerramentasLogic.gatedModuleCapability(module),
      );
      return;
    }
    onUnlocked();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evolucaoRoute = '/alunos/$alunoId/evolucao';
    final features = effectivePlanoFeatures(ref);
    final iaLocked = Aluno360FerramentasLogic.isGatedModuleLocked(
      features: features,
      module: Aluno360FerramentasGatedModule.iaProgresso,
    );
    final feedbackLocked = Aluno360FerramentasLogic.isGatedModuleLocked(
      features: features,
      module: Aluno360FerramentasGatedModule.feedbackVideo,
    );
    final aderenciaPercent = (aluno.aderenciaPercent ?? 0).toDouble();
    final composicaoPending = Aluno360FerramentasLogic.composicaoCorporalPending(
      bf: bf,
      massaMagra: massaMagra,
    );
    final aderenciaAttention = Aluno360FerramentasLogic.aderenciaNeedsAttention(
      aluno: aluno,
      aderenciaSemanal: aderenciaSemanal,
    );
    final sparklineValues = Aluno360FerramentasLogic.aderenciaSparklineValues(
      aderenciaSemanal,
    );
    final sparklineSemantics =
        Aluno360FerramentasLogic.aderenciaSparkSemanticsLabel(
          aderenciaSemanal,
        );
    final iaPlan = Aluno360FerramentasLogic.gatedModulePlanLabel(
      Aluno360FerramentasGatedModule.iaProgresso,
    );
    final feedbackPlan = Aluno360FerramentasLogic.gatedModulePlanLabel(
      Aluno360FerramentasGatedModule.feedbackVideo,
    );

    return KeyedSubtree(
      key: const ValueKey('aluno360_ferramentas_modulos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Treino & evolução',
            actionLabel: 'Ajuda',
            onAction: () => showAluno360FerramentasHelpSheet(context),
          ),
          Text(
            Aluno360FerramentasLogic.treinoCaption,
            style: Aluno360Layout.metaStyle(context),
          ),
          const SizedBox(height: TokensStrip.s3),
          FxSatelliteListTile(
            title: 'Treinos',
            subtitle: Text(
              aluno.diasSemTreino == null
                  ? 'Histórico completo'
                  : aluno.diasSemTreino! >= 7
                  ? '${aluno.diasSemTreino} dias sem treino'
                  : 'Ativo recentemente',
            ),
            accent: primary,
            onTap:
                () => context.push(
                  '/alunos/$alunoId/treinos-list',
                  extra: aluno.nome,
                ),
          ),
          FxSatelliteListTile(
            title: 'Equipamentos',
            subtitle: Text(
              aluno.equipamentosDisponiveis.isEmpty
                  ? 'Sem restrição cadastrada'
                  : '${aluno.equipamentosDisponiveis.length} marcados',
            ),
            accent: primary,
            onTap: () => context.push('/alunos/$alunoId/equipamentos'),
          ),
          FxSatelliteListTile(
            title: 'IA Progresso',
            subtitle: Text(
              iaLocked ? 'Disponível no $iaPlan' : 'Carga sugerida pela IA',
            ),
            leading: Icon(
              iaLocked ? Icons.lock_outline : Icons.auto_awesome_outlined,
              color: primary,
            ),
            accent: primary,
            onTap:
                () => _openGated(
                  context,
                  module: Aluno360FerramentasGatedModule.iaProgresso,
                  featureName: 'IA Progresso',
                  locked: iaLocked,
                  onUnlocked:
                      () => context.push(
                        '/alunos/$alunoId/ia/progressao',
                        extra: aluno.nome,
                      ),
                ),
          ),
          FxSatelliteListTile(
            title: 'Composição corporal',
            subtitle: Text(
              bf != null || massaMagra != null
                  ? 'Última avaliação registrada'
                  : 'Registrar medidas',
            ),
            trailing: Text(
              Aluno360FerramentasLogic.composicaoCorporalValue(
                bf: bf,
                massaMagra: massaMagra,
              ),
            ),
            accent: composicaoPending ? EagleTokens.warn : primary,
            onTap: () => context.push(evolucaoRoute, extra: aluno.nome),
          ),
          FxSatelliteListTile(
            title: 'Aderência',
            subtitle: Text(
              Aluno360FerramentasLogic.aderenciaModuleSub(
                aluno: aluno,
                aderenciaSemanal: aderenciaSemanal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sparklineValues.isNotEmpty) ...[
                  Aluno360FerramentasMiniSparkline(
                    data: sparklineValues,
                    color: primary,
                    semanticsLabel: sparklineSemantics,
                  ),
                  const SizedBox(width: TokensStrip.s2),
                ],
                Text('${aderenciaPercent.toInt()}%'),
              ],
            ),
            accent: aderenciaAttention ? EagleTokens.warn : primary,
            onTap:
                () => context.push(
                  '/alunos/$alunoId/relatorio',
                  extra: aluno.nome,
                ),
          ),
          FxSatelliteListTile(
            title: 'Plano de sucesso',
            subtitle: const Text('Metas e marcos do aluno'),
            accent: primary,
            onTap:
                () => context.push(
                  '/alunos/$alunoId/plano-sucesso',
                  extra: aluno.nome,
                ),
          ),
          const SizedBox(height: TokensStrip.s5),
          DashboardSectionHeader(
            title: 'Perfil & gestão',
            actionLabel: 'Ajuda',
            onAction: () => showAluno360FerramentasHelpSheet(context),
          ),
          Text(
            Aluno360FerramentasLogic.perfilCaption,
            style: Aluno360Layout.metaStyle(context),
          ),
          const SizedBox(height: TokensStrip.s3),
          FxSatelliteListTile(
            title: 'Anamnese',
            subtitle: Text(
              perfilCompletion >= 85
                  ? 'Perfil completo'
                  : 'Completar cadastro',
            ),
            trailing: Text(
              Aluno360FerramentasLogic.anamneseValue(perfilCompletion),
            ),
            accent: perfilCompletion < 85 ? EagleTokens.warn : primary,
            onTap: () => context.push('/alunos/$alunoId/anamnese'),
          ),
          FxSatelliteListTile(
            title: 'Mensalidades',
            subtitle: Text(
              aluno.statusFinanceiro == 'INADIMPLENTE'
                  ? 'Pagamento em atraso'
                  : 'Em dia',
            ),
            trailing: Text(
              aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Ação' : 'OK',
            ),
            accent:
                aluno.statusFinanceiro == 'INADIMPLENTE'
                    ? EagleTokens.bad
                    : primary,
            onTap: () => context.push('/financeiro?alunoId=$alunoId'),
          ),
          FxSatelliteListTile(
            title: 'Chat',
            subtitle: const Text('Conversa direta com o aluno'),
            accent: primary,
            onTap:
                () => context.push(
                  '/alunos/$alunoId/chat',
                  extra: aluno.nome,
                ),
          ),
          FxSatelliteListTile(
            title: 'Dieta',
            subtitle: const Text('Plano alimentar atual'),
            accent: primary,
            onTap:
                () => context.push(
                  '/alunos/$alunoId/alimentar',
                  extra: aluno.nome,
                ),
          ),
          FxSatelliteListTile(
            title: 'Feedback em vídeo',
            subtitle: Text(
              feedbackLocked
                  ? 'Disponível no $feedbackPlan'
                  : 'Correções e análise de execução',
            ),
            leading: Icon(
              feedbackLocked ? Icons.lock_outline : Icons.videocam_outlined,
              color: primary,
            ),
            accent: primary,
            onTap:
                () => _openGated(
                  context,
                  module: Aluno360FerramentasGatedModule.feedbackVideo,
                  featureName: 'Feedback em vídeo',
                  locked: feedbackLocked,
                  onUnlocked:
                      () => context.push(
                        '/alunos/$alunoId/feedback-video',
                        extra: aluno.nome,
                      ),
                ),
          ),
        ],
      ),
    );
  }
}
