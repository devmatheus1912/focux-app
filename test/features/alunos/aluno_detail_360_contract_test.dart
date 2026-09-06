import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
      'lib/features/alunos/widgets/aluno360_operacao_tab.dart';
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
  const copilotLockedSectionFile =
      'lib/features/alunos/widgets/aluno360_copilot_locked_section.dart';
  const copilotUpgradeSheetFile =
      'lib/features/alunos/widgets/aluno360_copilot_upgrade_sheet.dart';
  const operationalSectionFile =
      'lib/features/alunos/widgets/aluno360_operational_status_section.dart';
  const focusToggleFile =
      'lib/features/alunos/widgets/aluno360_operacao_focus_toggle.dart';
  const copilotSupportFile =
      'lib/features/alunos/widgets/aluno360_copilot_support.dart';
  const stickyCtaFile =
      'lib/features/alunos/widgets/aluno360_operacao_sticky_cta.dart';
  const followUpFile =
      'lib/features/alunos/widgets/aluno360_follow_up_card.dart';
  const financeBannerFile =
      'lib/features/alunos/widgets/aluno360_finance_risk_banner.dart';
  const ferramentasModulesFile =
      'lib/features/alunos/widgets/aluno360_ferramentas_modules_grid.dart';
  const timelineCardFile =
      'lib/features/alunos/widgets/aluno360_timeline_card.dart';
  const insetEmptyActionsFile =
      'lib/features/alunos/widgets/aluno360_inset_empty_actions.dart';
  const alunoActionsFile =
      'lib/features/alunos/utils/aluno_detail_aluno_actions.dart';
  const deleteConfirmSheetFile =
      'lib/features/alunos/widgets/aluno_delete_confirm_sheet.dart';
  const quickActionsFile =
      'lib/features/alunos/widgets/aluno360_student_quick_actions.dart';
  const evolucaoCardFile =
      'lib/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart';
  const adherenceLegendFile =
      'lib/features/alunos/widgets/aluno_operacao_adherence_legend.dart';
  const profileGapsSheetFile =
      'lib/features/alunos/widgets/aluno360_copilot_profile_gaps_sheet.dart';
  const copilotTaskActionsFile =
      'lib/features/alunos/utils/aluno360_copilot_task_actions.dart';
  const executarButtonFile =
      'lib/features/alunos/widgets/aluno360_copilot_executar_button.dart';
  const iaRepositoryFile = 'lib/features/ia/data/ia_repository.dart';
  const detailOperacaoTabFile =
      'lib/features/alunos/widgets/aluno360_detail_operacao_tab.dart';
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
  final main = File(mainFile).readAsStringSync();
  final statePart = File(statePartFile).readAsStringSync();
  final providers = File(providersFile).readAsStringSync();
  final heroWidget = File(heroWidgetFile).readAsStringSync();
  final heroRiskStyle = File(heroRiskStyleFile).readAsStringSync();
  final headerWidget = File(headerWidgetFile).readAsStringSync();
  final operacaoTab = File(operacaoTabFile).readAsStringSync();
  final operacaoLogic = File(operacaoLogicFile).readAsStringSync();
  final copilotLogic = File(copilotLogicFile).readAsStringSync();
  final copilotExecutarLogic =
      File(copilotExecutarLogicFile).readAsStringSync();
  final copilotOutreachLogic =
      File(copilotOutreachLogicFile).readAsStringSync();
  final copilotTextLogic = File(copilotTextLogicFile).readAsStringSync();
  final outreachDisplay = File(outreachDisplayFile).readAsStringSync();
  final outreachSheet = File(outreachSheetFile).readAsStringSync();
  final copilotCard = File(copilotCardFile).readAsStringSync();
  final copilotLockedSection =
      File(copilotLockedSectionFile).readAsStringSync();
  final copilotUpgradeSheet =
      File(copilotUpgradeSheetFile).readAsStringSync();
  final operationalSection = File(operationalSectionFile).readAsStringSync();
  final focusToggle = File(focusToggleFile).readAsStringSync();
  final copilotSupport = File(copilotSupportFile).readAsStringSync();
  final stickyCta = File(stickyCtaFile).readAsStringSync();
  final followUp = File(followUpFile).readAsStringSync();
  final copilotTaskActions = File(copilotTaskActionsFile).readAsStringSync();
  final executarButton = File(executarButtonFile).readAsStringSync();
  final financeBanner = File(financeBannerFile).readAsStringSync();
  final ferramentasModules = File(ferramentasModulesFile).readAsStringSync();
  final timelineCard = File(timelineCardFile).readAsStringSync();
  final insetEmptyActions = File(insetEmptyActionsFile).readAsStringSync();
  final alunoActions = File(alunoActionsFile).readAsStringSync();
  final deleteConfirmSheet = File(deleteConfirmSheetFile).readAsStringSync();
  final quickActions = File(quickActionsFile).readAsStringSync();
  final evolucaoCard = File(evolucaoCardFile).readAsStringSync();
  final adherenceLegend = File(adherenceLegendFile).readAsStringSync();
  final profileGapsSheet = File(profileGapsSheetFile).readAsStringSync();
  final iaRepository = File(iaRepositoryFile).readAsStringSync();
  final detailOperacaoTab = File(detailOperacaoTabFile).readAsStringSync();
  final detailEvolucaoTab = File(detailEvolucaoTabFile).readAsStringSync();
  final detailFerramentasTab =
      File(detailFerramentasTabFile).readAsStringSync();
  final recoveryInsight = File(recoveryInsightFile).readAsStringSync();
  final weightActivity = File(weightActivityFile).readAsStringSync();
  final detailLoadingSkeleton =
      File(detailLoadingSkeletonFile).readAsStringSync();
  final alunoRepository = File(alunoRepositoryFile).readAsStringSync();
  return '$main\n$statePart\n$providers\n$heroWidget\n$heroRiskStyle\n$headerWidget\n$operacaoTab\n$operacaoLogic\n$copilotLogic\n$copilotExecutarLogic\n$copilotOutreachLogic\n$copilotTextLogic\n$outreachDisplay\n$outreachSheet\n$copilotCard\n$copilotLockedSection\n$copilotUpgradeSheet\n$operationalSection\n$focusToggle\n$copilotSupport\n$stickyCta\n$followUp\n$copilotTaskActions\n$executarButton\n$financeBanner\n$ferramentasModules\n$timelineCard\n$insetEmptyActions\n$alunoActions\n$deleteConfirmSheet\n$quickActions\n$evolucaoCard\n$adherenceLegend\n$profileGapsSheet\n$iaRepository\n$detailOperacaoTab\n$detailEvolucaoTab\n$detailFerramentasTab\n$recoveryInsight\n$weightActivity\n$detailLoadingSkeleton\n$alunoRepository';
}

