part of 'alerta_detalhe_screen.dart';

extension on _AlertaDetalheScreenState {
  Widget _chips({
    required String nome,
    required Color primary,
    required bool isDark,
  }) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        DashboardHomeActionChip(
          label: 'Lista',
          accent: primary,
          isDark: isDark,
          onPressed: () => safePopOrGo(context, '/alertas'),
        ),
        DashboardHomeActionChip(
          label: 'Aluno',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}',
            extra: nome,
          ),
        ),
        DashboardHomeActionChip(
          label: 'Evolução',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}/evolucao',
            extra: nome,
          ),
        ),
        DashboardHomeActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}/chat',
            extra: nome,
          ),
        ),
      ],
    );
  }
}
