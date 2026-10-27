import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../providers/financeiro_provider.dart';

/// "Como você recebe": a chave PIX é pré-requisito de PIX e de recorrência.
/// Sem chave vira um convite com verbo; com chave, uma linha de estado.
class FinanceiroChavePixLinha extends ConsumerWidget {
  const FinanceiroChavePixLinha({super.key, this.soSeFaltar = false});

  /// Na lista de mensalidades só interessa quando falta; em Recorrências
  /// a linha aparece sempre.
  final bool soSeFaltar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final perfil = ref.watch(perfilProvider).value;
    if (perfil == null) return const SizedBox.shrink();
    final tem = (perfil.chavePix ?? '').trim().isNotEmpty;
    if (tem && soSeFaltar) return const SizedBox.shrink();
    void abrir() => context.push('/perfil/wallet');
    if (!tem) {
      return FxActionRow(
        titulo: s.financeiroComoRecebe,
        motivo: s.financeiroChaveFalta,
        verbo: s.financeiroVerboCadastrar,
        leading: Icons.account_balance_wallet_outlined,
        onTap: abrir,
      );
    }
    return FxSettingsGroup(
      children: [
        FxSettingsTile(
          fxIcon: 'wallet',
          label: s.financeiroComoRecebe,
          value: s.financeiroChaveCadastrada,
          showDivider: false,
          onTap: abrir,
        ),
      ],
    );
  }
}

/// "Cobrança automática": liga a tela de falhas e do agendador.
class FinanceiroCobrancaAutoLinha extends ConsumerWidget {
  const FinanceiroCobrancaAutoLinha({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final snapshot = ref.watch(financeiroCobrancaAutoProvider).value;
    final falhas = snapshot?.abertas ?? 0;
    return FxSettingsGroup(
      children: [
        FxSettingsTile(
          fxIcon: 'repeat',
          label: s.financeiroCobrancaAuto,
          value: snapshot == null ? '' : s.financeiroCobrancaAutoStatus(falhas),
          showDivider: false,
          onTap: () => context.push('/dunning'),
        ),
      ],
    );
  }
}
