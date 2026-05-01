import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_sparkline.dart';

class AlunoDetailScreen extends ConsumerWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir aluno'),
            content: Text(
              'Tem certeza que deseja excluir ${aluno.nome}? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlunoRepository(ref.read(apiClientProvider)).excluirAluno(aluno.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aluno excluído.')));
        safePopOrGo(context, '/alunos');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final autonomiaAsync = ref.watch(alunoAutonomiaEventosProvider(alunoId));
    final autonomiaResumoAsync = ref.watch(
      alunoAutonomiaResumoProvider(alunoId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Scaffold(
      backgroundColor: bg,
      body: alunoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          // Fake mock data for UI parity until we get these from backend
          final aderencia = "85%";
          final streak = "12d";
          final prs = "3";
          final treinos = "45";

          return CustomScrollView(
            slivers: [
              // Hero App Bar that stays when scrolling
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, BrandPalette.deep(primary)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    fxInitials(aluno.nome),
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aluno.nome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        aluno.objetivo ?? 'Emagrecimento',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stats Strip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroStat(label: 'Aderência', value: aderencia),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(
                                  label: 'Streak',
                                  value: streak,
                                  icon: Icons.local_fire_department,
                                  iconColor: const Color(0xFFFFD37A),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(label: 'PRs · mês', value: prs),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(label: 'Treinos', value: treinos),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Editar',
                    onPressed: () async {
                      final updated = await context.push<bool>(
                        '/alunos/$alunoId/editar',
                        extra: aluno,
                      );
                      if (updated == true) {
                        ref.invalidate(alunoProvider(alunoId));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Excluir',
                    onPressed: () => _confirmarExclusao(context, ref, aluno),
                  ),
                ],
              ),

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Copiloto IA pronto para sugestões',
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? EagleTokens.darkInk
                                          : EagleTokens.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AutonomiaAlunoCard(
                        eventosAsync: autonomiaAsync,
                        resumoAsync: autonomiaResumoAsync,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // Weight evolution card
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? EagleTokens.darkCard : EagleTokens.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isDark
                                    ? EagleTokens.darkLine
                                    : EagleTokens.line,
                          ),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PESO · ÚLTIMAS 7 SEMANAS',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? EagleTokens.darkInkMute
                                                : EagleTokens.inkMute,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          aluno.peso?.toStringAsFixed(1) ??
                                              '0.0',
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'kg',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? EagleTokens.darkInkMute
                                                    : EagleTokens.inkMute,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? const Color(0x1F6FE296)
                                                    : EagleTokens.goodSoft,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.arrow_downward,
                                                size: 10,
                                                color:
                                                    isDark
                                                        ? const Color(
                                                          0xFF6FE296,
                                                        )
                                                        : EagleTokens.good,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '3.9 kg',
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? const Color(
                                                            0xFF6FE296,
                                                          )
                                                          : EagleTokens.good,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  'Meta · 62 kg',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? EagleTokens.darkInkMute
                                            : EagleTokens.inkMute,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 72,
                              child: FxSparkline(
                                data: const [
                                  68,
                                  67.5,
                                  66.8,
                                  66.0,
                                  65.2,
                                  64.8,
                                  64.1,
                                ],
                                color: primary,
                                fill: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Measurements Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                        children: [
                          _MeasurementCard(
                            label: 'Idade',
                            value: (aluno.idade ?? '--').toString(),
                            unit: 'anos',
                            isDark: isDark,
                          ),
                          _MeasurementCard(
                            label: 'Altura',
                            value: aluno.altura?.toStringAsFixed(2) ?? '--',
                            unit: 'm',
                            isDark: isDark,
                          ),
                          _MeasurementCard(
                            label: 'BF',
                            value: '--',
                            unit: '%',
                            isDark: isDark,
                          ),
                          _MeasurementCard(
                            label: 'M. Magra',
                            value: '--',
                            unit: 'kg',
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Módulos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grid Ferramentas (SaaS Handoff style)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        children: [
                          _ModuleTile(
                            icon: Icons.fitness_center,
                            label: 'Treinos',
                            sub: 'Treinos vinculados',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/treinos-list',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.auto_awesome,
                            label: 'IA · Progressão',
                            sub: 'Sugerir cargas',
                            highlight: true,
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/ia/progressao',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.show_chart,
                            label: 'Evolução',
                            sub: 'Medidas e PRs',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/evolucao',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.people,
                            label: 'Anamnese',
                            sub: 'Completa ✓',
                            isDark: isDark,
                            onTap:
                                () => context.push('/alunos/$alunoId/anamnese'),
                          ),
                          _ModuleTile(
                            icon: Icons.attach_money,
                            label: 'Mensalidades',
                            sub:
                                aluno.statusFinanceiro == 'INADIMPLENTE'
                                    ? 'Em atraso'
                                    : 'Em dia',
                            isDark: isDark,
                            onTap: () => context.push('/financeiro/aluno'),
                          ),
                          _ModuleTile(
                            icon: Icons.chat,
                            label: 'Chat',
                            sub: 'Comunicação',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/chat',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.restaurant_menu,
                            label: 'Dieta',
                            sub: 'Plano atual',
                            isDark: isDark,
                            onTap:
                                () =>
                                    context.push('/alunos/$alunoId/alimentar'),
                          ),
                          _ModuleTile(
                            icon: Icons.video_camera_back,
                            label: 'Feedback',
                            sub: 'Análise de vídeo',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/feedback-video',
                                  extra: aluno.nome,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AutonomiaAlunoCard extends StatelessWidget {
  final AsyncValue<List<AlunoAutonomiaEvento>> eventosAsync;
  final AsyncValue<AlunoAutonomiaResumo> resumoAsync;
  final bool isDark;

  const _AutonomiaAlunoCard({
    required this.eventosAsync,
    required this.resumoAsync,
    required this.isDark,
  });

  String _formatDate(DateTime? value) {
    if (value == null) return '--';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String _actionLabel(String action) {
    switch (action.toUpperCase()) {
      case 'CLICKED':
        return 'Clicou';
      case 'COMPLETED':
        return 'Concluiu';
      case 'VIEWED':
        return 'Viu';
      default:
        return action;
    }
  }

  Color _actionColor(String action, Color fallback) {
    switch (action.toUpperCase()) {
      case 'CLICKED':
        return EagleTokens.warn;
      case 'COMPLETED':
        return EagleTokens.good;
      default:
        return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.fact_check_outlined,
                  color: primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Autonomia do aluno',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Mostra onde o aluno tenta agir sozinho e onde ainda trava.',
                      style: TextStyle(color: mute, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          resumoAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error:
                (_, __) => Text(
                  'Resumo indisponivel agora.',
                  style: TextStyle(color: mute, fontSize: 12.5),
                ),
            data:
                (resumo) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _AutonomiaMetric(
                            label: 'Vistos',
                            value: resumo.vistos.toString(),
                            color: primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AutonomiaMetric(
                            label: 'Cliques',
                            value: resumo.cliques.toString(),
                            color: EagleTokens.warn,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AutonomiaMetric(
                            label: 'Fechados',
                            value: resumo.concluidos.toString(),
                            color: EagleTokens.good,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    if (resumo.gargaloTitulo?.isNotEmpty == true) ...[
                      const SizedBox(height: 10),
                      _AutonomiaBottleneck(
                        resumo: resumo,
                        isDark: isDark,
                        actionLabel: _actionLabel(
                          resumo.gargaloUltimaAcao ?? '',
                        ),
                        dateLabel: _formatDate(resumo.gargaloCriadoEm),
                      ),
                    ],
                  ],
                ),
          ),
          const SizedBox(height: 14),
          eventosAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error:
                (_, __) => Text(
                  'Historico indisponivel agora.',
                  style: TextStyle(color: mute, fontSize: 12.5),
                ),
            data: (eventos) {
              if (eventos.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : BrandPalette.softer(primary),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Sem sinais ainda. Quando o aluno abrir, clicar ou concluir tarefas, o historico aparece aqui.',
                    style: TextStyle(color: mute, height: 1.4),
                  ),
                );
              }

              final recentes = eventos.take(5).toList();
              return Column(
                children: [
                  for (final evento in recentes) ...[
                    _AutonomiaEventoTile(
                      evento: evento,
                      isDark: isDark,
                      actionLabel: _actionLabel(evento.action),
                      actionColor: _actionColor(evento.action, primary),
                      dateLabel: _formatDate(evento.criadoEm),
                    ),
                    if (evento != recentes.last)
                      Divider(color: line, height: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AutonomiaMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _AutonomiaMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? Colors.white.withValues(alpha: 0.04)
            : color.withValues(alpha: 0.08);
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.14);
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AutonomiaBottleneck extends StatelessWidget {
  final AlunoAutonomiaResumo resumo;
  final bool isDark;
  final String actionLabel;
  final String dateLabel;

  const _AutonomiaBottleneck({
    required this.resumo,
    required this.isDark,
    required this.actionLabel,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final bg =
        isDark
            ? Colors.white.withValues(alpha: 0.04)
            : BrandPalette.softer(primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gargalo principal',
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  resumo.gargaloTitulo ?? 'Tarefa do aluno',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _bottleneckHint(resumo.gargaloTaskId),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MiniAutonomyChip(label: actionLabel, color: primary),
                    if (resumo.gargaloPrioridade?.isNotEmpty == true)
                      _MiniAutonomyChip(
                        label: resumo.gargaloPrioridade!,
                        color: mute,
                      ),
                    _MiniAutonomyChip(label: dateLabel, color: mute),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _bottleneckHint(String? taskId) {
  return switch (taskId) {
    'perfil-base' || 'foto-dados' =>
      'Bom ponto para pedir foto, contato ou dados corporais que estao faltando.',
    'medida-recente' =>
      'Vale pedir uma medida recente para manter comparativos confiaveis.',
    'treino-semana' =>
      'Verifique se existe treino ativo ou se o aluno precisa de ajuste.',
    'chat-contexto' =>
      'Abra conversa com uma pergunta simples para reduzir dependencia.',
    'agenda-semana' => 'Confirme agenda e proximos compromissos com o aluno.',
    'financeiro' =>
      'Resolva pendencia financeira antes que vire bloqueio de acesso.',
    _ => 'Abra a ficha e remova a barreira principal desse aluno.',
  };
}

class _AutonomiaEventoTile extends StatelessWidget {
  final AlunoAutonomiaEvento evento;
  final bool isDark;
  final String actionLabel;
  final Color actionColor;
  final String dateLabel;

  const _AutonomiaEventoTile({
    required this.evento,
    required this.isDark,
    required this.actionLabel,
    required this.actionColor,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 9),
          decoration: BoxDecoration(color: actionColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento.taskTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _MiniAutonomyChip(label: actionLabel, color: actionColor),
                  if (evento.priority?.isNotEmpty == true)
                    _MiniAutonomyChip(label: evento.priority!, color: mute),
                  if (evento.profileCompletion != null)
                    _MiniAutonomyChip(
                      label: 'Perfil ${evento.profileCompletion}%',
                      color: mute,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(dateLabel, style: TextStyle(color: mute, fontSize: 11.5)),
      ],
    );
  }
}

class _MiniAutonomyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniAutonomyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _HeroStat({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isDark;

  const _MeasurementCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: mute,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool isDark;
  final bool highlight;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.isDark,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    final bg =
        highlight
            ? (isDark ? EagleTokens.darkCardHi : EagleTokens.brandSoft)
            : cardBg;
    final border = Border.all(
      color: highlight ? primary.withValues(alpha: 0.2) : line,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: highlight ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: highlight ? primary : primary),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: highlight ? primary : ink,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                fontSize: 11.5,
                color: highlight ? BrandPalette.deep(primary) : mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
