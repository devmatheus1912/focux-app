import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../health/data/health_repository.dart';
import 'package:focux_app/core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final resumoSemanalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).resumoSemanal();
});

/// Parameters for the insights provider.
/// Equality + hashCode ensure Riverpod dedupes by (alunoId, mode).
class InsightsQuery {
  final int? alunoId;
  final String? mode;
  const InsightsQuery({this.alunoId, this.mode});

  @override
  bool operator ==(Object other) =>
      other is InsightsQuery && other.alunoId == alunoId && other.mode == mode;

  @override
  int get hashCode => Object.hash(alunoId, mode);
}

final insightsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, InsightsQuery>((
      ref,
      query,
    ) async {
      return IaRepository(
        ref.read(apiClientProvider),
      ).insights(alunoId: query.alunoId, mode: query.mode);
    });

final proximaAcaoProvider = FutureProvider.family<Map<String, dynamic>, int>((
  ref,
  alunoId,
) async {
  return IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
});

final copilotRecoveryProvider = FutureProvider.family<RecoverySnapshot?, int>((
  ref,
  alunoId,
) async {
  return HealthRepository.fromClient(
    ref.read(apiClientProvider),
  ).fetchRecoveryForAluno(alunoId);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class _CopilotTaskDraft {
  const _CopilotTaskDraft({required this.acao, required this.motivo});

  final String acao;
  final String motivo;
}

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
        return [
          'Objetivo e nível',
          'Foco de volume',
          'Próxima ação sugerida',
        ];
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

  Future<void> _selecionarAluno() async {
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    if (alunos.isEmpty) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(
          content: Text('Você ainda não possui alunos cadastrados.'),
        ),
      );
      return;
    }
    final search = TextEditingController();
    final escolhido = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;
        final cardBg = dark ? EagleTokens.darkCard : TokensStrip.cardBg;
        var query = '';

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered =
                alunos.where((a) {
                  final haystack =
                      '${a.nome} ${a.objetivo ?? ''}'.toLowerCase();
                  return haystack.contains(query.trim().toLowerCase());
                }).toList();

            return Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label:
                  'Selecionar aluno, ${filtered.length} de ${alunos.length}',
              child: DraggableScrollableSheet(
                initialChildSize: 0.58,
                minChildSize: 0.42,
                maxChildSize: 0.82,
                expand: false,
                builder: (ctx, scrollController) {
                  return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  child: DecoratedBox(
                    decoration: fxListCardDecoration(
                      ctx,
                      accent: primary,
                      radius: 28,
                    ),
                    child: SafeArea(
                      top: false,
                      child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                      children: [
                        Center(
                          child: Container(
                            width: 34,
                            height: 4,
                            decoration: BoxDecoration(
                              color: line,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: BrandPalette.soft(primary, dark: dark),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.person_search_outlined,
                                color: primary,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selecionar aluno',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Escolha o aluno para analisar.',
                                    style: TextStyle(
                                      color: mute,
                                      fontSize: 12.2,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: BrandPalette.soft(primary, dark: dark),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${filtered.length}/${alunos.length}',
                                style: TextStyle(
                                  color: primary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TokensStrip.s4),
                        TextField(
                          controller: search,
                          onChanged:
                              (value) => setModalState(() => query = value),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Buscar por nome ou objetivo',
                            prefixIcon: Icon(
                              Icons.search,
                              color: mute,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: cardBg,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: FxInputDeco.outlineBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: line),
                            ),
                            enabledBorder: FxInputDeco.outlineBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: line),
                            ),
                            focusedBorder: FxInputDeco.outlineBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (filtered.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            decoration: fxListCardDecoration(ctx, radius: 18),
                            child: Text(
                              'Nenhum aluno encontrado para essa busca.',
                              style: TextStyle(
                                color: mute,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          )
                        else
                          ...filtered.map((a) {
                            final selected = _selectedAlunoId == a.id;
                            final objetivo =
                                (a.objetivo == null || a.objetivo!.isEmpty)
                                    ? 'Sem objetivo definido'
                                    : a.objetivo!;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => Navigator.of(ctx).pop(a.id),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.all(12),
                                  decoration:
                                      selected
                                          ? fxListCardDecoration(
                                            ctx,
                                            selected: true,
                                            accent: primary,
                                            radius: 18,
                                          )
                                          : fxListCardDecoration(
                                            ctx,
                                            radius: 18,
                                          ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color:
                                              selected
                                                  ? primary
                                                  : BrandPalette.soft(
                                                    primary,
                                                    dark: dark,
                                                  ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            _iniciais(a.nome),
                                            style: TextStyle(
                                              color:
                                                  selected
                                                      ? Colors.white
                                                      : primary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.nome,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: ink,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              objetivo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: mute,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        selected
                                            ? Icons.check_circle
                                            : Icons.chevron_right,
                                        color: selected ? primary : mute,
                                        size: selected ? 22 : 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              );
                },
              ),
            );
          },
        );
      },
    ).whenComplete(search.dispose);
    if (escolhido == null) return;
    final aluno = alunos.firstWhere((a) => a.id == escolhido);
    setState(() {
      _selectedAlunoId = aluno.id;
      _selectedAlunoNome = aluno.nome;
      _gerado = false;
      _erro = null;
      _proximaAcao = null;
      _tarefaCriada = false;
      _tarefaPersistida = false;
    });
  }

  String _iniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final first = partes.first.characters.first;
    final second = partes.length > 1 ? partes.last.characters.first : '';
    return ('$first$second').toUpperCase();
  }

  Future<void> _gerar() async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    setState(() {
      _gerando = true;
      _gerado = false;
      _erro = null;
      _geracaoMs = 0;
      _tarefaCriada = false;
      _tarefaPersistida = false;
    });
    final stopwatch = Stopwatch()..start();
    try {
      await AnalyticsService.instance.track(
        ProductEvents.iaInsightRequested,
        props: {'mode': _mode, 'alunoId': _selectedAlunoId},
      );
      final query = InsightsQuery(alunoId: _selectedAlunoId, mode: _mode);
      ref.invalidate(insightsProvider(query));
      ref.invalidate(resumoSemanalProvider);
      await ref.read(insightsProvider(query).future);
      _proximaAcao = await ref.read(
        proximaAcaoProvider(_selectedAlunoId!).future,
      );
      stopwatch.stop();
      if (mounted) {
        setState(() {
          _gerando = false;
          _gerado = true;
          _geracaoMs = stopwatch.elapsedMilliseconds;
        });
      }
    } catch (e) {
      stopwatch.stop();
      await AnalyticsService.instance.track(
        ProductEvents.iaCopilotFailure,
        props: {
          'mode': _mode,
          'error': e.toString(),
          if (e is IaOperationalException) 'retryable': e.retryable,
          if (e is IaOperationalException && e.reference != null)
            'reference': e.reference,
        },
      );
      if (mounted) {
        setState(() {
          _gerando = false;
          _erro = e;
        });
      }
    }
  }

  String _erroIaTexto(Object erro) {
    if (erro is IaOperationalException) {
      final refText = erro.reference == null ? '' : ' Ref: ${erro.reference}.';
      if (erro.retryable) {
        return '${erro.message}$refText Tente novamente em alguns instantes.';
      }
      return '${erro.message}$refText';
    }
    return 'Não foi possível gerar agora. Tente novamente.';
  }

  Future<void> _atribuir() async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final acaoAtual =
          _proximaAcao ?? await repo.proximaAcao(_selectedAlunoId!);
      final textoAcao =
          (acaoAtual['acao'] ??
                  acaoAtual['titulo'] ??
                  acaoAtual['mensagem'] ??
                  '')
              .toString();
      final motivo = (acaoAtual['motivo'] ?? '').toString();
      final draft = await _confirmarCriarTarefa(
        textoAcao.isEmpty ? 'Revisar aluno no Copiloto' : textoAcao,
        motivo,
      );
      if (draft == null) return;
      final acao = await repo.salvarAcaoCopiloto(
        alunoId: _selectedAlunoId!,
        acao: draft.acao,
        motivo: draft.motivo,
        modo: _mode,
        source: 'COPILOT',
        recommendationId:
            'COPILOT_${_modeDisplay.toUpperCase()}_STUDENT_${_selectedAlunoId!}',
        createdFromInsight: true,
      );
      final actionKey = (acao['actionKey'] ?? '').toString();
      var persisted = actionKey.isNotEmpty;
      if (persisted) {
        try {
          final abertas = await ref
              .read(dashboardRepositoryProvider)
              .getIaCommandActions(status: 'ABERTO', alunoId: _selectedAlunoId);
          persisted = abertas.any((item) => item.actionKey == actionKey);
        } catch (_) {
          persisted = false;
        }
      }
      if (!mounted) return;
      setState(() {
        _proximaAcao = acao;
        _tarefaCriada = true;
        _tarefaPersistida = persisted;
      });
      ref.invalidate(commandCenterProvider);
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text(
            persisted
                ? 'Tarefa salva no Command Center.'
                : 'Tarefa criada. Confirme no Command Center.',
          ),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => context.push('/dashboard/command-center/copiloto'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Não foi possível atribuir agora.')),
      );
    }
  }

  Future<_CopilotTaskDraft?> _confirmarCriarTarefa(
    String acaoInicial,
    String motivoInicial,
  ) async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = dark ? BrandPalette.accent(primary) : primary;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final cardBg = dark ? EagleTokens.darkCard : TokensStrip.cardBg;
    final controller = TextEditingController(text: acaoInicial);

    final result = await showModalBottomSheet<_CopilotTaskDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  ctx,
                  accent: brand,
                  radius: 28,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: brand.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.assignment_turned_in_outlined,
                          color: brand,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Criar tarefa para ${_selectedAlunoNome ?? "aluno"}?',
                              style: TextStyle(
                                color: ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vai para o Command Center. Nada é aplicado automaticamente.',
                              style: TextStyle(
                                color: mute,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  Text(
                    'Ação',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: cardBg,
                      hintText: 'Descreva a tarefa para revisar depois',
                      hintStyle: TextStyle(color: mute),
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: brand, width: 1.2),
                      ),
                    ),
                    style: TextStyle(
                      color: ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CopilotMetaChip(
                        label: 'Destino: Command Center',
                        icon: Icons.space_dashboard_outlined,
                        brand: brand,
                        ink: ink,
                        line: line,
                      ),
                      _CopilotMetaChip(
                        label: 'Prioridade P1',
                        icon: Icons.flag_outlined,
                        brand: brand,
                        ink: ink,
                        line: line,
                      ),
                      _CopilotMetaChip(
                        label: 'SLA 24h',
                        icon: Icons.timer_outlined,
                        brand: brand,
                        ink: ink,
                        line: line,
                      ),
                    ],
                  ),
                  if (motivoInicial.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      motivoInicial,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FxLiquidPrimaryButton(
                          label: 'Criar tarefa',
                          icon: Icons.add_task_outlined,
                          onPressed: () {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            Navigator.of(ctx).pop(
                              _CopilotTaskDraft(
                                acao: text,
                                motivo: motivoInicial.trim(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _abrirMenu() async {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = dark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = dark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = dark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
              child: DecoratedBox(
                decoration: fxListCardDecoration(
                  ctx,
                  accent: primary,
                  radius: TokensStrip.rXl,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: BrandPalette.soft(primary, dark: dark),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.tune_outlined,
                        color: primary,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ações do rascunho',
                            style: TextStyle(
                              color: ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Atualize, troque o aluno ou limpe este resultado.',
                            style: TextStyle(
                              color: mute,
                              fontSize: 12.2,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                _CopilotMenuAction(
                  icon: Icons.person_search_outlined,
                  title: 'Trocar aluno',
                  subtitle: 'Gera um novo rascunho para outra pessoa.',
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('trocar'),
                ),
                _CopilotMenuAction(
                  icon: Icons.refresh_rounded,
                  title: 'Atualizar insights',
                  subtitle: 'Recalcula as recomendações para este aluno.',
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('atualizar'),
                ),
                _CopilotMenuAction(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Limpar resultado',
                  subtitle: 'Volta para o estado inicial do Copiloto.',
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('limpar'),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'trocar':
        await _selecionarAluno();
        break;
      case 'atualizar':
        await _gerar();
        break;
      case 'limpar':
        setState(() {
          _gerado = false;
          _proximaAcao = null;
          _tarefaCriada = false;
          _tarefaPersistida = false;
          _erro = null;
        });
        break;
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

    return FxShellScaffold(
      useMesh: true,
      safeArea: false,
      appBar: FxShellAppBar(
        title: 'Copiloto',
        subtitle: 'IA FOCUX',
        onBack: () => safePopOr(context, () => goToRoleHome(context, ref)),
        actions: [
          _CopilotHeaderStatus(
            dark: dark,
            brand: brand,
            line: line,
            ink: ink,
          ),
        ],
      ),
      bottomNavigationBar:
          _gerado
              ? _CopilotResultActionBar(
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
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 12),
              child: _CopilotStudentSelector(
                alunoNome: _selectedAlunoNome,
                brand: brand,
                ink: ink,
                mute: mute,
                onTap: _selecionarAluno,
              ),
            ),

            // Mode selector
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 14),
              child: _CopilotModeSelector(
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
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 14),
              child: _CopilotReadinessCard(
                headline: _readinessHeadline,
                modeDisplay: _modeDisplay,
                icon: _modeIcon,
                promise: _modePromise,
                checks: _modeChecks,
                alunoNome: _selectedAlunoNome,
                recoveryAsync: _selectedAlunoId == null
                    ? null
                    : ref.watch(copilotRecoveryProvider(_selectedAlunoId!)),
              ),
            ),

            // Safety disclaimer
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 12),
              child: _CopilotSafetyNote(
                ink: ink,
                mute: mute,
                brand: brand,
              ),
            ),

            // Generate button / progress
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 18),
              child:
                  !_gerado && !_gerando
                      ? _CopilotPrimaryAction(
                        label: 'Gerar $_modeDisplay',
                        icon: _modeIcon,
                        brand: brand,
                        primaryDeep: primaryDeep,
                        onTap: _gerar,
                      )
                      : _CopilotGenerationStatus(
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
                padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 18),
                child: _CopilotPreviewCard(
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
                padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        dark
                            ? const Color(0x331F1212)
                            : const Color(0x14E25656),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x33E25656)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFE25656),
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
                        onPressed: _gerar,
                        child: const Text('Tentar'),
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
                  final insightsAsync = ref.watch(insightsProvider(query));
                  return insightsAsync.when(
                    loading:
                        () => Padding(
                          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
                          child: _CopilotInsightsLoading(
                            ink: ink,
                            mute: mute,
                            brand: brand,
                          ),
                        ),
                    error:
                        (e, _) => Padding(
                          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  dark
                                      ? const Color(0x331F1212)
                                      : const Color(0x14E25656),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x33E25656),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Color(0xFFE25656),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _erroIaTexto(e),
                                    style: TextStyle(color: ink, fontSize: 13),
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
                          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: fxListCardDecoration(
                              context,
                              accent: primary,
                              radius: 18,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  style: TextStyle(color: mute, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 16),
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
                                              BrandPalette.deep(primaryDeep),
                                            ]
                                            : [primary, primaryDeep],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'INSIGHTS · ${_mode.toUpperCase()}',
                                      style: const TextStyle(
                                        color: Color(0xB3FFFFFF),
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
                                return _CopilotInsightItem(
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
                                          ? const Color(0x0FFFFFFF)
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
                margin: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, 16, 12),
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
                              dark ? EagleTokens.darkInk : EagleTokens.inkSoft,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_tarefaCriada && _proximaAcao != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 12, 16, 0),
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
                                    ? 'Tarefa salva no Command Center'
                                    : 'Tarefa criada, verifique a lista',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            _CopilotTinyTypeChip(
                              label:
                                  (_proximaAcao!['status'] ?? 'ABERTO')
                                      .toString(),
                              color: brand,
                              background: Colors.white.withValues(alpha: 0.72),
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
    );
  }
}

class _CopilotResultActionBar extends StatelessWidget {
  const _CopilotResultActionBar({
    required this.brand,
    required this.ink,
    required this.onCreateTask,
    required this.onMore,
  });

  final Color brand;
  final Color ink;
  final VoidCallback onCreateTask;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Criar tarefa no Command Center',
                child: FxLiquidPrimaryButton(
                  label: 'Criar tarefa',
                  icon: Icons.assignment_turned_in_outlined,
                  onPressed: onCreateTask,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: 'Mais ações do Copiloto',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMore,
                  borderRadius: BorderRadius.circular(14),
                  child: Ink(
                    width: 50,
                    height: 50,
                    decoration: fxListCardDecoration(
                      context,
                      accent: brand,
                      radius: 14,
                    ),
                    child: Icon(Icons.more_vert, color: ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopilotHeaderStatus extends StatelessWidget {
  const _CopilotHeaderStatus({
    required this.dark,
    required this.brand,
    required this.line,
    required this.ink,
  });

  final bool dark;
  final Color brand;
  final Color line;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(dark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: chrome.headerAction(radius: 999),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: brand, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            'Pronto',
            style: TextStyle(
              color: ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotStudentSelector extends StatelessWidget {
  const _CopilotStudentSelector({
    required this.alunoNome,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.onTap,
  });

  final String? alunoNome;
  final Color brand;
  final Color ink;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = alunoNome != null;

    return Semantics(
      button: true,
      label:
          selected
              ? 'Aluno selecionado, $alunoNome. Toque para trocar.'
              : 'Selecionar aluno',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: fxListCardDecoration(context, accent: brand, radius: 18),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.person_search_outlined, color: brand, size: 18),
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected ? alunoNome! : 'Selecionar aluno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected
                        ? 'Aluno ativo para esta análise'
                        : 'Escolha o aluno para ver recomendações',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mute,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: mute, size: 22),
          ],
        ),
      ),
      ),
    );
  }
}

class _CopilotModeSelector extends StatelessWidget {
  const _CopilotModeSelector({
    required this.modes,
    required this.selectedIndex,
    required this.brand,
    required this.dark,
    required this.line,
    required this.mute,
    required this.onSelect,
  });

  final List<String> modes;
  final int selectedIndex;
  final Color brand;
  final bool dark;
  final Color line;
  final Color mute;
  final ValueChanged<int> onSelect;

  String _label(String mode) => mode == 'Progressão' ? 'Progresso' : mode;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(dark);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: chrome.panel(radius: 16),
      child: Row(
        children:
            modes.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: selected,
                  label: 'Modo ${_label(e.value)}',
                  child: GestureDetector(
                    onTap: () => onSelect(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      height: 38,
                      decoration: BoxDecoration(
                        color: selected ? brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      boxShadow:
                          selected
                              ? [
                                BoxShadow(
                                  color: brand.withValues(alpha: 0.20),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        _label(e.value),
                        style: TextStyle(
                          color: selected ? Colors.white : mute,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _CopilotSafetyNote extends StatelessWidget {
  const _CopilotSafetyNote({
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: fxListCardDecoration(context, accent: brand, radius: 16),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, color: brand, size: 16),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Nada é aplicado automaticamente. Revise antes de usar com o aluno.',
              style: TextStyle(
                color: ink,
                fontSize: 11.6,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Seguro',
            style: TextStyle(
              color: mute,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotMetaChip extends StatelessWidget {
  const _CopilotMetaChip({
    required this.label,
    required this.icon,
    required this.brand,
    required this.ink,
    required this.line,
  });

  final String label;
  final IconData icon;
  final Color brand;
  final Color ink;
  final Color line;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 10, 7),
      decoration: BoxDecoration(
        color: brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 11.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotInsightItem extends StatefulWidget {
  const _CopilotInsightItem({
    required this.index,
    required this.insight,
    required this.isLast,
    required this.highlighted,
    required this.line,
    required this.primarySoft,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.chipBg,
  });

  final int index;
  final Map<String, dynamic> insight;
  final bool isLast;
  final bool highlighted;
  final Color line;
  final Color primarySoft;
  final Color brand;
  final Color ink;
  final Color mute;
  final Color chipBg;

  @override
  State<_CopilotInsightItem> createState() => _CopilotInsightItemState();
}

class _CopilotInsightItemState extends State<_CopilotInsightItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rawTitulo =
        (widget.insight['titulo'] ?? widget.insight['title'] ?? '').toString();
    final titulo =
        rawTitulo.trim().isEmpty ||
                RegExp(
                  r'^insight\s+\d+$',
                  caseSensitive: false,
                ).hasMatch(rawTitulo.trim())
            ? 'Recomendação ${widget.index + 1}'
            : rawTitulo;
    final detalhe =
        (widget.insight['detalhe'] ??
                widget.insight['descricao'] ??
                widget.insight['descrição'] ??
                widget.insight['mensagem'] ??
                '')
            .toString();
    final tipo =
        (widget.insight['tipo'] ?? widget.insight['categoria'] ?? '')
            .toString();

    return Semantics(
      button: detalhe.length > 150,
      label: '$titulo. $tipo. $detalhe',
      child: InkWell(
        onTap:
            detalhe.length > 150
                ? () => setState(() => _expanded = !_expanded)
                : null,
        child: Container(
        margin:
            widget.highlighted
                ? const EdgeInsets.fromLTRB(10, 10, 10, 8)
                : EdgeInsets.zero,
        padding:
            widget.highlighted
                ? const EdgeInsets.all(14)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color:
              widget.highlighted
                  ? widget.primarySoft.withValues(alpha: 0.38)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.highlighted ? 16 : 0),
          border:
              widget.highlighted
                  ? Border.all(color: widget.brand.withValues(alpha: 0.18))
                  : Border(
                    bottom:
                        widget.isLast
                            ? BorderSide.none
                            : BorderSide(color: widget.line, width: 0.5),
                  ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: widget.highlighted ? 38 : 30,
              height: widget.highlighted ? 38 : 30,
              decoration: BoxDecoration(
                color:
                    widget.highlighted
                        ? widget.brand.withValues(alpha: 0.12)
                        : widget.primarySoft,
                borderRadius: BorderRadius.circular(
                  widget.highlighted ? 12 : 9,
                ),
              ),
              child: Center(
                child: Text(
                  '${widget.index + 1}',
                  style: TextStyle(
                    color: widget.brand,
                    fontSize: widget.highlighted ? 13 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.highlighted) ...[
                              Text(
                                'Mais importante',
                                style: TextStyle(
                                  color: widget.brand,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 3),
                            ],
                            Text(
                              titulo,
                              style: TextStyle(
                                color: widget.ink,
                                fontSize: widget.highlighted ? 14 : 13,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tipo.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _CopilotTinyTypeChip(
                          label: tipo,
                          color: widget.mute,
                          background: widget.chipBg,
                        ),
                      ],
                    ],
                  ),
                  if (detalhe.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      detalhe,
                      maxLines: _expanded ? null : (widget.highlighted ? 4 : 2),
                      overflow:
                          _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.mute,
                        fontSize: widget.highlighted ? 12.7 : 12.2,
                        height: widget.highlighted ? 1.42 : 1.34,
                      ),
                    ),
                    if (detalhe.length > 150) ...[
                      const SizedBox(height: 7),
                      Text(
                        _expanded ? 'Ver menos' : 'Ver detalhe',
                        style: TextStyle(
                          color: widget.brand,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CopilotTinyTypeChip extends StatelessWidget {
  const _CopilotTinyTypeChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CopilotReadinessCard extends StatelessWidget {
  const _CopilotReadinessCard({
    required this.headline,
    required this.modeDisplay,
    required this.icon,
    required this.promise,
    required this.checks,
    required this.alunoNome,
    this.recoveryAsync,
  });

  final String headline;
  final String modeDisplay;
  final IconData icon;
  final String promise;
  final List<String> checks;
  final String? alunoNome;
  final AsyncValue<RecoverySnapshot?>? recoveryAsync;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final soft = BrandPalette.soft(primary, dark: dark);
    final visibleChecks = checks.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: chrome.panel(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alunoNome == null
                          ? 'Escolha um aluno para analisar.'
                          : 'Personalizado para $alunoNome.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.8,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: primary.withValues(alpha: 0.14)),
                ),
                child: Text(
                  'Revisável',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            promise,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12.4, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final check in visibleChecks)
                _CopilotPill(
                  icon: Icons.check_rounded,
                  label: check,
                  ink: ink,
                  mute: mute,
                  line: line,
                  soft: soft,
                  brand: primary,
                ),
              if (recoveryAsync != null)
                recoveryAsync!.when(
                  loading: () => _CopilotPill(
                    icon: Icons.watch_outlined,
                    label: 'Sync wearable...',
                    ink: ink,
                    mute: mute,
                    line: line,
                    soft: soft,
                    brand: primary,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (snapshot) {
                    if (snapshot == null) {
                      return _CopilotPill(
                        icon: Icons.watch_off_outlined,
                        label: 'Sem wearable',
                        ink: ink,
                        mute: mute,
                        line: line,
                        soft: soft,
                        brand: primary,
                      );
                    }
                    return _CopilotPill(
                      icon: Icons.favorite_outline,
                      label: '${snapshot.recoveryScore}% prontidao',
                      ink: ink,
                      mute: mute,
                      line: line,
                      soft: soft,
                      brand: primary,
                    );
                  },
                ),
              _CopilotPill(
                icon: Icons.manage_search_outlined,
                label: 'Análise IA',
                ink: ink,
                mute: mute,
                line: line,
                soft: soft,
                brand: primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopilotMenuAction extends StatelessWidget {
  const _CopilotMenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ink,
    required this.mute,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color ink;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: fxListCardDecoration(context, accent: primary, radius: 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: dark),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: mute, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopilotInsightsLoading extends StatelessWidget {
  const _CopilotInsightsLoading({
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final soft = brand.withValues(alpha: 0.10);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: brand, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparando recomendações',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Organizando as recomendações...',
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          for (final width in const [0.92, 0.74, 0.84])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                widthFactor: width,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CopilotPill extends StatelessWidget {
  const _CopilotPill({
    required this.icon,
    required this.label,
    required this.ink,
    required this.mute,
    required this.line,
    required this.soft,
    required this.brand,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final Color mute;
  final Color line;
  final Color soft;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotPrimaryAction extends StatelessWidget {
  const _CopilotPrimaryAction({
    required this.label,
    required this.icon,
    required this.brand,
    required this.primaryDeep,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color brand;
  final Color primaryDeep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [brand, primaryDeep]),
            borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: brand.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _CopilotGenerationStatus extends StatelessWidget {
  const _CopilotGenerationStatus({
    required this.gerando,
    required this.gerado,
    required this.elapsedMs,
    required this.mode,
    required this.ink,
    required this.mute,
    required this.primarySoft,
  });

  final bool gerando;
  final bool gerado;
  final int elapsedMs;
  final String mode;
  final Color ink;
  final Color mute;
  final Color primarySoft;

  @override
  Widget build(BuildContext context) {
    final elapsed =
        elapsedMs >= 1000
            ? '${(elapsedMs / 1000).toStringAsFixed(1)}s'
            : '${elapsedMs}ms';
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2BB673),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    gerando
                        ? 'Gerando recomendações...'
                        : 'Recomendações prontas',
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (!gerando && elapsedMs > 0)
                Text(
                  elapsed,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: gerado ? 1.0 : null,
              minHeight: 6,
              backgroundColor: primarySoft,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2BB673)),
            ),
          ),
          if (gerado) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children:
                  [
                    'Histórico analisado',
                    'Sinais priorizados',
                    'Pronto para sua revisão',
                  ].map((s) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2BB673),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s,
                          style: const TextStyle(
                            color: Color(0xFF2BB673),
                            fontSize: 10.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CopilotPreviewCard extends StatelessWidget {
  const _CopilotPreviewCard({
    required this.howItWorks,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.checks,
  });

  final String howItWorks;
  final Color brand;
  final Color ink;
  final Color mute;
  final List<String> checks;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      container: true,
      label: 'Como funciona o Copiloto. $howItWorks',
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(context, accent: primary, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: brand, size: 18),
              const SizedBox(width: 8),
              Text(
                'Como funciona',
                style: TextStyle(
                  color: ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            howItWorks,
            style: TextStyle(color: mute, fontSize: 12.2, height: 1.45),
          ),
          const SizedBox(height: 12),
          for (final check in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(Icons.check, color: brand, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      check,
                      style: TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }
}
