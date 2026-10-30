import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

String _alunoDetailLibrarySource() {
  const dir = 'lib/features/alunos/screens';
  const mainFile = '$dir/aluno_detail_screen.dart';
  const statePartFile = '$dir/aluno_detail_screen_state.part.dart';
  const providersFile =
      'lib/features/alunos/providers/aluno_detail_providers.dart';
  const heroWidgetFile =
      'lib/features/alunos/widgets/aluno_detail_hero_card.dart';
  const heroRiskStyleFile =
      'lib/features/alunos/utils/aluno360_hero_risk_style.dart';
  const operacaoTabFile =
      'lib/features/alunos/widgets/aluno360_resumo_tab.dart';
  const fichaCardFile = 'lib/features/alunos/widgets/aluno360_ficha_card.dart';
  const resumoAgoraFile = 'lib/features/alunos/utils/aluno360_resumo_agora.dart';
  const menuAcoesFile = 'lib/features/alunos/utils/aluno360_menu_acoes.dart';
  const headerWidgetFile =
      'lib/features/alunos/widgets/aluno360_composite_header.dart';
  const operacaoLogicFile =
      'lib/features/alunos/utils/aluno360_operacao_logic.dart';
  const copilotLogicFile =
      'lib/features/alunos/utils/aluno360_copilot_logic.dart';
  const copilotExecutarLogicFile =
      'lib/features/alunos/utils/aluno360_copilot_executar_logic.dart';
  const copilotOutreachLogicFile =
      'lib/features/alunos/utils/aluno360_copilot_outreach_logic.dart';
  const copilotTextLogicFile =
      'lib/features/alunos/utils/aluno360_copilot_text_logic.dart';
  const outreachDisplayFile =
      'lib/features/alunos/utils/aluno_outreach_display.dart';
  const outreachSheetFile =
      'lib/features/alunos/widgets/aluno_outreach_message_sheet.dart';
  const copilotCardFile =
      'lib/features/alunos/widgets/aluno360_copilot_card.dart';
  const copilotSupportFile =
      'lib/features/alunos/widgets/aluno360_copilot_support.dart';
  const stickyCtaFile =
      'lib/features/alunos/widgets/aluno360_acao_sticky.dart';
  const followUpFile =
      'lib/features/alunos/widgets/aluno360_follow_up_card.dart';
  const commitmentSheetFile =
      'lib/features/alunos/widgets/aluno360_commitment_sheet.dart';
  const ferramentasModulesFile =
      'lib/features/alunos/widgets/aluno360_ferramentas_grupos_view.dart';
  const timelineCardFile =
      'lib/features/alunos/widgets/aluno360_timeline_card.dart';
  const insetEmptyActionsFile =
      'lib/features/alunos/widgets/aluno360_inset_empty_actions.dart';
  const alunoActionsFile =
      'lib/features/alunos/utils/aluno_detail_aluno_actions.dart';
  const deleteConfirmSheetFile =
      'lib/features/alunos/widgets/aluno_delete_confirm_sheet.dart';
  const evolucaoCardFile =
      'lib/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart';
  const profileGapsSheetFile =
      'lib/features/alunos/widgets/aluno360_copilot_profile_gaps_sheet.dart';
  const copilotTaskActionsFile =
      'lib/features/alunos/utils/aluno360_copilot_task_actions.dart';
  const executarButtonFile =
      'lib/features/alunos/widgets/aluno360_copilot_executar_button.dart';
  const iaRepositoryFile = 'lib/features/ia/data/ia_repository.dart';
  const detailEvolucaoTabFile =
      'lib/features/alunos/widgets/aluno360_detail_evolucao_tab.dart';
  const detailFerramentasTabFile =
      'lib/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';
  const recoveryInsightFile =
      'lib/features/alunos/widgets/aluno360_recovery_insight_card.dart';
  const weightActivityFile =
      'lib/features/alunos/widgets/aluno360_weight_activity_card.dart';
  const detailLoadingSkeletonFile =
      'lib/features/alunos/widgets/aluno_detail_loading_skeleton.dart';
  const alunoRepositoryFile = 'lib/features/alunos/data/aluno_repository.dart';
  const alunoCoreModelsFile = 'lib/features/alunos/data/aluno_core_models.dart';
  const aluno360ModelsFile = 'lib/features/alunos/data/aluno_360_models.dart';
  const alunoHomeModelsFile = 'lib/features/alunos/data/aluno_home_models.dart';
  final main = File(mainFile).readAsStringSync();
  final statePart = File(statePartFile).readAsStringSync();
  final providers = File(providersFile).readAsStringSync();
  final heroWidget = File(heroWidgetFile).readAsStringSync();
  final heroRiskStyle = File(heroRiskStyleFile).readAsStringSync();
  final headerWidget = File(headerWidgetFile).readAsStringSync();
  final operacaoTab = File(operacaoTabFile).readAsStringSync();
  final operacaoLogic = readScreenSourceBundle(operacaoLogicFile);
  final copilotLogic = File(copilotLogicFile).readAsStringSync();
  final copilotExecutarLogic =
      File(copilotExecutarLogicFile).readAsStringSync();
  final copilotOutreachLogic =
      File(copilotOutreachLogicFile).readAsStringSync();
  final copilotTextLogic = File(copilotTextLogicFile).readAsStringSync();
  final outreachDisplay = File(outreachDisplayFile).readAsStringSync();
  final outreachSheet = File(outreachSheetFile).readAsStringSync();
  final copilotCard = File(copilotCardFile).readAsStringSync();
  final fichaCard = File(fichaCardFile).readAsStringSync();
  final resumoAgora = File(resumoAgoraFile).readAsStringSync();
  final menuAcoes = File(menuAcoesFile).readAsStringSync();
  final copilotSupport = File(copilotSupportFile).readAsStringSync();
  final stickyCta = File(stickyCtaFile).readAsStringSync();
  final followUp = File(followUpFile).readAsStringSync();
  final commitmentSheet = File(commitmentSheetFile).readAsStringSync();
  final copilotTaskActions = File(copilotTaskActionsFile).readAsStringSync();
  final executarButton = File(executarButtonFile).readAsStringSync();
  final ferramentasModules = File(ferramentasModulesFile).readAsStringSync();
  final timelineCard = File(timelineCardFile).readAsStringSync();
  final insetEmptyActions = File(insetEmptyActionsFile).readAsStringSync();
  final alunoActions = File(alunoActionsFile).readAsStringSync();
  final deleteConfirmSheet = File(deleteConfirmSheetFile).readAsStringSync();
  final evolucaoCard = File(evolucaoCardFile).readAsStringSync();
  final profileGapsSheet = File(profileGapsSheetFile).readAsStringSync();
  final iaRepository = File(iaRepositoryFile).readAsStringSync();
  final detailEvolucaoTab = File(detailEvolucaoTabFile).readAsStringSync();
  final detailFerramentasTab =
      File(detailFerramentasTabFile).readAsStringSync();
  final recoveryInsight = File(recoveryInsightFile).readAsStringSync();
  final weightActivity = File(weightActivityFile).readAsStringSync();
  final detailLoadingSkeleton =
      File(detailLoadingSkeletonFile).readAsStringSync();
  final alunoRepository = File(alunoRepositoryFile).readAsStringSync();
  final alunoCoreModels = File(alunoCoreModelsFile).readAsStringSync();
  final aluno360Models = File(aluno360ModelsFile).readAsStringSync();
  final alunoHomeModels = File(alunoHomeModelsFile).readAsStringSync();
  return '$main\n$statePart\n$providers\n$heroWidget\n$heroRiskStyle\n$headerWidget\n$operacaoTab\n$operacaoLogic\n$copilotLogic\n$copilotExecutarLogic\n$copilotOutreachLogic\n$copilotTextLogic\n$outreachDisplay\n$outreachSheet\n$copilotCard\n$fichaCard\n$resumoAgora\n$menuAcoes\n$copilotSupport\n$stickyCta\n$followUp\n$commitmentSheet\n$copilotTaskActions\n$executarButton\n$ferramentasModules\n$timelineCard\n$insetEmptyActions\n$alunoActions\n$deleteConfirmSheet\n$evolucaoCard\n$profileGapsSheet\n$iaRepository\n$detailEvolucaoTab\n$detailFerramentasTab\n$recoveryInsight\n$weightActivity\n$detailLoadingSkeleton\n$alunoRepository\n$alunoCoreModels\n$aluno360Models\n$alunoHomeModels';
}

