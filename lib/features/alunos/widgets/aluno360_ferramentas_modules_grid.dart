import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_logic.dart';

/// Módulos Ferramentas em grupos inset — paridade Perfil (`FxSettingsGroup`).
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
    final aderenciaPercent = (aluno.aderenciaPercent ?? 0).toDouble();

    return KeyedSubtree(
      key: const ValueKey('aluno360_ferramentas_modulos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxSettingsGroup(
            header: 'Treino & evolução',
            children: [
              FxSettingsTile(
                icon: Icons.fitness_center,
                label: 'Treinos',
                subtitle:
                    aluno.diasSemTreino == null
                        ? 'Histórico completo'
                        : aluno.diasSemTreino! >= 7
                        ? '${aluno.diasSemTreino} dias sem treino'
                        : 'Ativo recentemente',
                value: '',
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/treinos-list',
                      extra: aluno.nome,
                    ),
              ),
              FxSettingsTile(
                icon: Icons.tune_rounded,
                label: 'Equipamentos',
                subtitle:
                    aluno.equipamentosDisponiveis.isEmpty
                        ? 'Sem restrição cadastrada'
                        : '${aluno.equipamentosDisponiveis.length} marcados',
                value: '',
                onTap: () => context.push('/alunos/$alunoId/equipamentos'),
              ),
              FxSettingsTile(
                icon: Icons.auto_awesome,
                label: 'IA Progresso',
                subtitle: 'Carga sugerida pela IA',
                value: 'IA',
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/ia/progressao',
                      extra: aluno.nome,
                    ),
              ),
              FxSettingsTile(
                icon: Icons.show_chart,
                label: 'Composição corporal',
                subtitle:
                    bf != null || massaMagra != null
                        ? 'Última avaliação registrada'
                        : 'Registrar medidas',
                value: bf == null && massaMagra == null ? 'Pend.' : '',
                onTap: () => context.push(evolucaoRoute, extra: aluno.nome),
              ),
              FxSettingsTile(
                icon: Icons.assessment_outlined,
                label: 'Aderência',
                subtitle: Aluno360FerramentasLogic.aderenciaModuleSub(
                  aluno: aluno,
                  aderenciaSemanal: aderenciaSemanal,
                ),
                value: '${aderenciaPercent.toInt()}%',
                numeric: true,
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/relatorio',
                      extra: aluno.nome,
                    ),
              ),
              FxSettingsTile(
                icon: Icons.flag_outlined,
                label: 'Plano de sucesso',
                subtitle: 'Metas e marcos do aluno',
                value: '',
                showDivider: false,
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/plano-sucesso',
                      extra: aluno.nome,
                    ),
              ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            header: 'Perfil & gestão',
            children: [
              FxSettingsTile(
                icon: Icons.people,
                label: 'Anamnese',
                subtitle:
                    perfilCompletion >= 85
                        ? 'Perfil completo'
                        : 'Completar cadastro',
                value: perfilCompletion >= 85 ? '✓' : '$perfilCompletion%',
                numeric: perfilCompletion < 85,
                onTap: () => context.push('/alunos/$alunoId/anamnese'),
              ),
              FxSettingsTile(
                icon: Icons.attach_money,
                label: 'Mensalidades',
                subtitle:
                    aluno.statusFinanceiro == 'INADIMPLENTE'
                        ? 'Pagamento em atraso'
                        : 'Em dia',
                value:
                    aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Ação' : 'OK',
                danger: aluno.statusFinanceiro == 'INADIMPLENTE',
                onTap: () => context.push('/financeiro?alunoId=$alunoId'),
              ),
              FxSettingsTile(
                icon: Icons.chat,
                label: 'Chat',
                subtitle: 'Conversa direta com o aluno',
                value: '',
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/chat',
                      extra: aluno.nome,
                    ),
              ),
              FxSettingsTile(
                icon: Icons.restaurant_menu,
                label: 'Dieta',
                subtitle: 'Plano alimentar atual',
                value: '',
                onTap:
                    () => context.push(
                      '/alunos/$alunoId/alimentar',
                      extra: aluno.nome,
                    ),
              ),
              FxSettingsTile(
                icon: Icons.video_camera_back,
                label: 'Feedback em vídeo',
                subtitle: 'Correções e análise de execução',
                value: '',
                showDivider: false,
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
    );
  }
}
