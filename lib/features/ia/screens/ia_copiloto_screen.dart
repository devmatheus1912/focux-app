import 'package:flutter/material.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
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
    final escolhido = await showModalBottomSheet<int>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: alunos.length,
              itemBuilder: (ctx, index) {
                final a = alunos[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(a.nome),
                  subtitle: Text(a.objetivo ?? 'Sem objetivo definido'),
                  trailing:
                      _selectedAlunoId == a.id
                          ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2BB673),
                          )
                          : null,
                  onTap: () => Navigator.of(ctx).pop(a.id),
                );
              },
            ),
          ),
    );
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
      final acao = await repo.salvarAcaoCopiloto(
        alunoId: _selectedAlunoId!,
        acao: textoAcao.isEmpty ? 'Revisar aluno no Copiloto' : textoAcao,
        motivo: motivo,
      );
      if (!mounted) return;
      setState(() => _proximaAcao = acao);
      ref.invalidate(commandCenterProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ação atribuída para ${_selectedAlunoNome ?? "aluno"}: ${(acao['acao'] ?? acao['titulo'] ?? 'Próxima ação').toString()}',
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

  Future<void> _abrirMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_search),
                  title: const Text('Trocar aluno'),
                  onTap: () => Navigator.of(ctx).pop('trocar'),
                ),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Atualizar insights'),
                  onTap: () => Navigator.of(ctx).pop('atualizar'),
                ),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('Limpar resultado'),
                  onTap: () => Navigator.of(ctx).pop('limpar'),
                ),
              ],
            ),
          ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 54),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
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
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: primarySoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: brand,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'IA FOCUX',
                                style: TextStyle(
                                  color: brand,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Copiloto',
                            style: TextStyle(
                              color: ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -1.2,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x0FFFFFFF) : EagleTokens.card,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, color: brand, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Copiloto',
                          style: TextStyle(
                            color: ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: GestureDetector(
                onTap: _selecionarAluno,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: line),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.group_outlined, color: brand, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedAlunoNome == null
                              ? 'Selecionar aluno'
                              : 'Aluno selecionado: $_selectedAlunoNome',
                          style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: mute),
                    ],
                  ),
                ),
              ),
            ),

            // Mode selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: dark ? EagleTokens.darkCard : EagleTokens.lineSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children:
                      _modes.asMap().entries.map((e) {
                        final sel = e.key == _modeIdx;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _modeIdx = e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? brand : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow:
                                    sel
                                        ? [
                                          BoxShadow(
                                            color: brand.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: sel ? Colors.white : mute,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),

            // Contexto e preparo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: _CopilotReadinessCard(
                mode: _mode,
                icon: _modeIcon,
                promise: _modePromise,
                checks: _modeChecks,
                alunoNome: _selectedAlunoNome,
              ),
            ),

            // Safety disclaimer
            const IaSafetyDisclaimer(compact: true),
            const SizedBox(height: 4),

            // Generate button / progress
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child:
                  !_gerado && !_gerando
                      ? _CopilotPrimaryAction(
                        label: 'Gerar $_mode',
                        icon: _modeIcon,
                        brand: brand,
                        primaryDeep: primaryDeep,
                        onTap: _gerar,
                      )
                      : _CopilotGenerationStatus(
                        gerando: _gerando,
                        gerado: _gerado,
                        elapsedMs: _geracaoMs,
                        mode: _mode,
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
                        () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
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
                                final titulo =
                                    (ins['titulo'] ??
                                            ins['title'] ??
                                            'Insight ${e.key + 1}')
                                        .toString();
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
                        'Progressão gerada com base no histórico de check-ins e recordes pessoais do aluno.',
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
                                'Atribuir ação',
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

class _CopilotReadinessCard extends StatelessWidget {
  const _CopilotReadinessCard({
    required this.mode,
    required this.icon,
    required this.promise,
    required this.checks,
    required this.alunoNome,
  });

  final String mode;
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rascunho de $mode',
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alunoNome == null
                          ? 'Escolha um aluno para personalizar a análise.'
                          : 'Personalizado para $alunoNome.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
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
          const SizedBox(height: 12),
          Text(
            promise,
            style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final check in checks)
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
