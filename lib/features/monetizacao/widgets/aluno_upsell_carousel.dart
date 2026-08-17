import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/upsell_repository.dart';

final _alunoUpsellProvider = FutureProvider.autoDispose<List<AlunoOferta>>((
  ref,
) {
  return UpsellRepository(ref.read(apiClientProvider)).listarMeusPendentes();
});

/// Ofertas pendentes do personal — exibidas no dashboard do aluno.
class AlunoUpsellCarousel extends ConsumerWidget {
  const AlunoUpsellCarousel({super.key, this.ofertas});

  final List<AlunoOferta>? ofertas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provided = ofertas;
    if (provided != null) {
      return _body(context, ref, provided);
    }
    final async = ref.watch(_alunoUpsellProvider);
    return async.when(
      data: (items) => _body(context, ref, items),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<AlunoOferta> ofertas) {
    if (ofertas.isEmpty) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Ofertas do seu personal',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ofertas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final o = ofertas[i];
              return _OfertaCard(
                oferta: o,
                primary: primary,
                onAccept: () => _responder(context, ref, o, 'ACEITO'),
                onDecline: () => _responder(context, ref, o, 'RECUSADO'),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _responder(
    BuildContext context,
    WidgetRef ref,
    AlunoOferta oferta,
    String resposta,
  ) async {
    try {
      await UpsellRepository(
        ref.read(apiClientProvider),
      ).responder(oferta.alunoOfertaId, resposta);
      await AnalyticsService.instance.track(
        'upsell_aluno_resposta',
        props: {'ofertaId': oferta.ofertaId, 'resposta': resposta},
      );
      ref.invalidate(_alunoUpsellProvider);
      ref.invalidate(alunoDashboardHomeProvider);
      if (context.mounted) {
        FeedbackHelper.showSuccess(
          context,
          resposta == 'ACEITO'
              ? 'Oferta aceita! Seu personal será avisado.'
              : 'Oferta recusada.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        FeedbackHelper.showError(
          context,
          'Não foi possível registrar sua resposta',
        );
      }
    }
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    required this.oferta,
    required this.primary,
    required this.onAccept,
    required this.onDecline,
  });

  final AlunoOferta oferta;
  final Color primary;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final valor = oferta.valor.toStringAsFixed(2).replaceAll('.', ',');
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
        color: primary.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            oferta.titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              oferta.descricao,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            'R\$ $valor',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text('Agora não'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: const Text('Quero'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
