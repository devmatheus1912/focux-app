import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_sparkline.dart';

class AlunoDetailScreen extends ConsumerWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  Future<void> _confirmarExclusao(BuildContext context, WidgetRef ref, Aluno aluno) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir aluno'),
        content: Text('Tem certeza que deseja excluir ${aluno.nome}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno excluído.')),
        );
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
                expandedHeight: 320,
                pinned: true,
                backgroundColor: isDark ? const Color(0xFF0F1E4A) : EagleTokens.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark 
                            ? [const Color(0xFF1C3273), const Color(0xFF0F1E4A)]
                            : [EagleTokens.brand, EagleTokens.brandDeep],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 72, height: 72,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    fxInitials(aluno.nome),
                                    style: const TextStyle(color: EagleTokens.brand, fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('DESDE 2024', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                                      Text(aluno.nome, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('${aluno.objetivo ?? 'Emagrecimento'} · ${aluno.email}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Stats Strip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroStat(label: 'Aderência', value: aderencia),
                                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                                _HeroStat(label: 'Streak', value: streak, icon: Icons.local_fire_department, iconColor: const Color(0xFFFFD37A)),
                                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
                                _HeroStat(label: 'PRs · mês', value: prs),
                                Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.2)),
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
                      final updated = await context.push<bool>('/alunos/$alunoId/editar', extra: aluno);
                      if (updated == true) ref.invalidate(alunoProvider(alunoId));
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
                  padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: EagleTokens.brand.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Icons.auto_awesome, color: EagleTokens.brand, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Copiloto IA pronto para sugestões', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 13, fontWeight: FontWeight.w500))),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Weight evolution card
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
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
                                    Text('PESO · ÚLTIMAS 7 SEMANAS', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(aluno.peso?.toStringAsFixed(1) ?? '0.0', style: TextStyle(color: ink, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
                                        const SizedBox(width: 3),
                                        Text('kg', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 14, fontWeight: FontWeight.w400)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0x1F6FE296) : EagleTokens.goodSoft,
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Icons.arrow_downward, size: 10, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good),
                                              const SizedBox(width: 3),
                                              Text('3.9 kg', style: TextStyle(color: isDark ? const Color(0xFF6FE296) : EagleTokens.good, fontSize: 12, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text('Meta · 62 kg', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11.5, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 72,
                              child: FxSparkline(
                                data: const [68, 67.5, 66.8, 66.0, 65.2, 64.8, 64.1],
                                color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand,
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
                          _MeasurementCard(label: 'Idade', value: (aluno.idade ?? '--').toString(), unit: 'anos', isDark: isDark),
                          _MeasurementCard(label: 'Altura', value: aluno.altura?.toStringAsFixed(2) ?? '--', unit: 'm', isDark: isDark),
                          _MeasurementCard(label: 'BF', value: '--', unit: '%', isDark: isDark),
                          _MeasurementCard(label: 'M. Magra', value: '--', unit: 'kg', isDark: isDark),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text('Ferramentas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink, letterSpacing: -0.5)),
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
                          _ModuleTile(icon: Icons.fitness_center, label: 'Treinos', sub: 'Push A ativo', isDark: isDark, onTap: () => context.go('/treinos')),
                          _ModuleTile(icon: Icons.auto_awesome, label: 'IA · Progressão', sub: 'Sugerir cargas', highlight: true, isDark: isDark, onTap: () => context.push('/alunos/$alunoId/ia/progressao', extra: aluno.nome)),
                          _ModuleTile(icon: Icons.show_chart, label: 'Evolução', sub: 'Medidas e PRs', isDark: isDark, onTap: () => context.push('/alunos/$alunoId/evolucao', extra: aluno.nome)),
                          _ModuleTile(icon: Icons.people, label: 'Anamnese', sub: 'Completa ✓', isDark: isDark, onTap: () => context.push('/alunos/$alunoId/anamnese')),
                          _ModuleTile(icon: Icons.attach_money, label: 'Mensalidades', sub: aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Em atraso' : 'Em dia', isDark: isDark, onTap: () => context.push('/financeiro/aluno')),
                          _ModuleTile(icon: Icons.chat, label: 'Chat', sub: 'Comunicação', isDark: isDark, onTap: () => context.push('/alunos/$alunoId/chat', extra: aluno.nome)),
                          _ModuleTile(icon: Icons.restaurant_menu, label: 'Dieta', sub: 'Plano atual', isDark: isDark, onTap: () => context.push('/alunos/$alunoId/alimentar')),
                          _ModuleTile(icon: Icons.video_camera_back, label: 'Feedback', sub: 'Análise de vídeo', isDark: isDark, onTap: () => context.push('/alunos/$alunoId/feedback-video', extra: aluno.nome)),
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

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _HeroStat({required this.label, required this.value, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
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
            style: TextStyle(color: mute, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.0),
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
                style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(width: 2),
              Text(unit, style: TextStyle(color: mute, fontSize: 10, fontWeight: FontWeight.w500)),
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
    required this.icon, required this.label, required this.sub, 
    required this.isDark, this.highlight = false, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final accent = isDark ? EagleTokens.brandAccent : EagleTokens.brand;

    final bg = highlight ? (isDark ? const Color(0xFF1C3273) : EagleTokens.brandSoft) : cardBg;
    final border = Border.all(color: highlight ? Colors.transparent : line);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: border),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: highlight 
                    ? (isDark ? Colors.white.withValues(alpha: 0.12) : EagleTokens.brand) 
                    : (isDark ? EagleTokens.brandAccent.withValues(alpha: 0.12) : EagleTokens.brandSofter),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: highlight ? Colors.white : accent),
            ),
            const Spacer(),
            Text(label, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: highlight && !isDark ? EagleTokens.brand : ink, letterSpacing: -0.2)),
            Text(sub, style: TextStyle(fontSize: 11.5, color: highlight && !isDark ? EagleTokens.brandInk : mute)),
          ],
        ),
      ),
    );
  }
}