void main() {
  test('aluno detail exposes 360 view and prescriptive copilot actions', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class Aluno360CopilotCard'));
    expect(screen, contains('Aluno 360'));
    expect(screen, contains('class Aluno360TimelineCard'));
    expect(screen, contains("'Linha do tempo 360'"));
    expect(screen, contains('aluno360Provider'));
    expect(screen, contains('shouldWatchAlunoDetailFallback'));
    expect(screen, contains('shouldWatchAlunoRecoverySidecar'));
    expect(screen, contains('shouldWatchAluno360Tab1Sidecars'));
    expect(screen, contains('resolveAlunoDetailAlunoAsync'));
    expect(screen, contains('resolveDiasSemTreinoLimiteFromHome'));
    expect(screen, contains('ref.exists(alunosHomeProvider)'));
    expect(screen, isNot(contains('alertasConfigProvider')));
    expect(screen, contains('buscarAluno360'));
    expect(screen, contains('class Timeline360Tile'));
    expect(screen, contains('disclosure: expandable'));
    expect(screen, contains('onTap: interactive ? onTap : null'));
    expect(screen, contains('alunoCopilotoActionProvider'));
    expect(screen, contains('proximaAcao(alunoId)'));
    expect(screen, contains('salvarAcaoCopiloto'));
    expect(screen, contains('commandCenterProvider'));
    expect(screen, contains('class Aluno360CopilotSignalTile'));
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
    expect(screen, contains("'Criar tarefa'"));
    expect(screen, contains('TextButton'));
    expect(screen, isNot(contains("label: 'Criar tarefa'")));
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
        'lib/features/alunos/widgets/aluno360_finance_risk_banner.dart',
      ).readAsStringSync(),
      allOf(
        contains('class Aluno360FinanceRiskBanner'),
        contains('CommandActionTile'),
        contains('Pendência financeira'),
      ),
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

  test('aluno 360 first paint: only /360, list preview, short cache, lazy tabs', () {
    final screen = _alunoDetailLibrarySource();
    final providers =
        File('lib/features/alunos/providers/aluno_detail_providers.dart')
            .readAsStringSync();
    final resolution =
        File('lib/features/alunos/utils/aluno_detail_aluno_resolution.dart')
            .readAsStringSync();
    final cache =
        File('lib/features/alunos/utils/aluno360_client_cache.dart')
            .readAsStringSync();
    final skeleton =
        File('lib/features/alunos/widgets/aluno_detail_loading_skeleton.dart')
            .readAsStringSync();
    final state =
        File('lib/features/alunos/screens/aluno_detail_screen_state.part.dart')
            .readAsStringSync();

    expect(providers, contains('Aluno360ClientCache.getIfFresh'));
    expect(providers, contains('buscarAluno360'));
    expect(providers, contains('ProductEvents.aluno360FetchDuration'));
    expect(cache, contains('ttl = Duration(seconds: 45)'));
    expect(resolution, contains('shouldWatchAlunoRecoverySidecar'));
    expect(resolution, contains('return false;'));
    expect(resolution, contains('resolveAlunoDetailListPreview'));
    expect(resolution, contains('evolucaoTabOpened'));
    expect(state, isNot(contains('ref.watch(alunoAutonomiaResumoProvider')));
    expect(state, contains('resolveAlunoDetailListPreview'));
    expect(state, contains('listPreview: listPreview'));
    expect(state, contains('ProductEvents.aluno360FirstPaint'));
    expect(state, contains('_openedTabs'));
    expect(skeleton, contains('listPreview'));
    expect(skeleton, contains('AlunoAvatar'));
    expect(screen, contains('listPreview'));
    expect(screen, contains("extra: aluno"));
  });

  test(
    'aluno 360 polish: tabs, unified status, refresh, altura, sparkline',
    () {
      final screen = _alunoDetailLibrarySource();

      expect(screen, contains('class Aluno360FollowUpCard'));
      expect(screen, contains('ConsumerState<Aluno360FollowUpCard>'));
      expect(screen, contains('Contato registrado'));
      expect(screen, contains('Aluno360Layout.captionStyle'));
      expect(screen, contains('aderenciaSemanal'));
      expect(screen, contains('class Aluno360OperationalStatusSection'));
      expect(screen, contains('Status operacional'));
      expect(screen, contains('Índice operacional'));
      expect(screen, contains('Próximo contato:'));
      expect(screen, contains('alunoOperacaoFocusModeProvider'));
      expect(screen, contains('resolveOperacaoStickyAction'));
      expect(screen, contains('operacaoHeroShowsRisco'));
      expect(screen, contains('shouldShowCopilotProfileGapsButton'));
      expect(screen, contains('Aluno360OperacaoFocusModeToggle'));
      expect(
        File(
          'lib/features/alunos/utils/aluno360_copilot_logic.dart',
        ).readAsStringSync(),
        contains('Sugestão offline'),
      );
      expect(screen, contains('invalidateAluno360Providers'));
      expect(screen, contains('alunoPesoHistoricoProvider'));
      expect(screen, contains('alunoAderenciaSemanalProvider'));
      expect(screen, contains('AnimatedSwitcher'));
      expect(screen, contains('hasOpenCopilotTask'));
      expect(screen, contains('openCopilotTasks'));
      expect(screen, contains('class AderenciaDia'));
      expect(screen, contains('hidePrimaryCta'));
      expect(screen, contains('hideChatCta'));
      expect(screen, contains('shouldHideCopilotChatCta'));
      expect(screen, contains('AlunoOperacaoAdherenceBars'));
      expect(screen, contains('summarizeAderenciaWeek'));
      expect(screen, contains('class Aluno360WeightTrendSparkline'));
      expect(screen, contains('FxSparkline'));
      expect(
        File(
          'lib/features/alunos/utils/aluno360_ferramentas_logic.dart',
        ).readAsStringSync(),
        contains('measurementsSummary'),
      );
      expect(screen, contains('friendlyError'));
      expect(screen, contains('class Aluno360OperacaoTab'));
      expect(screen, contains('class Aluno360CompositeHeaderDelegate'));
      expect(screen, contains("static const _labels = ['Operação', 'Evolução', 'Ferramentas']"));
      expect(screen, contains('class Aluno360DetailOperacaoTab'));
      expect(screen, contains('class Aluno360DetailEvolucaoTab'));
      expect(screen, contains('class Aluno360DetailFerramentasTab'));
      expect(screen, contains('FxLoading.sectionShimmer'));
      expect(screen, contains('class AlunoDetailLoadingSkeleton'));
      expect(screen, contains('aluno360_hero_skeleton'));
      expect(
        File(
          'lib/features/alunos/widgets/aluno360_copilot_prescription.dart',
        ).readAsStringSync(),
        contains('_collapsedLines = 2'),
      );
      expect(screen, contains('Aluno360CopilotPrescriptionBody'));
      expect(screen, contains('operacaoStatusSubtitle'));
      expect(screen, contains('copilotProfileGapsForCard'));
      expect(screen, contains('copilotProfileGapsButtonLabel'));
      expect(
        File(
          'lib/features/alunos/widgets/aluno360_copilot_prescription.dart',
        ).readAsStringSync(),
        contains('Ver contexto'),
      );
      expect(screen, contains('alunoCopilotoForceIaProvider'));
      expect(screen, contains('proximaAcao360'));
      expect(screen, contains('/financeiro?alunoId='));
      expect(screen, contains('Aluno360OperacaoStickyCtaBar'));
      expect(screen, isNot(contains('Pulso operacional')));
      expect(screen, isNot(contains('Score API')));
      expect(screen, contains('confirmarExclusaoAlunoDetail'));
      expect(screen, contains('riscoMetricIcon'));
      expect(screen, contains('FxSettingsTile'));
      expect(screen, contains('copySensitiveToClipboard'));
      expect(screen, isNot(contains('Erro: \$e')));
      expect(screen, isNot(contains('operational_metrics.part.dart')));
      expect(screen, contains('class AlunoDetailHeroCard'));
      expect(screen, contains('aluno360_hero_card'));
      expect(screen, contains('_HeroRiskNotice'));
      expect(screen, contains('Aluno360CopilotUpgradeSheet'));
      expect(screen, contains('Aluno360HeroRiskStyle'));
      expect(screen, contains('copySensitiveToClipboard'));
      expect(
        screen,
        isNot(contains('trailing: Aluno360OperacaoFocusModeToggle')),
      );
      expect(screen, contains('showFocusToggle: true'));
      expect(screen, contains('class _IdentityObjectiveRow'));
      expect(screen, contains('alunoObjectiveIsDefined'));
      expect(screen, contains('onDefineObjective'));
      expect(screen, contains('Aluno360Layout'));
      expect(screen, contains('operacaoScrollBottomReserve'));
      expect(screen, contains('transitionBuilder:'));
      expect(screen, contains('chrome.sheetFill'));
    },
  );

  test('aluno 360 fase 3: tabs, semantics, friendly errors, shared tile', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class Aluno360DetailOperacaoTab'));
    expect(screen, contains('Aluno360OperacaoStickyCtaBar'));
    expect(screen, contains('class Aluno360OperationalStatusSection'));
    expect(screen, contains('Ações rápidas da aba operação'));
    expect(screen, contains('class Aluno360DetailEvolucaoTab'));
    expect(screen, contains('class Aluno360TimelineCard'));
    expect(screen, contains('Linha do tempo 360'));
    expect(screen, contains('Ver todos os'));
    expect(screen, contains('class Aluno360DetailFerramentasTab'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_tab.dart',
      ).readAsStringSync(),
      allOf(
        contains("'Medidas'"),
        contains('DashboardSectionHeader'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_ferramentas_modules_grid.dart',
      ).readAsStringSync(),
      allOf(contains("'Treino & evolução'"), contains("'Perfil & gestão'")),
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
    expect(screen, contains('syncFromAluno'));
    expect(screen, contains('operacaoFocusMode'));
    expect(screen, contains('atualizarOperacaoFocus'));
    expect(layoutSource, contains('insetCardRadius'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_follow_up_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('aluno360FollowUpSemantics'),
        contains('DashboardHomeActionChip'),
        contains('showFxInsetPickerSheet'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_a11y.dart',
      ).readAsStringSync(),
      contains('aluno360ModuleTileSemantics'),
    );
    expect(
      File(
        'lib/features/alunos/utils/aluno360_readability.dart',
      ).readAsStringSync(),
      contains('aluno360ReadableCaption'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_operational_status_section.dart',
      ).readAsStringSync(),
      contains('OperationalMetricTile'),
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
        contains("'Medidas'"),
        contains('measurementRows'),
        contains("'Medidas em dia'"),
        contains('DashboardSectionHeader'),
        contains('FxSatelliteListTile'),
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
        'lib/features/alunos/widgets/aluno360_ferramentas_modules_grid.dart',
      ).readAsStringSync(),
      allOf(
        contains('class Aluno360FerramentasModulesGrid'),
        contains('ConsumerWidget'),
        contains('UpgradePromptSheet'),
        contains('Aluno360FerramentasMiniSparkline'),
        contains('DashboardSectionHeader'),
        contains('FxSatelliteListTile'),
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
        'lib/features/alunos/widgets/aluno360_copilot_locked_section.dart',
      ).readAsStringSync(),
      contains('Aluno360CopilotUpgradeSheet.show'),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_student_quick_actions.dart',
      ).readAsStringSync(),
      contains('DashboardHomeActionChip'),
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
    expect(screen, contains('ValueKey(\'aluno360_operacao_status\')'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_operacao_sticky_cta.dart',
      ).readAsStringSync(),
      allOf(
        contains('FxLiquidPrimaryButton'),
        contains('DashboardHomeActionChip'),
        contains('Ações rápidas da aba operação'),
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
        'lib/features/alunos/widgets/aluno360_ferramentas_modules_grid.dart',
      ).readAsStringSync(),
      contains('ValueKey(\'aluno360_ferramentas_modulos\')'),
    );
    expect(screen, contains('class Aluno360StudentQuickActions'));
    expect(screen, contains('AlunoOperacaoAdherenceLegend'));
    expect(screen, contains('fonteLabel'));
    expect(screen, contains('AderenciaSemanalBundle'));
    expect(screen, contains('recoverySnapshot'));
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_follow_up_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('DashboardHomeActionChip'),
        contains('DashboardSectionHeader'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_copilot_locked_section.dart',
      ).readAsStringSync(),
      allOf(contains('CommandActionTile'), contains('Aluno360CopilotUpgradeSheet.show')),
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
        contains('OperationalMetricTile'),
        contains('DashboardHomeActionChip'),
      ),
    );
    expect(
      File(
        'lib/features/alunos/widgets/aluno360_timeline_card.dart',
      ).readAsStringSync(),
      allOf(
        contains('DashboardSectionHeader'),
        contains('FxSatelliteListTile'),
        contains('DashboardHomeActionChip'),
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
      contains('friendlyError(e, fallback: \'Não foi possível gerar senha.\')'),
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
      File('lib/features/alunos/data/aluno_repository.dart').readAsStringSync(),
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
