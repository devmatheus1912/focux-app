import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_row.dart';
import '../providers/dashboard_provider.dart';
import '../constants/dashboard_layout.dart';
import '../utils/hoje_agora.dart';
import 'dashboard_section_header.dart';

/// "Boas notícias": evolução e recorde, fora do "Agora". "Parabenizar" abre o
/// chat do aluno com a mensagem pronta e tira a notícia da Hoje.
class HojeBoasNoticiasSecao extends ConsumerWidget {
  const HojeBoasNoticiasSecao({super.key, required this.noticias});

  final List<HojeBoaNoticia> noticias;

  Future<void> _parabenizar(
    BuildContext context,
    WidgetRef ref,
    HojeBoaNoticia n,
  ) async {
    final id = n.alunoId;
    if (id == null) return;
    try {
      await ref
          .read(dashboardRepositoryProvider)
          .completeCommandAction(n.actionKey);
      invalidatePersonalDashboardHome(ref);
    } catch (_) {
      // Sem rede: o chat abre mesmo assim; a notícia some quando recarregar.
    }
    if (!context.mounted) return;
    final nome = n.titulo.split(' ').first;
    context.push(
      '/alunos/$id/chat',
      extra: {'nome': nome, 'draft': n.rascunho},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (noticias.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DashboardSectionHeader(title: 'Boas notícias'),
          const SizedBox(height: TokensStrip.s2),
          for (final n in noticias.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: TokensStrip.s2),
              child: FxActionRow(
                titulo: n.titulo,
                motivo: n.frase,
                verbo: 'Parabenizar',
                forte: false,
                onTap: () => _parabenizar(context, ref, n),
              ),
            ),
        ],
      ),
    );
  }
}
