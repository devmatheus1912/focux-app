import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_action_row.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/theme/fx_icons.dart';

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
        leading: FxIcons.carteira,
        onTap: abrir,
      );
    }
    return FxSettingsGroup(
      children: [
        FxSettingsTile(
          icon: FxIcons.carteira,
          label: s.financeiroComoRecebe,
          value: s.financeiroChaveCadastrada,
          showDivider: false,
          onTap: abrir,
        ),
      ],
    );
  }
}

/// "Lembretes automáticos": o que o app faz sozinho por cobrança (lembrete
/// semanal ao aluno, aviso ao personal 5 dias antes, atraso marcado de
/// manhã). Só leitura; substitui a antiga "Cobrança automática", que lia
/// falhas de cartão que a cobrança por PIX nunca gera.
class FinanceiroLembretesLinha extends StatelessWidget {
  const FinanceiroLembretesLinha({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return FxSettingsGroup(
      children: [
        FxSettingsTile(
          icon: FxIcons.notificacao,
          label: s.financeiroLembretes,
          value: s.financeiroLembretesValor,
          showDivider: false,
          onTap: () => showFxHomeSheet<void>(
            context,
            builder: (_) => FxSheetFrame(
              title: s.financeiroLembretes,
              leading: Icon(FxIcons.notificacao, size: 20, color: Theme.of(context).colorScheme.primary),
              child: Text(
                s.financeiroLembretesTexto,
                style: FocuxHubTypography.body(color: ShellChrome.of(context).ink),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
