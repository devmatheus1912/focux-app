import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/smart_pricing_repository.dart';

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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Builder(
        builder:
            (context) => Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
              child: FxLoading.sectionShimmer(context, height: 128),
            ),
      );
    }
    if (_data == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final d = _data!;
    final atual = d.ticketAtual.toStringAsFixed(0);
    final sugerido = d.precoSugerido.toStringAsFixed(0);
    final delta = d.precoSugerido - d.ticketAtual;
    final deltaLabel =
        delta == 0
            ? 'mantém'
            : delta > 0
            ? '+R\$ ${delta.toStringAsFixed(0)}'
            : '−R\$ ${(-delta).toStringAsFixed(0)}';

    return FxStripCard(
      emphasize: true,
      glowStrength: 0.12,
      padding: const EdgeInsets.all(TokensStrip.s3),
      semanticsLabel:
          'Smart Pricing. Ticket R\$ $atual, sugerido R\$ $sugerido.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Pricing',
                  style: FocuxHubTypography.body(color: chrome.ink).copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.16 : 0.1),
                  borderRadius: BorderRadius.circular(TokensStrip.rPill),
                ),
                child: Text(
                  deltaLabel,
                  style: FocuxHubTypography.chip(primary).copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _PriceCol(
                  label: 'Atual',
                  value: 'R\$ $atual',
                  ink: chrome.mute,
                  valueColor: chrome.ink,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: chrome.mute,
                ),
              ),
              Expanded(
                child: _PriceCol(
                  label: 'Sugerido',
                  value: 'R\$ $sugerido',
                  ink: primary,
                  valueColor: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            d.rationale,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (d.pacotesSugeridos.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s2),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in d.pacotesSugeridos.take(2))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: chrome.line.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    ),
                    child: Text(
                      '${p.nome} · R\$ ${p.valor.toStringAsFixed(0)}',
                      style: FocuxHubTypography.chip(chrome.ink).copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          DashboardHomeActionChip(
            label: 'Criar pacote sugerido',
            accent: primary,
            isDark: isDark,
            onPressed: () => context.push('/pacotes'),
          ),
        ],
      ),
    );
  }
}

class _PriceCol extends StatelessWidget {
  const _PriceCol({
    required this.label,
    required this.value,
    required this.ink,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color ink;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FocuxHubTypography.chip(ink)),
        const SizedBox(height: 2),
        Text(
          value,
          style: FocuxHubTypography.kpi(
            color: valueColor,
            fontSize: FocuxHubTypography.metricMd,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