void main() {
  test('aluno detail exposes 360 view and prescriptive copilot actions', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class Aluno360CopilotCard'));
    expect(screen, contains('Aluno 360'));
    expect(screen, contains('class Aluno360TimelineCard'));
    expect(screen, contains("'Linha do tempo'"));
    expect(screen, isNot(contains('aluno360Provider(')));
    expect(screen, contains('shouldWatchAlunoDetailFallback'));
    expect(screen, contains('shouldWatchAlunoRecoverySidecar'));
    expect(screen, contains('shouldWatchAluno360Tab1Sidecars'));
    expect(screen, contains('resolveAlunoDetailAlunoAsync'));
    expect(screen, isNot(contains('alertasConfigProvider')));
    expect(screen, contains('buscarAluno360Operacao'));
    expect(screen, contains('class Timeline360Tile'));
    expect(screen, contains("hint: expandable ? 'Mostra o conteúdo completo'"));
    expect(screen, contains('final interactive = expandable || hasRoute'));
    expect(screen, contains('alunoCopilotoActionProvider'));
    expect(screen, contains('proximaAcao(alunoId)'));
    expect(screen, contains('salvarAcaoCopiloto'));
    expect(screen, contains('commandCenterProvider'));
    expect(screen, contains('class Aluno360CopilotSignalTile'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_copilot_card.dart',
      ).readAsStringSync(),
      isNot(contains('Aluno360CopilotSignalsGrid')),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_copilot_prescription.dart',
      ).readAsStringSync(),
      contains('class Aluno360CopilotPrescription'),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_copilot_logic.dart',
      ).readAsStringSync(),
      contains('resolveCopilotAcao'),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_copilot_outreach_logic.dart',
      ).readAsStringSync(),
      contains('copilotMensagemPronta'),
    );
    expect(screen, contains('copySensitiveToClipboard'));
    expect(
      File('lib/features/alunos/widgets/aluno360_menu_sheet.dart')
          .readAsStringSync(),
      contains('aluno360MenuCriarTarefa'),
    );
    expect(screen, contains('FxTonalButton'));
    // Criar tarefa fica no ⋮ do cabeçalho e o Chat é ação do cabeçalho; nunca no sticky.
    expect(screen, contains('Aluno360MenuAcao.criarTarefa'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_acao_sticky.dart',
      ).readAsStringSync(),
      isNot(contains("label: 'Criar tarefa'")),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_acao_sticky.dart',
      ).readAsStringSync(),
      isNot(contains("label: 'Chat'")),
    );
    expect(screen, isNot(contains("label: 'Concluir'")));
    expect(screen, contains("'Copiar mensagem'"));
    expect(screen, contains("'Mensagem sugerida'"));
    expect(screen, contains("'Abrir chat'"));
    expect(screen, contains('alunoOutreachOpenChatLabel'));
    expect(screen, contains('FxSettingsTile'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno_outreach_message_sheet.dart',
      ).readAsStringSync(),
      allOf(
        contains('FxLiquidPrimaryButton'),
        contains('alunoOutreachOpenChatLabel'),
        isNot(contains('FxSettingsGroup')),
        isNot(contains('OutlinedButton')),
        contains('_OutreachMessageQuote'),
      ),
    );
    expect(screen, contains('executarAcaoCopiloto'));
    expect(screen, contains('resolveCopilotExecutarAcao'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_copilot_executar_confirm.dart',
      ).readAsStringSync(),
      contains('showCopilotExecutarConfirmSheet'),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_copilot_executar_logic.dart',
      ).readAsStringSync(),
      contains('copilotExecutarConfirmBody'),
    );
    expect(
      File('lib/core/widgets/feedback_helper.dart').readAsStringSync(),
      contains('reserveBottom'),
    );
  });

  test(
    'aluno 360 progressive: first paint /360/operacao, idle prefetch, lazy tabs',
    () {
      final screen = _alunoDetailLibrarySource();
      final providers =
          File(
            'lib/features/alunos/providers/aluno_detail_providers.dart',
          ).readAsStringSync();
      final resolution =
          File(
            'lib/features/alunos/utils/aluno_detail_aluno_resolution.dart',
          ).readAsStringSync();
      final cache =
          File(
            'lib/features/alunos/utils/aluno360_client_cache.dart',
          ).readAsStringSync();
      final skeleton =
          File(
            'lib/features/alunos/widgets/aluno_detail_loading_skeleton.dart',
          ).readAsStringSync();
      final state =
          File(
            'lib/features/alunos/screens/aluno_detail_screen_state.part.dart',
          ).readAsStringSync();
      final repo =
          File(
            'lib/features/alunos/data/aluno_repository.dart',
          ).readAsStringSync();
      final repoLib = [
        repo,
        File(
          'lib/features/alunos/data/aluno_core_models.dart',
        ).readAsStringSync(),
        File(
          'lib/features/alunos/data/aluno_360_models.dart',
        ).readAsStringSync(),
        File(
          'lib/features/alunos/data/aluno_home_models.dart',
        ).readAsStringSync(),
      ].join('\n');
      final sticky =
          File(
            'lib/features/alunos/widgets/aluno360_acao_sticky.dart',
          ).readAsStringSync();

      expect(repoLib, contains('buscarAluno360Operacao'));
      expect(repoLib, contains('/360/operacao'));
      expect(repoLib, contains('buscarAluno360Evolucao'));
      expect(repoLib, contains('buscarAluno360Ferramentas'));
      expect(repoLib, contains('evolucaoHome'));
      expect(repoLib, contains('composicaoResumo'));
      expect(repoLib, contains('anamneseResumo'));
      expect(repoLib, contains('Aluno360AnamneseResumo'));
      expect(repoLib, contains('Aluno360ComposicaoResumo'));
      expect(
        File(
          'lib/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart',
        ).readAsStringSync(),
        allOf(
          contains('composicaoResumo'),
          contains('aluno360FerramentasBundleProvider'),
          isNot(contains('alunoMedidasResumoProvider')),
          isNot(contains('/avaliacoes/comparativo')),
        ),
      );

      expect(
        File(
          'lib/features/alunos/widgets/aluno360_ferramentas_grupos_view.dart',
        ).readAsStringSync(),
        allOf(
          contains('anamneseStatus'),
          isNot(contains('alunoAnamneseProvider')),
          isNot(contains('anamnese_provider.dart')),
        ),
      );
      expect(
        File(
          'lib/features/alunos/providers/aluno_detail_providers.dart',
        ).readAsStringSync(),
        isNot(contains('alunoMedidasResumoProvider')),
      );
      expect(
        File(
          'lib/features/alunos/providers/aluno_detail_providers.dart',
        ).readAsStringSync(),
        contains('_hydrateEvolucaoHomeFromFerramentas'),
      );
      expect(
        File(
          'lib/features/evolucao/providers/evolucao_home_provider.dart',
        ).readAsStringSync(),
        contains('EvolucaoHomeClientCache.getIfFresh'),
      );
      expect(providers, contains('aluno360OperacaoBundleProvider'));
      expect(providers, contains('buscarAluno360Operacao'));
      expect(providers, contains('prefetchAluno360SecondaryTabs'));
      expect(providers, contains('aluno360EvolucaoBundleProvider'));
      expect(providers, contains('aluno360FerramentasBundleProvider'));
      expect(providers, contains("endpoint': 'operacao'"));
      expect(cache, contains('ttl = Duration(seconds: 45)'));
      expect(cache, contains('getOperacaoIfFresh'));
      expect(resolution, contains('shouldWatchAlunoRecoverySidecar'));
      expect(resolution, contains('return false;'));
      expect(resolution, contains('resolveAlunoDetailListPreview'));
      expect(resolution, contains('Aluno360Operacao'));
      expect(state, isNot(contains('ref.watch(aluno360Provider')));
      expect(state, contains('aluno360OperacaoBundleProvider'));
      expect(state, contains('prefetchAluno360SecondaryTabs'));
      expect(state, contains('Priority.idle'));
      expect(state, contains("source': 'operacao'"));
      expect(state, contains('ProductEvents.aluno360FirstPaint'));
      expect(state, contains('_openedTabs'));
      expect(state, contains('resolveAlunoDetailListPreview'));
      expect(state, contains('listPreview: listPreview'));
      expect(skeleton, contains('listPreview'));
      expect(skeleton, contains('AlunoAvatar'));
      expect(screen, contains('listPreview'));
      expect(screen, contains("extra: aluno"));
      expect(state, isNot(contains('alunoCopilotoForceIaProvider')));
      expect(sticky, isNot(contains('ref.watch(alunoOpenIaActionsProvider')));
    },
  );
  test('aluno 360 fase 3: tabs, semantics, friendly errors, shared tile', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class Aluno360ResumoTab'));
    expect(screen, contains('class Aluno360DetailEvolucaoTab'));
    expect(screen, contains('class Aluno360TimelineCard'));
    expect(screen, contains('Linha do tempo'));
    expect(screen, contains('Ver todos os'));
    expect(screen, contains('class Aluno360DetailFerramentasTab'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_tab.dart',
      ).readAsStringSync(),
      allOf(
        contains('Aluno360DadosDoAlunoGrupo'),
        contains('aluno360DadosIncompletos'),
        isNot(contains('showAluno360FerramentasHelpSheet')),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_grupos_view.dart',
      ).readAsStringSync(),
      allOf(
        contains('aluno360GrupoTitulo'),
        contains('secoesDeFerramentas'),
        isNot(contains('Mais ferramentas')),
        isNot(contains('splitModulesForFold')),
      ),
    );
    final layoutSource =
        File(
          'lib/features/alunos/constants/aluno_360_layout.dart',
        ).readAsStringSync();
    expect(layoutSource, contains('compactSectionTitleStyle'));
    expect(layoutSource, contains('panelTitleStyle'));
    expect(layoutSource, contains('ctaLabelStyle'));
    expect(
      File('lib/features/alunos/utils/aluno360_entry_motion.dart').existsSync(),
      isFalse,
      reason: 'dead motion util removed',
    );
    expect(layoutSource, isNot(contains('heroExpandedHeight')));
    expect(
      File('lib/features/alunos/data/aluno_repository.dart').readAsStringSync(),
      isNot(contains('getTelefone')),
    );
    expect(
      File('lib/core/utils/motion_preferences.dart').readAsStringSync(),
      contains('fxMotionDurationMs'),
    );
    expect(layoutSource, contains('tabSelectedLabelStyle'));
    expect(layoutSource, contains('secondaryActionLabelStyle'));
    expect(layoutSource, contains('FxSettingsLayout.groupRadius'));
    expect(screen, isNot(contains('syncFromAluno')));
    expect(screen, isNot(contains('alunoOperacaoFocusModeProvider')));
    expect(screen, isNot(contains('atualizarOperacaoFocus')));
    expect(screen, contains('operacaoFocusMode'));
    expect(layoutSource, contains('insetCardRadius'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_follow_up_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('FxActionRow'),
        contains('alunoResumoContatoAgendar'),
        contains('showAluno360CommitmentSheet'),
        isNot(contains('FxActionChip')),
        isNot(contains('Registrar ou agendar')),
      ),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_readability.dart',
      ).readAsStringSync(),
      contains('aluno360ReadableCaption'),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_ferramentas_logic.dart',
      ).readAsStringSync(),
      contains('class Aluno360FerramentasLogic'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_tab.dart',
      ).readAsStringSync(),
      allOf(
        contains('FxSettingsGroup'),
        contains('FxSettingsTile'),
        contains('aluno360DadosDoAluno'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_module_tile.dart',
      ).existsSync(),
      isFalse,
      reason: 'fold legado ModuleTile removido',
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_grupos_view.dart',
      ).readAsStringSync(),
      allOf(
        contains('class Aluno360FerramentasGrupos'),
        contains('ConsumerWidget'),
        contains('UpgradePromptSheet'),
        contains('Aluno360FerramentasMiniSparkline'),
        contains('FxSettingsGroup'),
        contains('FxSettingsTile'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_composite_header.dart',
      ).readAsStringSync(),
      contains('FxHelpIconButton'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_help_sheets.dart',
      ).readAsStringSync(),
      contains('showAluno360EvolucaoHelpSheet'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_recovery_insight_card.dart',
      ).readAsStringSync(),
      contains('DashboardSectionHeader'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_copilot_executar_button.dart',
      ).readAsStringSync(),
      contains('class Aluno360CopilotExecutarAcaoButton'),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_copilot_task_actions.dart',
      ).readAsStringSync(),
      contains('criarTarefaCopilotoFromAluno360'),
    );
    expect(screen, contains('Abas do perfil do aluno'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_acao_sticky.dart',
      ).readAsStringSync(),
      allOf(
        contains('void abrirOperacaoSticky'),
        isNot(contains('FxLiquidPrimaryButton')),
        isNot(contains('Aluno360OperacaoStickyCtaBar')),
      ),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_ia_upgrade.dart',
      ).readAsStringSync(),
      contains('UpgradePromptSheet.show'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno_detail_hero_card.dart',
      ).readAsStringSync(),
      isNot(contains('FittedBox')),
    );
    expect(screen, contains('aluno360_evolucao_empty'));
    expect(screen, contains('ValueKey(\'aluno360_timeline_empty\')'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_grupos_view.dart',
      ).readAsStringSync(),
      contains('ValueKey(\'aluno360_ferramentas_grupos\')'),
    );
    expect(screen, contains("if (status != null) 'status': status"));
    expect(screen, contains('fonteLabel'));
    expect(screen, contains('AderenciaSemanalBundle'));
    expect(screen, contains('recoverySnapshot'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_follow_up_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('alunoResumoContatoGerenciar'),
        contains('alunoResumoContatoAgendar'),
        contains('FxActionRow'),
      ),
    );
    expect(screen, contains('operacaoContentWidthLimiter'));
    expect(screen, contains('ValueKey(\'aluno360_follow_up\')'));
    expect(screen, contains('alunoCopilotIaRefreshingProvider'));
    expect(screen, contains('operacaoOutlinedButtonStyle'));
    expect(screen, contains('class Aluno360EvolucaoInteligenteCard'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('DashboardSectionHeader'),
        contains('FxActionChip'),
        contains('_EvolucaoMetricChip'),
        contains('_VolumeSparklineRow'),
        contains('formatAlunoVolumeKg'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_timeline_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('DashboardSectionHeader'),
        contains('Timeline360Tile'),
        contains('Ver todos os'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_weight_activity_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('DashboardSectionHeader'),
        contains('OperationalMetricTile'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_commitment_sheet.dart',
      ).readAsStringSync(),
      allOf(
        contains('showFxInsetPickerSheet'),
        contains('Contato feito'),
        contains('Combinar sono'),
      ),
    );
    expect(screen, contains('showAluno360CopilotProfileGapsSheet'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_copilot_profile_gaps_sheet.dart',
      ).readAsStringSync(),
      contains('showFxInsetPickerSheet'),
    );
    expect(screen, contains('Peça um check-in'));
    expect(screen, contains('Quando houver check-in ou chat'));
    expect(
      screen,
      contains('friendlyError(e, fallback: s.alunoReenviarLinkErro)'),
    );
    expect(screen, contains('alunoTimeline360PagedProvider'));
    expect(screen, contains('reduceMotionOf(context)'));
    expect(
      File(
        'lib/features/alunos/providers/aluno_timeline360_paged_provider.dart',
      ).readAsStringSync(),
      allOf(contains('loadMore'), contains('Timeline360PagedState')),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_timeline_full_sheet.dart',
      ).readAsStringSync(),
      contains('class Aluno360TimelineFullSheet'),
    );
    expect(
      [
        File(
          'lib/features/alunos/data/aluno_repository.dart',
        ).readAsStringSync(),
        File(
          'lib/features/alunos/data/aluno_core_models.dart',
        ).readAsStringSync(),
      ].join('\n'),
      allOf(
        contains('buscarTimeline360Page'),
        contains('timeline-360/page'),
        contains('totalCount'),
      ),
    );
    expect(
      File('lib/core/widgets/operational_metric_tile.dart').readAsStringSync(),
      contains('operationalMetricDecoration'),
    );
  });
}
