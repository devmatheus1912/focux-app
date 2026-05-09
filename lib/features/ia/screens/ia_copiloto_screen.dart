import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/analytics/analytics_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/ia_repository.dart';

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

  String get _modePromise {
    switch (_mode) {
      case 'Dieta':
        return 'Organiza um rascunho alimentar com objetivo, rotina e pontos de atenção para revisão profissional.';
      case 'Progressão':
        return 'Lê histórico, check-ins e aderência para sugerir ajuste de carga, volume ou frequência.';
      default:
        return 'Monta um rascunho de treino coerente com objetivo, nível, equipamentos e histórico do aluno.';
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
        return ['Histórico recente', 'Sinais de aderência', 'Próxima ação'];
      default:
        return [
          'Objetivo e nível',
          'Volume sugerido',
          'Observações de execução',
        ];
    }
  }

  String get _resultNote {
    switch (_mode) {
      case 'Dieta':
        return 'Dieta gerada como rascunho para revisão profissional, com pontos de atenção antes de aplicar ao aluno.';
      case 'Progressão':
        return 'Progressão gerada com base no histórico de check-ins e recordes pessoais do aluno.';
      default:
        return 'Treino gerado como rascunho editável, com volume, objetivo e observações para revisão do personal.';
    }
  }

  Future<void> _selecionarAluno() async {
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    if (alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
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
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
        final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
        final line = dark ? EagleTokens.darkLine : EagleTokens.line;
        final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
        final surface = dark ? EagleTokens.darkBg : EagleTokens.paper;
        var query = '';

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filtered =
                alunos.where((a) {
                  final haystack =
                      '${a.nome} ${a.objetivo ?? ''}'.toLowerCase();
                  return haystack.contains(query.trim().toLowerCase());
                }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.58,
              minChildSize: 0.42,
              maxChildSize: 0.82,
              expand: false,
              builder: (ctx, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(top: BorderSide(color: line)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.38 : 0.16,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, -12),
                      ),
                    ],
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
                                    'Escolha quem receberá o rascunho da IA.',
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
                        const SizedBox(height: 16),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(color: primary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (filtered.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: line),
                            ),
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
                                  decoration: BoxDecoration(
                                    color:
                                        selected
                                            ? BrandPalette.soft(
                                              primary,
                                              dark: dark,
                                            )
                                            : cardBg,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected ? primary : line,
                                    ),
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
                );
              },
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
      );
      if (!mounted) return;
      setState(() => _proximaAcao = acao);
      ref.invalidate(commandCenterProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tarefa criada para ${_selectedAlunoNome ?? "aluno"} no Command Center.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final surface = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final controller = TextEditingController(text: acaoInicial);

    final result = await showModalBottomSheet<_CopilotTaskDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(top: BorderSide(color: line)),
              ),
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
                  const SizedBox(height: 16),
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: line),
                      ),
                      focusedBorder: OutlineInputBorder(
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
                        child: FilledButton.icon(
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
                          icon: const Icon(Icons.add_task_outlined, size: 17),
                          label: const Text('Criar tarefa'),
                          style: FilledButton.styleFrom(
                            backgroundColor: brand,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final surface = dark ? EagleTokens.darkBg : EagleTokens.paper;

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(top: BorderSide(color: line)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.38 : 0.16),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
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
                const SizedBox(height: 16),
                _CopilotMenuAction(
                  icon: Icons.person_search_outlined,
                  title: 'Trocar aluno',
                  subtitle: 'Gera um novo rascunho para outra pessoa.',
                  cardBg: cardBg,
                  line: line,
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('trocar'),
                ),
                _CopilotMenuAction(
                  icon: Icons.refresh_rounded,
                  title: 'Atualizar insights',
                  subtitle: 'Recalcula as recomendações para este aluno.',
                  cardBg: cardBg,
                  line: line,
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('atualizar'),
                ),
                _CopilotMenuAction(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Limpar resultado',
                  subtitle: 'Volta para o estado inicial do Copiloto.',
                  cardBg: cardBg,
                  line: line,
                  ink: ink,
                  mute: mute,
                  onTap: () => Navigator.of(ctx).pop('limpar'),
                ),
              ],
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
          _erro = null;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: dark);
    final primaryAccent = BrandPalette.accent(primary);
    final primaryDeep = BrandPalette.deep(primary);
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = dark ? primaryAccent : primary;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(82),
        child: SafeArea(
          bottom: false,
          child: Container(
            color: bg,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          () => safePopOr(
                            context,
                            () => goToRoleHome(context, ref),
                          ),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: ink,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Copiloto',
                          style: TextStyle(
                            color: ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: brand, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              'IA FOCUX',
                              style: TextStyle(
                                color: brand,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                _CopilotHeaderStatus(
                  dark: dark,
                  brand: brand,
                  line: line,
                  ink: ink,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        clipBehavior: Clip.hardEdge,
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _CopilotStudentSelector(
                alunoNome: _selectedAlunoNome,
                brand: brand,
                cardBg: cardBg,
                line: line,
                ink: ink,
                mute: mute,
                onTap: _selecionarAluno,
              ),
            ),

            // Mode selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _CopilotReadinessCard(
                modeDisplay: _modeDisplay,
                icon: _modeIcon,
                promise: _modePromise,
                checks: _modeChecks,
                alunoNome: _selectedAlunoNome,
              ),
            ),

            // Safety disclaimer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _CopilotSafetyNote(
                cardBg: cardBg,
                line: line,
                ink: ink,
                mute: mute,
                brand: brand,
              ),
            ),

            // Generate button / progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
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
                        cardBg: cardBg,
                        line: line,
                        ink: ink,
                        mute: mute,
                        primarySoft: primarySoft,
                      ),
            ),

            if (!_gerado && !_gerando && _erro == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: _CopilotPreviewCard(
                  mode: _mode,
                  brand: brand,
                  cardBg: cardBg,
                  line: line,
                  ink: ink,
                  mute: mute,
                  checks: _modeChecks,
                ),
              ),

            // Result card — vinculado ao backend (/api/ia/copiloto/insights)
            if (_erro != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: _CopilotInsightsLoading(
                            cardBg: cardBg,
                            line: line,
                            ink: ink,
                            mute: mute,
                            brand: brand,
                          ),
                        ),
                    error:
                        (e, _) => Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: line),
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: line),
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
                                    'A IA respondeu fora do formato ideal. Mantivemos o resultado como rascunho para revisão.',
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ...insights.asMap().entries.map((e) {
                                final ins = e.value;
                                final rawTitulo =
                                    (ins['titulo'] ?? ins['title'] ?? '')
                                        .toString();
                                final titulo =
                                    rawTitulo.trim().isEmpty ||
                                            RegExp(
                                              r'^insight\s+\d+$',
                                              caseSensitive: false,
                                            ).hasMatch(rawTitulo.trim())
                                        ? 'Recomendação ${e.key + 1}'
                                        : rawTitulo;
                                final detalhe =
                                    (ins['detalhe'] ??
                                            ins['descricao'] ??
                                            ins['descrição'] ??
                                            ins['mensagem'] ??
                                            '')
                                        .toString();
                                final tipo =
                                    (ins['tipo'] ?? ins['categoria'] ?? '')
                                        .toString();
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom:
                                          e.key < insights.length - 1
                                              ? BorderSide(
                                                color: line,
                                                width: 0.5,
                                              )
                                              : BorderSide.none,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: primarySoft,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${e.key + 1}',
                                            style: TextStyle(
                                              color: brand,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
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
                                              titulo,
                                              style: TextStyle(
                                                color: ink,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (detalhe.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                detalhe,
                                                style: TextStyle(
                                                  color: mute,
                                                  fontSize: 11.5,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (tipo.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                dark
                                                    ? const Color(0x0FFFFFFF)
                                                    : EagleTokens.lineSoft,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            tipo,
                                            style: TextStyle(
                                              color: mute,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color:
                      dark
                          ? EagleTokens.darkCardHi
                          : BrandPalette.softer(brand),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: brand.withValues(alpha: 0.18)),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _atribuir,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: brand,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: brand.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.assignment_turned_in_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Criar tarefa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _abrirMenu,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: line),
                        ),
                        child: Icon(Icons.more_vert, color: ink),
                      ),
                    ),
                  ],
                ),
              ),
              if (_proximaAcao != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: Text(
                      'Próxima ação: ${(_proximaAcao!['acao'] ?? _proximaAcao!['titulo'] ?? _proximaAcao!['mensagem'] ?? 'Sem detalhe').toString()}',
                      style: TextStyle(color: ink, fontSize: 12.5),
                    ),
                  ),
                ),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark ? const Color(0x0FFFFFFF) : EagleTokens.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.16 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
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
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.onTap,
  });

  final String? alunoNome;
  final Color brand;
  final Color cardBg;
  final Color line;
  final Color ink;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = alunoNome != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
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
                        : 'Escolha para personalizar o rascunho',
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? EagleTokens.darkCard : EagleTokens.lineSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children:
            modes.asMap().entries.map((e) {
              final selected = e.key == selectedIndex;
              return Expanded(
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
              );
            }).toList(),
      ),
    );
  }
}

