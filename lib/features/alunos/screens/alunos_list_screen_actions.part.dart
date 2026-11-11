part of 'alunos_list_screen.dart';

class _AlunosBulkActionsSheet extends StatefulWidget {
  final int count;
  final bool isDark;
  final bool mostrarMarcarPago;
  final String? statusAtual;
  final VoidCallback onMarcarPagos;
  final void Function(String status) onAtualizarStatus;
  final VoidCallback onExcluir;

  const _AlunosBulkActionsSheet({
    required this.count,
    required this.isDark,
    required this.mostrarMarcarPago,
    this.statusAtual,
    required this.onMarcarPagos,
    required this.onAtualizarStatus,
    required this.onExcluir,
  });

  @override
  State<_AlunosBulkActionsSheet> createState() =>
      _AlunosBulkActionsSheetState();
}

class _AlunosBulkActionsSheetState extends State<_AlunosBulkActionsSheet> {
  String? _statusSelecionado;

  /// As mesmas ações do 360 (Reativar, Pausar, Bloquear acesso), a partir do
  /// status comum da seleção; seleção misturada mostra as três.
  List<({String value, String label})> get _statusOptions {
    final atual = widget.statusAtual;
    final valores = atual == null
        ? const [AlunoStatus.ativo, AlunoStatus.inativo, AlunoStatus.bloqueado]
        : alunoStatusAcoesDisponiveis(atual);
    return [
      for (final v in valores) (value: v, label: alunoStatusAcaoLabel(v)),
    ];
  }

  String? _statusSubtitle(String status) {
    if (status == widget.statusAtual) return 'Status atual';
    return alunoStatusExplicacao(status);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: alunosSelectionTitle(widget.count),
      child: FxHomeSheetScaffold(
        isDark: widget.isDark,
        leading: Icon(FxIcons.checklist, color: primary, size: 22),
        title: 'Ações',
        subtitle: 'Status, pagamento ou exclusão.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mostrarMarcarPago) ...[
              FxLiquidSecondaryButton(
                label: 'Marcar mensalidade como paga',
                onPressed: widget.onMarcarPagos,
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
            ],
            FxSettingsGroup(
              header: 'Status',
              caption: 'Escolha a ação e confirme.',
              edgeToEdgeRows: true,
              semMoldura: true,
              accent: Theme.of(context).colorScheme.primary,
              children: FxInsetPickerOption.list(
                accent: BrandPalette.softened(
                  Theme.of(context).colorScheme.primary,
                ),
                items: [
                  for (var i = 0; i < _statusOptions.length; i++)
                    FxInsetPickerOptionSpec(
                      label: _statusOptions[i].label,
                      subtitle: _statusSubtitle(_statusOptions[i].value),
                      icon: alunoStatusIcon(_statusOptions[i].value),
                      selected: _statusSelecionado == _statusOptions[i].value,
                      onTap:
                          () => setState(
                            () => _statusSelecionado = _statusOptions[i].value,
                          ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxLiquidPrimaryButton(
              label: _statusSelecionado == null
                  ? 'Aplicar'
                  : alunoStatusAcaoLabel(_statusSelecionado!),
              onPressed:
                  _statusSelecionado == null ||
                          _statusSelecionado == widget.statusAtual
                      ? null
                      : () => widget.onAtualizarStatus(_statusSelecionado!),
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            _DestructiveSheetButton(
              label: 'Excluir selecionados',
              onPressed: widget.onExcluir,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Premium delete confirmation bottom sheet
// ──────────────────────────────────────────────
class _DestructiveSheetButton extends StatelessWidget {
  const _DestructiveSheetButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Material(
        color: EagleTokens.bad,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: TokensStrip.fontBody,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExcluirAlunosSheet extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ExcluirAlunosSheet({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {

    final label =
        count == 1
            ? '1 aluno selecionado será excluído permanentemente.'
            : '$count alunos selecionados serão excluídos permanentemente.';

    return FxHomeSheetSurface(
      isDark: isDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Excluir alunos?',
            subtitle: label,
            leading: const Icon(
              FxIcons.excluir,
              color: EagleTokens.bad,
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Esta ação não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(
              color: EagleTokens.bad.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          _DestructiveSheetButton(
            label: 'Excluir $count ${count == 1 ? 'aluno' : 'alunos'}',
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop(true);
            },
          ),
          const SizedBox(height: 10),
          FxTonalButton(label: 'Cancelar', onPressed: () => Navigator.of(context).pop(false), compact: true),
        ],
      ),
    );
  }
}
