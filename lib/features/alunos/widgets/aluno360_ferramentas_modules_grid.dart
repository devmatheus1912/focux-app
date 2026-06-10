import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';
import 'aluno360_module_tile.dart';

/// Grid of Ferramentas module shortcuts for Aluno 360 — grouped by coach workflow.
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

  static const _rowGap = 8.0;
  static const _columnGap = 10.0;
  static const _sectionGap = 14.0;

  Widget _intrinsicRows(List<Widget> tiles) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      final hasPair = i + 1 < tiles.length;
      if (hasPair) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: _columnGap),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
        );
      } else {
        rows.add(tiles[i]);
      }
      if (i + 2 < tiles.length) {
        rows.add(const SizedBox(height: _rowGap));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Aluno360Layout.eyebrowLabelStyle(
            context,
            isDark
                ? EagleTokens.darkInkMute.withValues(alpha: 0.92)
                : TokensStrip.textPrimary.withValues(alpha: 0.76),
          ),
        ),
        const SizedBox(height: 8),
        _intrinsicRows(tiles),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final evolucaoRoute = '/alunos/$alunoId/evolucao';
    final aderenciaSpark = Aluno360FerramentasLogic.aderenciaSparklineValues(
      aderenciaSemanal,
    );
    final aderenciaPercent = (aluno.aderenciaPercent ?? 0).toDouble();
    final aderenciaColor = EagleTokens.aderenciaColor(
      aderenciaPercent,
      isDark: isDark,
    );

    final treinoTiles = [
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
        sub: 'Carga IA',
        badge: 'IA',
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
                : 'Medida',
        badge: bf == null && massaMagra == null ? 'Pend.' : null,
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
        topTrailing: Aluno360FerramentasMiniSparkline(
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
    ];

    final perfilTiles = [
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
        badge: aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Ação' : null,
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
        onTap:
            () => context.push(
              '/alunos/$alunoId/alimentar',
              extra: aluno.nome,
            ),
      ),
      Aluno360ModuleTile(
        icon: Icons.video_camera_back,
        label: 'Feedback',
        sub: 'Vídeo',
        isDark: isDark,
        onTap:
            () => context.push(
              '/alunos/$alunoId/feedback-video',
              extra: aluno.nome,
            ),
      ),
    ];

    return KeyedSubtree(
      key: const ValueKey('aluno360_ferramentas_modulos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(context, 'Treino & evolução', treinoTiles),
          const SizedBox(height: _sectionGap),
          _section(context, 'Perfil & gestão', perfilTiles),
        ],
      ),
    );
  }
}
