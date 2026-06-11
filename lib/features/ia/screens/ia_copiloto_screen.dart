import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/ia_repository.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../widgets/ia_quota_upgrade.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../providers/ia_copilot_providers.dart';
import '../widgets/ia_copilot_shell_widgets.dart';
import '../widgets/ia_copilot_insight_widgets.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
part 'ia_copiloto_screen_actions.part.dart';

class IaCopilotoScreen extends ConsumerStatefulWidget {
  const IaCopilotoScreen({super.key});
  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}

class _IaCopilotoScreenState extends ConsumerState<IaCopilotoScreen>
    with SingleTickerProviderStateMixin {
  int _modeIdx = 0;
  bool _gerando = false;
  bool _gerado = false;
  Object? _erro;
  int? _selectedAlunoId;
  String? _selectedAlunoNome;
  // BUG-21: tempo real de geração
  int _geracaoMs = 0;
  Map<String, dynamic>? _proximaAcao;
  bool _tarefaCriada = false;
  bool _tarefaPersistida = false;
  final _modes = ['Treino', 'Dieta', 'Progressão'];

  String get _mode => _modes[_modeIdx];
  String get _modeDisplay => _mode == 'Progressão' ? 'Progresso' : _mode;

  IconData get _modeIcon {
    switch (_mode) {
      case 'Dieta':
        return Icons.restaurant_menu_outlined;
      case 'Progressão':
        return Icons.trending_up_outlined;
      default:
        return Icons.fitness_center_outlined;
    }
  }

  String get _readinessHeadline {
    switch (_mode) {
      case 'Dieta':
        return 'Recomendações · Dieta';
      case 'Progressão':
        return 'Recomendações · Progresso';
      default:
        return 'Recomendações · Treino';
    }
  }

  String get _modePromise {
    switch (_mode) {
      case 'Dieta':
        return 'Analisa objetivo e rotina do aluno e sugere pontos de atenção. O plano alimentar continua sendo montado por você.';
      case 'Progressão':
        return 'Lê histórico, check-ins e aderência para sugerir ajuste de carga, volume ou frequência — você decide o que aplicar.';
      default:
        return 'Analisa objetivo, nível, equipamentos e histórico do aluno. Você monta e edita os treinos na aba Treinos.';
    }
  }

  List<String> get _modeChecks {
    switch (_mode) {
      case 'Dieta':
        return [
          'Objetivo do aluno',
          'Rotina declarada',
          'Alertas para revisão',
        ];
      case 'Progressão':
        return ['Histórico recente', 'Prontidão wearable', 'Próxima ação'];
      default:
        return ['Objetivo e nível', 'Foco de volume', 'Próxima ação sugerida'];
    }
  }

  String get _howItWorksPreview {
    switch (_mode) {
      case 'Dieta':
        return 'O Copiloto não cria plano alimentar no app. Ele gera recomendações em texto para você revisar e montar a prescrição com autonomia.';
      case 'Progressão':
        return 'O Copiloto sugere ajustes com base em dados do aluno. Nada altera treino ou carga automaticamente — você revisa e aplica no atendimento.';
      default:
        return 'O Copiloto não monta fichas de treino. Ele gera recomendações em texto (riscos, volume, foco). Você cria e edita os treinos em Treinos, com total autonomia.';
    }
  }

  String get _resultNote {
    switch (_mode) {
      case 'Dieta':
        return 'Recomendações de dieta para revisão. Monte o plano no fluxo que você já usa — nada é aplicado ao aluno automaticamente.';
      case 'Progressão':
        return 'Recomendações de progressão com base em check-ins e histórico. Revise antes de ajustar carga ou volume na prática.';
      default:
        return 'Recomendações para prescrever o treino. Use como apoio à decisão; monte e publique o treino manualmente em Treinos.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: dark);
    final primaryAccent = BrandPalette.accent(primary);
    final primaryDeep = BrandPalette.deep(primary);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final brand = dark ? primaryAccent : primary;

    return fxScreenA11yScope(
      label: 'Copiloto',
      child: FeatureGate(
        featureName: 'Copiloto IA',
        requiredPlan: SubscriptionPlan.PREMIUM,
        capability: 'iaCopiloto',
        child: FxShellScaffold(
          useMesh: true,
          safeArea: false,
          appBar: FxShellAppBar(
            title: 'Copiloto',
            subtitle: 'IA FOCUX',
            onBack: () => safePopOr(context, () => goToRoleHome(context, ref)),
            actions: [
              IaCopilotHeaderStatus(
                dark: dark,
                brand: brand,
                line: line,
                ink: ink,
              ),
            ],
          ),
          bottomNavigationBar:
              _gerado
                  ? IaCopilotResultActionBar(
                    brand: brand,
                    ink: ink,
                    onCreateTask: _atribuir,
                    onMore: _abrirMenu,
                  )
                  : null,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.only(bottom: _gerado ? 108 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      12,
                    ),
                    child: IaCopilotStudentSelector(
                      alunoNome: _selectedAlunoNome,
                      brand: brand,
                      ink: ink,
                      mute: mute,
                      onTap: _selecionarAluno,
                    ),
                  ),

                  // Mode selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      14,
                    ),
                    child: IaCopilotModeSelector(
                      modes: _modes,
                      selectedIndex: _modeIdx,
                      brand: brand,
                      dark: dark,
                      line: line,
                      mute: mute,
                      onSelect: (index) => setState(() => _modeIdx = index),
                    ),
                  ),

                  // Contexto e preparo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      14,
                    ),
                    child: IaCopilotReadinessCard(
                      headline: _readinessHeadline,
                      modeDisplay: _modeDisplay,
                      icon: _modeIcon,
                      promise: _modePromise,
                      checks: _modeChecks,
                      alunoNome: _selectedAlunoNome,
                      recoveryAsync:
                          _selectedAlunoId == null
                              ? null
                              : ref.watch(
                                copilotRecoveryProvider(_selectedAlunoId!),
                              ),
                    ),
                  ),

                  // Safety disclaimer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      12,
                    ),
                    child: IaCopilotSafetyNote(
                      ink: ink,
                      mute: mute,
                      brand: brand,
                    ),
                  ),

                  // Generate button / progress
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      18,
                    ),
                    child:
                        !_gerado && !_gerando
                            ? IaCopilotPrimaryAction(
                              label: 'Gerar $_modeDisplay',
                              icon: _modeIcon,
                              brand: brand,
                              primaryDeep: primaryDeep,
                              onTap: _gerar,
                            )
                            : IaCopilotGenerationStatus(
                              gerando: _gerando,
                              gerado: _gerado,
                              elapsedMs: _geracaoMs,
                              mode: _modeDisplay,
                              ink: ink,
                              mute: mute,
                              primarySoft: primarySoft,
                            ),
                  ),

                  if (!_gerado && !_gerando && _erro == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        0,
                        16,
                        18,
                      ),
                      child: IaCopilotPreviewCard(
                        howItWorks: _howItWorksPreview,
                        brand: brand,
                        ink: ink,
                        mute: mute,
                        checks: _modeChecks,
                      ),
                    ),

                  // Result card — vinculado ao backend (/api/ia/copiloto/insights)
                  if (_erro != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        0,
                        16,
                        16,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                              dark
                                  ? EagleTokens.darkBg.withValues(alpha: 0.2)
                                  : EagleTokens.iaError.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: EagleTokens.iaError.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: EagleTokens.iaError,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _erroIaTexto(_erro!),
                                style: TextStyle(color: ink, fontSize: 13),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  _erroSugereUpgrade(_erro!)
                                      ? _mostrarUpgradePorErro
                                      : _gerar,
                              child: Text(
                                _erroSugereUpgrade(_erro!)
                                    ? 'Fazer upgrade'
                                    : 'Tentar',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_gerado) ...[
                    Consumer(
                      builder: (context, ref, _) {
                        final query = InsightsQuery(
                          alunoId: _selectedAlunoId,
                          mode: _mode,
                        );
                        final insightsAsync = ref.watch(
                          insightsProvider(query),
                        );
                        return insightsAsync.when(
                          loading:
                              () => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  16,
                                  16,
                                ),
                                child: IaCopilotInsightsLoading(
                                  ink: ink,
                                  mute: mute,
                                  brand: brand,
                                ),
                              ),
                          error:
                              (e, _) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        dark
                                            ? EagleTokens.darkBg.withValues(alpha: 0.2)
                                            : EagleTokens.iaError.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: EagleTokens.iaError.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: EagleTokens.iaError,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _erroIaTexto(e),
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed:
                                            () => ref.invalidate(
                                              insightsProvider(query),
                                            ),
                                        child: const Text('Recarregar'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          data: (insights) {
                            final degraded = insights.any((insight) {
                              final status =
                                  (insight['status'] ?? 'READY').toString();
                              return status != 'READY';
                            });
                            if (insights.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: fxListCardDecoration(
                                    context,
                                    accent: primary,
                                    radius: 18,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sem insights no momento',
                                        style: TextStyle(
                                          color: ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Adicione mais treinos e check-ins para que a IA gere recomendações personalizadas.',
                                        style: TextStyle(
                                          color: mute,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s4,
                                0,
                                16,
                                16,
                              ),
                              child: Container(
                                decoration: fxListCardDecoration(
                                  context,
                                  accent: primary,
                                  radius: 22,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        18,
                                        18,
                                        16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors:
                                              dark
                                                  ? [
                                                    primaryDeep,
                                                    BrandPalette.deep(
                                                      primaryDeep,
                                                    ),
                                                  ]
                                                  : [primary, primaryDeep],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'INSIGHTS · ${_mode.toUpperCase()}',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${insights.length} recomendações geradas',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (degraded)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          12,
                                        ),
                                        color: const Color(
                                          0xFFFFB020,
                                        ).withValues(alpha: 0.12),
                                        child: Text(
                                          'A IA respondeu fora do formato ideal. Mantivemos as recomendações para revisão manual.',
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ...insights.asMap().entries.map((e) {
                                      final ins = e.value;
                                      return IaCopilotInsightItem(
                                        index: e.key,
                                        insight: ins,
                                        isLast: e.key == insights.length - 1,
                                        highlighted: e.key == 0,
                                        line: line,
                                        primarySoft: primarySoft,
                                        brand: brand,
                                        ink: ink,
                                        mute: mute,
                                        chipBg:
                                            dark
                                                ? Colors.white.withValues(alpha: 0.06)
                                                : TokensStrip.borderDefault,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        0,
                        16,
                        12,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: fxListCardDecoration(
                        context,
                        accent: brand,
                        radius: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: brand),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _resultNote,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    dark
                                        ? EagleTokens.darkInk
                                        : EagleTokens.inkSoft,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tarefaCriada && _proximaAcao != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          12,
                          16,
                          0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: fxListCardDecoration(
                            context,
                            accent: brand,
                            radius: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _tarefaPersistida
                                        ? Icons.check_circle_outline
                                        : Icons.sync_problem_outlined,
                                    color: brand,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      _tarefaPersistida
                                          ? 'Tarefa salva no ${FocuxMicrocopy.commandCenter}'
                                          : 'Tarefa criada, verifique a lista',
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  IaCopilotTinyTypeChip(
                                    label:
                                        (_proximaAcao!['status'] ?? 'ABERTO')
                                            .toString(),
                                    color: brand,
                                    background: Colors.white.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (_proximaAcao!['acao'] ??
                                        _proximaAcao!['titulo'] ??
                                        _proximaAcao!['mensagem'] ??
                                        'Sem detalhe')
                                    .toString(),
                                style: TextStyle(
                                  color: mute,
                                  fontSize: 12.3,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () => context.push(
                                            '/dashboard/command-center/copiloto',
                                          ),
                                      icon: const Icon(
                                        Icons.space_dashboard_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Ver tarefa'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FxLiquidPrimaryButton(
                                      label: 'Abrir aluno',
                                      icon: Icons.person_outline,
                                      expand: true,
                                      onPressed:
                                          _selectedAlunoId == null
                                              ? null
                                              : () => context.push(
                                                '/alunos/$_selectedAlunoId',
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
