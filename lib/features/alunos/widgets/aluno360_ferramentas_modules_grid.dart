import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_module_tile.dart';

/// Grid of Ferramentas module shortcuts for Aluno 360.
class Aluno360FerramentasModulesGrid extends StatelessWidget {
  const Aluno360FerramentasModulesGrid({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.isDark,
    required this.perfilCompletion,
    this.bf,
    this.massaMagra,
    this.aderenciaSemanal,
  });

  final Aluno aluno;
  final int alunoId;
  final bool isDark;
  final int perfilCompletion;
  final String? bf;
  final String? massaMagra;
  final List<Map<String, dynamic>>? aderenciaSemanal;

  @override
  Widget build(BuildContext context) {
    final evolucaoRoute = '/alunos/$alunoId/evolucao';
    final primary = Theme.of(context).colorScheme.primary;
    final aderenciaSpark = Aluno360FerramentasLogic.aderenciaSparklineValues(
      aderenciaSemanal,
    );
    final aderenciaPercent = (aluno.aderenciaPercent ?? 0).toDouble();
    final aderenciaColor = EagleTokens.aderenciaColor(
      aderenciaPercent,
      isDark: isDark,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final hasBadgeTile = bf == null && massaMagra == null;
        final aspectRatio = Aluno360FerramentasLogic.modulesGridChildAspectRatio(
          hasBadgeTile: hasBadgeTile,
          textScale: textScale,
        );
        return GridView.count(
          key: const ValueKey('aluno360_ferramentas_modulos'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 10,
          childAspectRatio: aspectRatio,
          children: [
            Aluno360ModuleTile(
              icon: Icons.fitness_center,
              label: 'Treinos',
              sub:
                  aluno.diasSemTreino == null
                      ? 'Histórico'
                      : aluno.diasSemTreino! >= 7
                          ? '${aluno.diasSemTreino}d sem treino'
                          : 'Ativo recentemente',
              isDark: isDark,
              onTap:
                  () => context.push(
                    '/alunos/$alunoId/treinos-list',
                    extra: aluno.nome,
                  ),
            ),
            Aluno360ModuleTile(
              icon: Icons.tune_rounded,
              label: 'Equipamentos',
              sub:
                  aluno.equipamentosDisponiveis.isEmpty
                      ? 'Sem restrição'
                      : '${aluno.equipamentosDisponiveis.length} marcados',
              isDark: isDark,
              onTap: () => context.push('/alunos/$alunoId/equipamentos'),
            ),
            Aluno360ModuleTile(
              icon: Icons.auto_awesome,
              label: 'IA Progresso',
              sub: 'Sugerir carga',
              badge: 'IA',
              highlight: true,
              isDark: isDark,
              onTap:
                  () => context.push(
                    '/alunos/$alunoId/ia/progressao',
                    extra: aluno.nome,
                  ),
            ),
            Aluno360ModuleTile(
              icon: Icons.show_chart,
              label: 'Composição',
              sub:
                  bf != null || massaMagra != null
                      ? 'Última avaliação'
                      : 'Registrar medida',
              badge: bf == null && massaMagra == null ? 'Pendente' : null,
              isDark: isDark,
              onTap: () => context.push(evolucaoRoute, extra: aluno.nome),
            ),
            Aluno360ModuleTile(
              icon: Icons.assessment_outlined,
              label: 'Aderência',
              sub: Aluno360FerramentasLogic.aderenciaModuleSub(
                aluno: aluno,
                aderenciaSemanal: aderenciaSemanal,
              ),
              isDark: isDark,
              trailing: Aluno360FerramentasMiniSparkline(
                data: aderenciaSpark,
                color: aderenciaColor,
                semanticsLabel: Aluno360FerramentasLogic.aderenciaSparkSemanticsLabel(
                  aderenciaSemanal,
                ),
              ),
              onTap:
                  () => context.push(
                    '/alunos/$alunoId/relatorio',
                    extra: aluno.nome,
                  ),
            ),
            Aluno360ModuleTile(
              icon: Icons.flag_outlined,
              label: 'Sucesso',
              sub: 'Acompanhar',
              isDark: isDark,
              onTap:
                  () => context.push(
                    '/alunos/$alunoId/plano-sucesso',
                    extra: aluno.nome,
                  ),
            ),
            Aluno360ModuleTile(
              icon: Icons.people,
              label: 'Anamnese',
              sub: perfilCompletion >= 85 ? 'Completa ✓' : 'Ver status',
              isDark: isDark,
              onTap: () => context.push('/alunos/$alunoId/anamnese'),
            ),
            Aluno360ModuleTile(
              icon: Icons.attach_money,
              label: 'Mensalidades',
              sub:
                  aluno.statusFinanceiro == 'INADIMPLENTE'
                      ? 'Em atraso'
                      : 'Em dia',
              badge:
                  aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Ação' : null,
              isDark: isDark,
              onTap: () => context.push('/financeiro?alunoId=$alunoId'),
            ),
            Aluno360ModuleTile(
              icon: Icons.chat,
              label: 'Chat',
              sub: 'Última ação',
              isDark: isDark,
              onTap:
                  () => context.push(
                    '/alunos/$alunoId/chat',
                    extra: aluno.nome,
                  ),
            ),
            Aluno360ModuleTile(
              icon: Icons.restaurant_menu,
              label: 'Dieta',
              sub: 'Plano atual',
              isDark: isDark,
              onTap: () => context.push('/alunos/$alunoId/alimentar'),
            ),
            Aluno360ModuleTile(
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
        );
      },
    );
  }
}
