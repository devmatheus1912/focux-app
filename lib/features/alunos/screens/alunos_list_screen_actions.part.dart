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
    final primary = Theme.of(context).colorScheme.primary;

    return Semantics(
      label: alunosSelectionTitle(widget.count),
      child: FxHomeSheetScaffold(
        isDark: widget.isDark,
        leading: Icon(Icons.checklist_rounded, color: primary, size: 22),
        title: 'Ações',
        subtitle: 'Status, pagamento ou exclusão.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.mostrarMarcarPago) ...[
              FxSettingsGroup(
                children: [
                  FxSettingsTile(
                    icon: Icons.payments_rounded,
                    label: 'Marcar mensalidade como paga',
                    value: '',
                    highlight: true,
                    showDivider: false,
                    onTap: widget.onMarcarPagos,
                  ),
                ],
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
            ],
            FxSettingsGroup(
              header: 'Status',
              children: [
                for (var i = 0; i < _statusOptions.length; i++)
                  _AlunosSheetCheckRow(
                    icon: switch (_statusOptions[i].value) {
                      'INATIVO' => Icons.pause_circle_outline_rounded,
                      'BLOQUEADO' => Icons.block_rounded,
                      _ => Icons.check_circle_outline_rounded,
                    },
                    label: _statusOptions[i].label,
                    selected: _statusSelecionado == _statusOptions[i].value,
                    showDivider: true,
                    onTap:
                        () => setState(
                          () => _statusSelecionado = _statusOptions[i].value,
                        ),
                  ),
                FxSettingsTile(
                  icon: Icons.done_all_rounded,
                  label: 'Aplicar status',
                  value: '',
                  highlight: !widget.mostrarMarcarPago,
                  showDivider: false,
                  onTap: () => widget.onAtualizarStatus(_statusSelecionado),
                ),
              ],
            ),
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  icon: Icons.delete_outline_rounded,
                  label: 'Excluir selecionados',
                  value: '',
                  danger: true,
                  showDivider: false,
                  onTap: widget.onExcluir,
                ),
              ],
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
