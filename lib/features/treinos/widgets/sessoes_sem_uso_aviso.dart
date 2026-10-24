import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/treinos_provider.dart';

/// Aviso da aba Sessões: "N sessões vazias sem aluno" com a ação de limpar.
/// Só aparece quando há o que limpar. Limpar arquiva; nada é apagado.
class SessoesSemUsoAviso extends ConsumerWidget {
  const SessoesSemUsoAviso({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(sessoesSemUsoProvider).asData?.value ?? 0;
    if (total <= 0) return const SizedBox.shrink();
    final s = S.of(context);
    return FxTapRow(
      title: s.sessoesSemUso(total),
      trailing: Text(s.sessoesSemUsoAcao),
      onTap: () => _limpar(context, ref, total),
    );
  }

  Future<void> _limpar(BuildContext context, WidgetRef ref, int total) async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.sessoesSemUsoTitulo,
      subtitle: s.sessoesSemUso(total),
      message: s.sessoesSemUsoTexto,
      confirmLabel: s.sessoesSemUsoAcao,
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      final arquivadas = await ref.read(treinoRepositoryProvider).arquivarSessoesSemUso();
      invalidateTreinosCaches(ref);
      ref.invalidate(sessoesSemUsoProvider);
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, s.sessoesSemUsoFeito(arquivadas));
      }
    } catch (_) {
      if (context.mounted) FeedbackHelper.showError(context, s.checkinNaoSalvou);
    }
  }
}
