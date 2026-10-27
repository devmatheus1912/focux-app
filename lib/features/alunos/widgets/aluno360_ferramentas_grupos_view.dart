import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../planos/data/plano_recurso.dart';
import '../../recorrencia/providers/recorrencia_provider.dart';
import '../../recorrencia/utils/recorrencia_display.dart';
import '../../recorrencia/widgets/recorrencia_nova_folha.dart';
import '../../planos/utils/effective_plano_features.dart';
import '../../planos/utils/plan_gate.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_grupos.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_ferramentas_mini_sparkline.dart';

String aluno360GrupoTitulo(S s, Aluno360FerramentasGrupo g) => switch (g) {
  Aluno360FerramentasGrupo.treino => s.aluno360FerramentasGrupoTreino,
  Aluno360FerramentasGrupo.acompanhamento =>
    s.aluno360FerramentasGrupoAcompanhamento,
  Aluno360FerramentasGrupo.relacao => s.aluno360FerramentasGrupoRelacao,
  Aluno360FerramentasGrupo.dinheiro => s.aluno360FerramentasGrupoDinheiro,
};

String aluno360GrupoLegenda(S s, Aluno360FerramentasGrupo g) => switch (g) {
  Aluno360FerramentasGrupo.treino => s.aluno360FerramentasGrupoTreinoLegenda,
  Aluno360FerramentasGrupo.acompanhamento =>
    s.aluno360FerramentasGrupoAcompanhamentoLegenda,
  Aluno360FerramentasGrupo.relacao => s.aluno360FerramentasGrupoRelacaoLegenda,
  Aluno360FerramentasGrupo.dinheiro =>
    s.aluno360FerramentasGrupoDinheiroLegenda,
};

/// Todos os módulos do aluno, em grupos. Quem pede atenção leva um selo e
/// o grupo sobe; módulo bloqueado pelo plano mostra o selo do plano.
class Aluno360FerramentasGrupos extends ConsumerWidget {
  const Aluno360FerramentasGrupos({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.primary,
    this.bf,
    this.massaMagra,
    this.aderenciaSemanal,
    this.anamneseStatus,
    this.anamneseLoading = false,
  });

  final Aluno aluno;
  final int alunoId;
  final Color primary;
  final String? bf;
  final String? massaMagra;
  final List<Map<String, dynamic>>? aderenciaSemanal;

  /// De `/360/ferramentas.anamneseResumo.status`. Nulo = não iniciada.
  final String? anamneseStatus;
  final bool anamneseLoading;

  void _upgrade(
    BuildContext context, {
    required Aluno360FerramentasGatedModule module,
    required String featureName,
    required VoidCallback onUnlocked,
    required bool locked,
  }) {
    if (!locked) return onUnlocked();
    UpgradePromptSheet.show(
      context: context,
      featureName: featureName,
      capability: Aluno360FerramentasLogic.gatedModuleCapability(module),
    );
  }

