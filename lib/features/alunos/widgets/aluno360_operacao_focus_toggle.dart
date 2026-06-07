import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/fx_shell_scaffold.dart';
import '../providers/aluno_detail_providers.dart';

/// Toggle for Operação focus mode (hides metrics, highlights contact + copilot).
class Aluno360OperacaoFocusModeToggle extends ConsumerWidget {
  const Aluno360OperacaoFocusModeToggle({
    super.key,
    required this.alunoId,
    required this.primary,
    this.compact = false,
    this.iconOnly = false,
  });

  final int alunoId;
  final Color primary;
  final bool compact;
  final bool iconOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusMode = ref.watch(alunoOperacaoFocusModeProvider(alunoId));
    final ink = fxScreenInk(context);

    if (iconOnly) {
      return Semantics(
        button: true,
        label:
            focusMode
                ? 'Desativar modo foco'
                : 'Ativar modo foco — mostra só follow-up e copiloto',
        child: IconButton.filledTonal(
          onPressed:
              () =>
                  ref
                      .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                      .toggle(),
          icon: Icon(
            focusMode ? Icons.center_focus_strong : Icons.center_focus_weak,
            size: 18,
            color: focusMode ? primary : ink.withValues(alpha: 0.78),
          ),
          tooltip:
              focusMode
                  ? 'Modo foco ativo — toque para ver métricas'
                  : 'Modo foco — esconde métricas e destaca contato',
          visualDensity: VisualDensity.compact,
        ),
      );
    }

    if (compact && !focusMode) {
      return Semantics(
        button: true,
        label: 'Ativar modo foco — mostra só follow-up e copiloto',
        child: TextButton(
          onPressed:
              () =>
                  ref
                      .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                      .setFocus(true),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: ink.withValues(alpha: 0.78),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.center_focus_weak, size: 15, color: primary),
              const SizedBox(width: 4),
              const Text(
                'Modo foco',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Semantics(
        button: true,
        label:
            focusMode
                ? 'Desativar modo foco'
                : 'Ativar modo foco — mostra só follow-up e copiloto',
        child: OutlinedButton.icon(
          onPressed:
              () =>
                  ref
                      .read(alunoOperacaoFocusModeProvider(alunoId).notifier)
                      .toggle(),
          icon: Icon(
            focusMode ? Icons.center_focus_strong : Icons.center_focus_weak,
            size: 16,
            color: focusMode ? primary : ink.withValues(alpha: 0.75),
          ),
          label: Text(
            focusMode ? 'Modo foco ativo' : 'Ver diagnóstico completo',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: focusMode ? primary : ink.withValues(alpha: 0.85),
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            visualDensity: VisualDensity.compact,
            foregroundColor: focusMode ? primary : ink.withValues(alpha: 0.85),
            side: BorderSide(
              color: primary.withValues(alpha: focusMode ? 0.32 : 0.22),
            ),
            backgroundColor:
                focusMode ? primary.withValues(alpha: 0.08) : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
