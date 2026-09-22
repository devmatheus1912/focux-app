import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/smart_pricing_repository.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class SmartPricingCard extends ConsumerStatefulWidget {
  const SmartPricingCard({super.key});

  @override
  ConsumerState<SmartPricingCard> createState() => _SmartPricingCardState();
}

class _SmartPricingCardState extends ConsumerState<SmartPricingCard> {
  SmartPricingRecomendacao? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d =
          await SmartPricingRepository(
            ref.read(apiClientProvider),
          ).recomendacao();
      if (mounted) {
        setState(() {
          _data = d;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: FxLoading(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mute = Theme.of(context).hintColor;
    final d = _data!;
    final atual = d.ticketAtual.toStringAsFixed(0);
    final sugerido = d.precoSugerido.toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.15),
            primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph, color: primary),
              const SizedBox(width: 8),
              Text(
                'Smart Pricing',
                style: FocuxHubTypography.body(
                  color: onSurface,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(
            'Ticket atual',
            style: FocuxHubTypography.chip(mute),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ $atual',
            style: FocuxHubTypography.kpi(
              color: onSurface,
              fontSize: FocuxHubTypography.metricMd,
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            'Sugerido',
            style: FocuxHubTypography.chip(primary),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ $sugerido',
            style: FocuxHubTypography.kpi(
              color: primary,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            d.rationale,
            style: FocuxHubTypography.bodyMuted(color: mute),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (d.pacotesSugeridos.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s3),
            for (final p in d.pacotesSugeridos.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${p.nome} · R\$ ${p.valor.toStringAsFixed(0)}',
                  style: FocuxHubTypography.bodyMuted(
                    color: onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
          const SizedBox(height: TokensStrip.s3),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push('/pacotes'),
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('Criar pacote sugerido'),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
