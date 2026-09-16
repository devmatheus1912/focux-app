import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_ferramentas_mini_sparkline.dart';
import 'aluno360_help_sheets.dart';

/// Módulos Ferramentas — top-N no fold + overflow em sheet (A30 / v3.1).
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
    this.anamneseStatus,
    this.anamneseLoading = false,
  });

  final Aluno aluno;
  final int alunoId;
  final Color primary;
  final int perfilCompletion;
  final String? bf;
  final String? massaMagra;
  final List<Map<String, dynamic>>? aderenciaSemanal;

  /// From `/360/ferramentas.anamneseResumo.status`. Null = não iniciada.
  final String? anamneseStatus;
  final bool anamneseLoading;

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

  Future<void> _openMaisFerramentas(
    BuildContext context, {
    required List<Aluno360FerramentasModule> overflow,
    required bool isDark,
    required bool iaLocked,
    required bool feedbackLocked,
    required String iaPlan,
    required String feedbackPlan,
  }) async {
    if (overflow.isEmpty) return;
    final treino = overflow
        .where(
          (m) =>
              Aluno360FerramentasLogic.moduleGroup(m) ==
              Aluno360FerramentasModuleGroup.treino,
        )
        .toList(growable: false);
    final perfil = overflow
        .where(
          (m) =>
              Aluno360FerramentasLogic.moduleGroup(m) ==
              Aluno360FerramentasModuleGroup.perfil,
        )
        .toList(growable: false);

    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(context).height *
              FxHomeSheetChrome.maxHeightFactor,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: 8),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Mais ferramentas',
                subtitle: 'Catálogo completo deste aluno',
                leading: Icon(Icons.apps_outlined, color: primary, size: 20),
              ),
              const SizedBox(height: TokensStrip.s3),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (treino.isNotEmpty) ...[
                        Text(
                          'Treino & evolução',
                          style: Aluno360Layout.metaStyle(ctx).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        for (final module in treino)
                          _moduleTile(
                            context,
                            sheetContext: ctx,
                            module: module,
                            iaLocked: iaLocked,
                            feedbackLocked: feedbackLocked,
                            iaPlan: iaPlan,
                            feedbackPlan: feedbackPlan,
                          ),
                      ],
                      if (perfil.isNotEmpty) ...[
                        if (treino.isNotEmpty)
                          const SizedBox(height: TokensStrip.s4),
                        Text(
                          'Perfil & gestão',
                          style: Aluno360Layout.metaStyle(ctx).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        for (final module in perfil)
                          _moduleTile(
                            context,
                            sheetContext: ctx,
                            module: module,
                            iaLocked: iaLocked,
                            feedbackLocked: feedbackLocked,
                            iaPlan: iaPlan,
                            feedbackPlan: feedbackPlan,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _moduleTile(
    BuildContext host, {
    BuildContext? sheetContext,
    required Aluno360FerramentasModule module,
    required bool iaLocked,
    required bool feedbackLocked,
    required String iaPlan,
    required String feedbackPlan,
  }) {
    void go(VoidCallback action) {
      HapticFeedback.selectionClick();
      final sheet = sheetContext;
      if (sheet != null) {
        Navigator.of(sheet).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (host.mounted) action();
        });
        return;
      }
      action();
    }

    final evolucaoComparativo = '/alunos/$alunoId/evolucao-comparativo';
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

    return switch (module) {
      Aluno360FerramentasModule.treinos => FxSatelliteListTile(
        titleCase: false,
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
            () => go(
              () => host.push(
                '/alunos/$alunoId/treinos-list',
                extra: aluno.nome,
              ),
            ),
      ),
      Aluno360FerramentasModule.equipamentos => FxSatelliteListTile(
        titleCase: false,
        title: 'Equipamentos',
        subtitle: Text(
          aluno.equipamentosDisponiveis.isEmpty
              ? 'Sem restrição cadastrada'
              : '${aluno.equipamentosDisponiveis.length} marcados',
        ),
        accent: primary,
        onTap: () => go(() => host.push('/alunos/$alunoId/equipamentos')),
      ),
      Aluno360FerramentasModule.iaProgresso => FxSatelliteListTile(
        titleCase: false,
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
            () => go(
              () => _openGated(
                host,
                module: Aluno360FerramentasGatedModule.iaProgresso,
                featureName: 'IA Progresso',
                locked: iaLocked,
                onUnlocked:
                    () => host.push(
                      '/alunos/$alunoId/ia/progressao',
                      extra: aluno.nome,
                    ),
              ),
            ),
      ),
      Aluno360FerramentasModule.composicao => FxSatelliteListTile(
        titleCase: false,
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
        onTap:
            () => go(
              () => host.push(evolucaoComparativo, extra: aluno.nome),
            ),
      ),
      Aluno360FerramentasModule.aderencia => FxSatelliteListTile(
        titleCase: false,
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
            () => go(
              () => host.push(
                '/alunos/$alunoId/relatorio',
                extra: aluno.nome,
              ),
            ),
      ),
      Aluno360FerramentasModule.planoSucesso => FxSatelliteListTile(
        titleCase: false,
        title: 'Plano de sucesso',
        subtitle: const Text('Metas e marcos do aluno'),
        accent: primary,
        onTap:
            () => go(
              () => host.push(
                '/alunos/$alunoId/plano-sucesso',
                extra: aluno.nome,
              ),
            ),
      ),
      Aluno360FerramentasModule.trilhas => FxSatelliteListTile(
        titleCase: false,
        title: 'Trilhas',
        subtitle: const Text('Metas com etapas e progresso'),
        accent: primary,
        onTap:
            () => go(
              () => host.push(
                '/alunos/$alunoId/trilhas',
                extra: aluno.nome,
              ),
            ),
      ),
      Aluno360FerramentasModule.engajamento => FxSatelliteListTile(
        titleCase: false,
        title: 'Engajamento',
        subtitle: const Text('Treinos, medidas e mensagens'),
        accent: primary,
        onTap:
            () => go(
              () => host.push(
                '/alunos/$alunoId/engajamento',
                extra: aluno.nome,
              ),
            ),
      ),
      Aluno360FerramentasModule.anamnese => FxSatelliteListTile(
        titleCase: false,
        title: 'Anamnese',
        subtitle: Text(
          anamneseLoading
              ? 'Carregando ficha…'
              : Aluno360FerramentasLogic.anamneseSubtitle(anamneseStatus),
        ),
        trailing: Text(
          anamneseLoading
              ? '…'
              : Aluno360FerramentasLogic.anamneseValue(anamneseStatus),
        ),
        accent:
            anamneseLoading
                ? primary
                : (Aluno360FerramentasLogic.anamneseNeedsAttention(
                      anamneseStatus,
                    )
                    ? EagleTokens.warn
                    : primary),
        onTap: () => go(() => host.push('/alunos/$alunoId/anamnese')),
      ),
      Aluno360FerramentasModule.mensalidades => FxSatelliteListTile(
        titleCase: false,
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
        onTap: () => go(() => host.push('/financeiro?alunoId=$alunoId')),
      ),
      Aluno360FerramentasModule.chat => FxSatelliteListTile(
        titleCase: false,
        title: 'Chat',
        subtitle: const Text('Conversa direta com o aluno'),
        accent: primary,
        onTap:
            () => go(
              () => host.push(
                '/alunos/$alunoId/chat',
                extra: aluno.nome,
              ),
            ),
      ),
      Aluno360FerramentasModule.feedbackVideo => FxSatelliteListTile(
        titleCase: false,
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
            () => go(
              () => _openGated(
                host,
                module: Aluno360FerramentasGatedModule.feedbackVideo,
                featureName: 'Feedback em vídeo',
                locked: feedbackLocked,
                onUnlocked:
                    () => host.push(
                      '/alunos/$alunoId/feedback-video',
                      extra: aluno.nome,
                    ),
              ),
            ),
      ),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final features = effectivePlanoFeatures(ref);
    final iaLocked = Aluno360FerramentasLogic.isGatedModuleLocked(
      features: features,
      module: Aluno360FerramentasGatedModule.iaProgresso,
    );
    final feedbackLocked = Aluno360FerramentasLogic.isGatedModuleLocked(
      features: features,
      module: Aluno360FerramentasGatedModule.feedbackVideo,
    );
    final iaPlan = Aluno360FerramentasLogic.gatedModulePlanLabel(
      Aluno360FerramentasGatedModule.iaProgresso,
    );
    final feedbackPlan = Aluno360FerramentasLogic.gatedModulePlanLabel(
      Aluno360FerramentasGatedModule.feedbackVideo,
    );
    final split = Aluno360FerramentasLogic.splitModulesForFold(
      aluno: aluno,
      bf: bf,
      massaMagra: massaMagra,
      anamneseStatus: anamneseStatus,
      aderenciaSemanal: aderenciaSemanal,
    );

    return KeyedSubtree(
      key: const ValueKey('aluno360_ferramentas_modulos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(
            title: 'Atalhos do aluno',
            actionLabel: 'Ajuda',
            onAction: () => showAluno360FerramentasHelpSheet(context),
          ),
          Text(
            Aluno360FerramentasLogic.treinoCaption,
            style: Aluno360Layout.metaStyle(context),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (final module in split.fold)
            _moduleTile(
              context,
              module: module,
              iaLocked: iaLocked,
              feedbackLocked: feedbackLocked,
              iaPlan: iaPlan,
              feedbackPlan: feedbackPlan,
            ),
          if (split.overflow.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: DashboardHomeActionChip(
                label: 'Mais ferramentas',
                accent: primary,
                isDark: isDark,
                onPressed:
                    () => _openMaisFerramentas(
                      context,
                      overflow: split.overflow,
                      isDark: isDark,
                      iaLocked: iaLocked,
                      feedbackLocked: feedbackLocked,
                      iaPlan: iaPlan,
                      feedbackPlan: feedbackPlan,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
