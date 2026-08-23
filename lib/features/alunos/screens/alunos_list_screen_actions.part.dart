part of 'alunos_list_screen.dart';

class _AlunosTriageBanner extends StatelessWidget {
  final int count;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _AlunosTriageBanner({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final warn = isDark ? EagleTokens.warnAccent : EagleTokens.warn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: fxStripCardDecoration(
            context,
            accent: warn,
            radius: TokensStrip.rCard,
            glowStrength: AlunosLayout.chipGlowStrength,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: warn.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 18, color: warn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: FocuxHubTypography.sectionTitle(
                        context,
                        color: ink,
                      ).copyWith(fontSize: TokensStrip.fontBodySm),
                    ),
                    Text(
                      subtitle,
                      style: FocuxHubTypography.bodyMuted(
                        color: mute,
                      ).copyWith(fontSize: 11.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              Text(
                AlunosMicrocopy.focarAgora,
                style: FocuxHubTypography.bodyMuted(
                  color: BrandPalette.sectionLink(primary, dark: isDark),
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: BrandPalette.sectionLink(primary, dark: isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlunosBulkActionsSheet extends StatefulWidget {
  final int count;
  final bool isDark;
  final bool mostrarMarcarPago;
  final VoidCallback onMarcarPagos;
  final void Function(String status) onAtualizarStatus;
  final VoidCallback onExcluir;

  const _AlunosBulkActionsSheet({
    required this.count,
    required this.isDark,
    required this.mostrarMarcarPago,
    required this.onMarcarPagos,
    required this.onAtualizarStatus,
    required this.onExcluir,
  });

  @override
  State<_AlunosBulkActionsSheet> createState() =>
      _AlunosBulkActionsSheetState();
}

class _AlunosBulkActionsSheetState extends State<_AlunosBulkActionsSheet> {
  String _statusSelecionado = 'ATIVO';

  static const _statusOptions = <({String value, String label})>[
    (value: 'ATIVO', label: 'Ativo'),
    (value: 'INATIVO', label: 'Inativo'),
    (value: 'BLOQUEADO', label: 'Bloqueado'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final primary = Theme.of(context).colorScheme.primary;
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

    return FxHomeSheetSurface(
      isDark: widget.isDark,
      maxHeight: maxHeight,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: widget.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: widget.isDark,
              title: alunosSelectionTitle(widget.count),
              subtitle: 'Ações em lote para os alunos selecionados.',
              leading: Icon(Icons.checklist_rounded, color: primary, size: 18),
            ),
            const SizedBox(height: 18),
            if (widget.mostrarMarcarPago) ...[
              Semantics(
                button: true,
                label: 'Marcar mensalidade como paga',
                child: SizedBox(
                  height: AlunosLayout.touchTarget,
                  child: FilledButton.icon(
                    onPressed: widget.onMarcarPagos,
                    icon: const Icon(Icons.payments_rounded, size: 18),
                    label: const Text('Marcar mensalidade como paga'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              'Atualizar status',
              style: FocuxHubTypography.eyebrow(
                context,
                color: ink,
                fontWeight: FontWeight.w700,
              ).copyWith(fontSize: TokensStrip.fontBodySm),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _statusOptions)
                  Semantics(
                    button: true,
                    selected: _statusSelecionado == option.value,
                    label: 'Status ${option.label}',
                    child: _SheetShortcutChip(
                      label: option.label,
                      selected: _statusSelecionado == option.value,
                      onTap:
                          () =>
                              setState(() => _statusSelecionado = option.value),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: AlunosLayout.touchTarget,
              child:
                  widget.mostrarMarcarPago
                      ? OutlinedButton.icon(
                        onPressed:
                            () => widget.onAtualizarStatus(_statusSelecionado),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Aplicar status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(
                            color: primary.withValues(alpha: 0.28),
                          ),
                          shape: const StadiumBorder(),
                        ),
                      )
                      : FilledButton.icon(
                        onPressed:
                            () => widget.onAtualizarStatus(_statusSelecionado),
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Aplicar status'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                      ),
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: 'Excluir alunos selecionados',
              child: SizedBox(
                height: AlunosLayout.touchTarget,
                child: OutlinedButton.icon(
                  onPressed: widget.onExcluir,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir selecionados'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EagleTokens.bad,
                    side: BorderSide(
                      color: EagleTokens.bad.withValues(alpha: 0.45),
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
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
class _ExcluirAlunosSheet extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ExcluirAlunosSheet({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

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
              Icons.delete_outline_rounded,
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
          SizedBox(
            width: double.infinity,
            height: AlunosLayout.touchTarget,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('Excluir $count ${count == 1 ? 'aluno' : 'alunos'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EagleTokens.bad,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: AlunosLayout.touchTarget,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  FxHomeSheetChrome.touchTarget,
                  FxHomeSheetChrome.touchTarget,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(color: mute, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