class _CopilotSafetyNote extends StatelessWidget {
  const _CopilotSafetyNote({
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color cardBg;
  final Color line;
  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
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

class _CopilotReadinessCard extends StatelessWidget {
  const _CopilotReadinessCard({
    required this.modeDisplay,
    required this.icon,
    required this.promise,
    required this.checks,
    required this.alunoNome,
  });

  final String modeDisplay;
  final IconData icon;
  final String promise;
  final List<String> checks;
  final String? alunoNome;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final soft = BrandPalette.soft(primary, dark: dark);
    final visibleChecks = checks.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.20 : 0.045),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
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
                      'Rascunho de $modeDisplay',
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
                          ? 'Escolha um aluno para personalizar.'
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
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color line;
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
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
          ),
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
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color cardBg;
  final Color line;
  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final soft = brand.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
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
                      'Organizando os achados antes de mostrar o rascunho.',
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
          const SizedBox(height: 16),
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
    return GestureDetector(
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
    );
  }
}

class _CopilotGenerationStatus extends StatelessWidget {
  const _CopilotGenerationStatus({
    required this.gerando,
    required this.gerado,
    required this.elapsedMs,
    required this.mode,
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.primarySoft,
  });

  final bool gerando;
  final bool gerado;
  final int elapsedMs;
  final String mode;
  final Color cardBg;
  final Color line;
  final Color ink;
  final Color mute;
  final Color primarySoft;

  @override
  Widget build(BuildContext context) {
    final elapsed =
        elapsedMs >= 1000
            ? '${(elapsedMs / 1000).toStringAsFixed(1)}s'
            : '${elapsedMs}ms';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
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
                    gerando ? 'Gerando rascunho...' : 'Rascunho gerado',
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
                    'Carga calibrada',
                    '$mode pronto para revisão',
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
    required this.mode,
    required this.brand,
    required this.cardBg,
    required this.line,
    required this.ink,
    required this.mute,
    required this.checks,
  });

  final String mode;
  final Color brand;
  final Color cardBg;
  final Color line;
  final Color ink;
  final Color mute;
  final List<String> checks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_outlined, color: brand, size: 18),
              const SizedBox(width: 8),
              Text(
                'Antes de gerar',
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
            'O Copiloto entrega um rascunho de $mode. O personal revisa, edita e só depois aplica no atendimento.',
            style: TextStyle(color: mute, fontSize: 12.2, height: 1.4),
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
    );
  }
}
