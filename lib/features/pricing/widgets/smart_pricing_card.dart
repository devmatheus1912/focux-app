import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final d = await SmartPricingRepository(ref.read(apiClientProvider)).recomendacao();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: SizedBox(width: 22, height: 22, child: FxLoading(strokeWidth: 2))),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final d = _data!;

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withValues(alpha: 0.15), primary.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph),
              SizedBox(width: 8),
              Text('Smart Pricing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ticket atual: R\$ ${d.ticketAtual.toStringAsFixed(0)} → Sugerido: R\$ ${d.precoSugerido.toStringAsFixed(0)}'),
          const SizedBox(height: 6),
          Text(d.rationale, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
          if (d.pacotesSugeridos.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...d.pacotesSugeridos.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${p.nome}: R\$ ${p.valor.toStringAsFixed(0)} — ${p.descricao}',
                  style: const TextStyle(fontSize: 12)),
            )),
          ],
        ],
      ),
    );
  }
}
