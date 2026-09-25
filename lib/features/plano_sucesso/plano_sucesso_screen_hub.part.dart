part of 'plano_sucesso_screen.dart';

extension _PlanoSucessoHub on _PlanoSucessoScreenState {
  List<Widget> _planoMetricTiles({
    required Color primary,
    required bool isDark,
    required String progressoValue,
    required String progressoHint,
    required String etapasValue,
    required String etapasHint,
    required String revisaoValue,
    required String revisaoHint,
    required String statusValue,
    required String statusHint,
  }) {
    Widget tile(String label, String value, String hint) {
      return Padding(
        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
        child: OperationalMetricTile(
          label: label,
          value: value,
          hint: hint,
          color: primary,
          isDark: isDark,
        ),
      );
    }

    return [
      tile('Progresso', progressoValue, progressoHint),
      tile('Etapas', etapasValue, etapasHint),
      tile('Revisão', revisaoValue, revisaoHint),
      tile('Status', statusValue, statusHint),
    ];
  }

  Widget _alunoChips({
    required Color primary,
    required bool isDark,
    VoidCallback? onEditar,
  }) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        if (onEditar != null)
          FxActionChip(
            label: 'Editar',
            accent: primary,
            isDark: isDark,
            onPressed: onEditar,
          ),
        FxActionChip(
          label: 'Lista',
          accent: primary,
          isDark: isDark,
          onPressed: () =>
              safePopOrGo(context, '/alunos/${widget.alunoId}'),
        ),
        FxActionChip(
          label: 'Evolução',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}/evolucao',
            extra: widget.alunoNome,
          ),
        ),
        FxActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push(
            '/alunos/${widget.alunoId}/chat',
            extra: widget.alunoNome,
          ),
        ),
      ],
    );
  }
}