  /// "Recorrência" do grupo Dinheiro: mostra o que existe e cria a partir daqui,
  /// com o aluno já escolhido.
  Widget _linhaRecorrencia(
    BuildContext context,
    WidgetRef ref, {
    required FxSettingsTile Function({
      required String label,
      required String subtitle,
      String value,
      Widget? accessory,
      bool locked,
      String? tier,
      required VoidCallback onTap,
    })
    linha,
    required void Function(String featureName, VoidCallback action) goPlan,
    required bool planLocked,
    required String? tier,
  }) {
    final s = S.of(context);
    final atual = planLocked
        ? null
        : ref
              .watch(
                recorrenciaDoAlunoProvider((
                  alunoId: alunoId,
                  nome: aluno.nome,
                )),
              )
              .value;
    final proxima = atual?.proximaCobranca?.trim() ?? '';
    return linha(
      label: s.alunoRecorrenciaLinha,
      subtitle: atual == null
          ? s.alunoRecorrenciaSubVazio
          : proxima.isEmpty
          ? recorrenciaStatusLabel(atual.status)
          : s.alunoRecorrenciaProxima(recorrenciaProximaValue(proxima)),
      value: atual == null
          ? (planLocked ? '' : s.alunoRecorrenciaNaoCriada)
          : recorrenciaValorLabel(atual.valor),
      locked: planLocked,
      tier: tier,
      onTap: () => goPlan(s.alunoRecorrenciaLinha, () async {
        if (atual != null) {
          context.push('/financeiro?aba=recorrencias');
          return;
        }
        final criou = await showRecorrenciaNovaFolha(
          context,
          ref,
          alunoId: alunoId,
          alunoNome: aluno.nome,
        );
        if (!criou) return;
        ref.invalidate(
          recorrenciaDoAlunoProvider((alunoId: alunoId, nome: aluno.nome)),
        );
        if (context.mounted) {
          FeedbackHelper.showSuccess(context, recorrenciaCriadaMensagem);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
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
    final planLocks = <Aluno360FerramentasModule, (String, PlanoRecurso)>{
      Aluno360FerramentasModule.mensalidades: (
        PlanoRecursoKeys.financeiro,
        PlanGate.watch(ref, PlanoRecursoKeys.financeiro),
      ),
      Aluno360FerramentasModule.recorrencia: (
        PlanoRecursoKeys.recorrencia,
        PlanGate.watch(ref, PlanoRecursoKeys.recorrencia),
      ),
      Aluno360FerramentasModule.aderencia: (
        PlanoRecursoKeys.relatorios,
        PlanGate.watch(ref, PlanoRecursoKeys.relatorios),
      ),
    };
    final secoes = secoesDeFerramentas(
      aluno: aluno,
      anamneseStatus: anamneseStatus,
      bf: bf,
      massaMagra: massaMagra,
      aderenciaSemanal: aderenciaSemanal,
    );

    Widget tile(Aluno360FerramentasModule modulo, {required bool ultimo}) {
      final planLock = planLocks[modulo];
      final planLocked = planLock != null && !planLock.$2.liberado;
      final atencao = aluno360ModuloPedeAtencao(
        modulo,
        aluno: aluno,
        bf: bf,
        massaMagra: massaMagra,
        anamneseStatus: anamneseStatus,
        aderenciaSemanal: aderenciaSemanal,
      );
      FxSettingsTile linha({
        required String label,
        required String subtitle,
        String value = '',
        Widget? accessory,
        bool locked = false,
        String? tier,
        required VoidCallback onTap,
      }) => FxSettingsTile(
        icon: Aluno360FerramentasLogic.moduleIcon(modulo),
        label: label,
        subtitle: subtitle,
        value: value,
        accessory: accessory,
        locked: locked,
        upgradeTierLabel: tier,
        highlight: atencao && !locked,
        mute: chrome.mute,
        line: chrome.line,
        showDivider: !ultimo,
        onTap: onTap,
      );
      void goPlan(String featureName, VoidCallback action) {
        if (!planLocked) return action();
        UpgradePromptSheet.show(
          context: context,
          featureName: featureName,
          capability: planLock.$1,
          requiredPlan: planLock.$2.planoMinimo,
          upgradePlano: planLock.$2.planoMinimo,
          source: 'aluno360_ferramentas',
        );
      }

      final nome = aluno.nome;
      final push = context.push;
      return switch (modulo) {
        Aluno360FerramentasModule.treinos => linha(
          label: 'Treinos',
          subtitle: aluno.diasSemTreino == null
              ? 'Treinos do plano'
              : aluno.diasSemTreino! >= 7
              ? '${aluno.diasSemTreino} dias sem treino'
              : 'Ativo recentemente',
          onTap: () => push('/alunos/$alunoId/treinos-list', extra: nome),
        ),
        Aluno360FerramentasModule.equipamentos => linha(
          label: 'Equipamentos',
          subtitle: aluno.equipamentosDisponiveis.isEmpty
              ? 'Sem restrição cadastrada'
              : '${aluno.equipamentosDisponiveis.length} marcados',
          onTap: () => push('/alunos/$alunoId/equipamentos'),
        ),
        Aluno360FerramentasModule.aderencia => linha(
          label: 'Aderência',
          subtitle: Aluno360FerramentasLogic.aderenciaModuleSub(
            aluno: aluno,
            aderenciaSemanal: aderenciaSemanal,
          ),
          value: aluno360AderenciaValor(aluno),
          accessory:
              Aluno360FerramentasLogic.aderenciaSparklineValues(
                aderenciaSemanal,
              ).isEmpty
              ? null
              : Aluno360FerramentasMiniSparkline(
                  data: Aluno360FerramentasLogic.aderenciaSparklineValues(
                    aderenciaSemanal,
                  ),
                  color: primary,
                  semanticsLabel:
                      Aluno360FerramentasLogic.aderenciaSparkSemanticsLabel(
                        aderenciaSemanal,
                      ),
                ),
          locked: planLocked,
          tier: planLocked ? PlanGate.tierLabel(planLock.$2.planoMinimo) : null,
          onTap: () => goPlan(
            'Relatório de aderência',
            () => push('/alunos/$alunoId/relatorio', extra: nome),
          ),
        ),
        Aluno360FerramentasModule.iaProgresso => linha(
          label: 'IA Progresso',
          subtitle: iaLocked
              ? 'Disponível no $iaPlan'
              : 'Sugestão de carga e progressão',
          locked: iaLocked,
          tier: iaPlan,
          onTap: () => _upgrade(
            context,
            module: Aluno360FerramentasGatedModule.iaProgresso,
            featureName: 'IA Progresso',
            locked: iaLocked,
            onUnlocked: () =>
                push('/alunos/$alunoId/ia/progressao', extra: nome),
          ),
        ),
        Aluno360FerramentasModule.feedbackVideo => linha(
          label: 'Feedback em vídeo',
          subtitle: feedbackLocked
              ? 'Disponível no $feedbackPlan'
              : 'Vídeos do aluno · você responde',
          locked: feedbackLocked,
          tier: feedbackPlan,
          onTap: () => _upgrade(
            context,
            module: Aluno360FerramentasGatedModule.feedbackVideo,
            featureName: 'Feedback em vídeo',
            locked: feedbackLocked,
            onUnlocked: () =>
                push('/alunos/$alunoId/feedback-video', extra: nome),
          ),
        ),
        Aluno360FerramentasModule.composicao => linha(
          label: 'Composição corporal',
          subtitle: composicaoSuspeita(bf: bf, massaMagra: massaMagra)
              ? 'Gordura ${bf ?? '—'}% · Massa magra ${massaMagra ?? '—'} kg'
              : bf != null || massaMagra != null
              ? 'Última avaliação registrada'
              : 'Registrar medidas',
          value: aluno360ComposicaoValor(bf: bf, massaMagra: massaMagra),
          onTap: () =>
              push('/alunos/$alunoId/evolucao-comparativo', extra: nome),
        ),
        Aluno360FerramentasModule.planoSucesso => linha(
          label: 'Plano de sucesso',
          subtitle: 'Metas e marcos do aluno',
          onTap: () => push('/alunos/$alunoId/plano-sucesso', extra: nome),
        ),
        Aluno360FerramentasModule.trilhas => linha(
          label: 'Trilhas',
          subtitle: 'Metas com etapas e progresso',
          onTap: () => push('/alunos/$alunoId/trilhas', extra: nome),
        ),
        Aluno360FerramentasModule.engajamento => linha(
          label: 'Engajamento',
          subtitle: 'Treinos, medidas e mensagens',
          onTap: () => push('/alunos/$alunoId/engajamento', extra: nome),
        ),
        Aluno360FerramentasModule.anamnese => linha(
          label: 'Anamnese',
          subtitle: anamneseLoading
              ? 'Carregando ficha…'
              : Aluno360FerramentasLogic.anamneseSubtitle(anamneseStatus),
          value: anamneseLoading
              ? '…'
              : Aluno360FerramentasLogic.anamneseValue(anamneseStatus),
          onTap: () => push('/alunos/$alunoId/anamnese'),
        ),
        Aluno360FerramentasModule.recorrencia => _linhaRecorrencia(
          context,
          ref,
          linha: linha,
          goPlan: goPlan,
          planLocked: planLocked,
          tier: planLocked ? PlanGate.tierLabel(planLock.$2.planoMinimo) : null,
        ),
        Aluno360FerramentasModule.chat => linha(
          label: 'Chat',
          subtitle: 'Conversa direta com o aluno',
          onTap: () => push('/alunos/$alunoId/chat', extra: nome),
        ),
        Aluno360FerramentasModule.mensalidades => linha(
          label: 'Mensalidades',
          subtitle: atencao ? 'Pagamento em atraso' : 'Em dia',
          value: atencao ? 'Em atraso' : 'OK',
          locked: planLocked,
          tier: planLocked ? PlanGate.tierLabel(planLock.$2.planoMinimo) : null,
          onTap: () => goPlan(
            'Mensalidades',
            () => push('/financeiro?alunoId=$alunoId'),
          ),
        ),
      };
    }

    return KeyedSubtree(
      key: const ValueKey('aluno360_ferramentas_grupos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, secao) in secoes.indexed) ...[
            if (i > 0) const SizedBox(height: FxSettingsLayout.groupGap),
            FxSettingsGroup(
              key: ValueKey('aluno360_grupo_${secao.grupo.name}'),
              header: aluno360GrupoTitulo(s, secao.grupo),
              caption: aluno360GrupoLegenda(s, secao.grupo),
              children: [
                for (final (j, m) in secao.modulos.indexed)
                  tile(m, ultimo: j == secao.modulos.length - 1),
              ],
            ),
          ],
          const SizedBox(height: TokensStrip.s1),
        ],
      ),
    );
  }
}
