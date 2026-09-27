import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/upsell_repository.dart';

/// Ofertas pendentes do personal na Home do aluno (vêm do BFF).
class AlunoUpsellCarousel extends ConsumerStatefulWidget {
  const AlunoUpsellCarousel({super.key, required this.ofertas});

  final List<AlunoOferta> ofertas;

  @override
  ConsumerState<AlunoUpsellCarousel> createState() =>
      _AlunoUpsellCarouselState();
}

class _AlunoUpsellCarouselState extends ConsumerState<AlunoUpsellCarousel> {
  final Set<int> _enviando = {};

  Future<void> _responder(AlunoOferta oferta, {required bool aceitar}) async {
    if (!_enviando.add(oferta.alunoOfertaId)) return;
    setState(() {});
    final s = S.of(context);
    try {
      await UpsellRepository(
        ref.read(apiClientProvider),
      ).responder(oferta.alunoOfertaId, aceitar ? 'ACEITO' : 'RECUSADO');
      await AnalyticsService.instance.track(
        'upsell_aluno_resposta',
        props: {
          'ofertaId': oferta.ofertaId,
          'resposta': aceitar ? 'ACEITO' : 'RECUSADO',
        },
      );
      if (!mounted) return;
      invalidateAlunoDashboardHome(ref);
      FeedbackHelper.showSuccess(
        context,
        aceitar ? s.alunoOfertaAceita : s.alunoOfertaRecusada,
      );
    } catch (_) {
      if (mounted) FeedbackHelper.showError(context, s.alunoOfertaErro);
    } finally {
      _enviando.remove(oferta.alunoOfertaId);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final ofertas = widget.ofertas;
    if (ofertas.isEmpty) return const SizedBox.shrink();
    Widget card(AlunoOferta o) => _OfertaCard(
      oferta: o,
      enviando: _enviando.contains(o.alunoOfertaId),
      onAccept: () => _responder(o, aceitar: true),
      onDecline: () => _responder(o, aceitar: false),
    );
    // Altura do conteúdo (fonte grande não corta); cards lado a lado alinham.
    final linha = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (ofertas.length == 1)
            Expanded(child: card(ofertas.single))
          else
            for (var i = 0; i < ofertas.length; i++) ...[
              if (i > 0) const SizedBox(width: TokensStrip.s2),
              SizedBox(width: 260, child: card(ofertas[i])),
            ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: S.of(context).alunoOfertasTitulo),
        const SizedBox(height: TokensStrip.s2),
        if (ofertas.length == 1)
          linha
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: linha,
          ),
      ],
    );
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    required this.oferta,
    required this.enviando,
    required this.onAccept,
    required this.onDecline,
  });

  final AlunoOferta oferta;
  final bool enviando;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            oferta.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            oferta.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const Spacer(),
          const SizedBox(height: TokensStrip.s2),
          Text(
            oferta.valor.format(),
            style: FocuxHubTypography.cardTitle(color: primary),
          ),
          const SizedBox(height: TokensStrip.s2),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: enviando ? null : onDecline,
                  child: Text(s.alunoOfertaRecusar),
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: enviando ? null : onAccept,
                  child: Text(s.alunoOfertaAceitar),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
