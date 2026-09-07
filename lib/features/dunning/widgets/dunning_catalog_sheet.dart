import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/dunning_repository.dart';
import '../utils/dunning_ops_display.dart';

Future<void> showDunningCatalogSheet(
  BuildContext context, {
  required DunningHomeBundle firstPage,
  required DunningRepository repo,
  required void Function(DunningFalha falha) onAbrir,
}) {
  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _DunningCatalogSheet(
          firstPage: firstPage,
          repo: repo,
          onAbrir: onAbrir,
        ),
  );
}

class _DunningCatalogSheet extends StatefulWidget {
  const _DunningCatalogSheet({
    required this.firstPage,
    required this.repo,
    required this.onAbrir,
  });

  final DunningHomeBundle firstPage;
  final DunningRepository repo;
  final void Function(DunningFalha falha) onAbrir;

  @override
  State<_DunningCatalogSheet> createState() => _DunningCatalogSheetState();
}

class _DunningCatalogSheetState extends State<_DunningCatalogSheet> {
  late List<DunningFalha> _falhas = List.of(widget.firstPage.falhas);
  late int _page = widget.firstPage.page;
  late bool _hasMore = widget.firstPage.hasMore;
  var _loadingMore = false;

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repo.getHome(page: _page + 1);
      if (!mounted) return;
      final seen = _falhas.map((f) => f.id).toSet();
      setState(() {
        _falhas = [
          ..._falhas,
          ...next.falhas.where((f) => seen.add(f.id)),
        ];
        _page = next.page;
        _hasMore = next.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      child: ListView(
        shrinkWrap: true,
        children: [
          FxHomeSheetHeader(
            title: 'Em aberto',
            subtitle: '${widget.firstPage.snapshot.abertas} falhas neste recorte.',
            leading: Icon(Icons.warning_amber_outlined, size: 18, color: primary),
          ),
          if (_falhas.isEmpty)
            const FxEmptyState(
              icon: 'circle-check',
              title: 'Nenhuma falha na lista',
              subtitle: 'As recuperadas saem daqui.',
            )
          else ...[
            for (final falha in _falhas)
              FxSatelliteListTile(
                title: dunningFalhaTitulo(falha.alunoNome, falha.contexto),
                subtitle: Text(
                  dunningFalhaSubtitle(
                    contexto: falha.contexto,
                    alunoNome: falha.alunoNome,
                    motivo: falha.motivo,
                    tentativa: falha.tentativa,
                  ),
                ),
                trailing: Text(
                  dunningMoneyLabel(falha.valor),
                  style: FocuxHubTypography.bodyMuted(
                    color: EagleTokens.bad,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                accent: EagleTokens.bad,
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onAbrir(falha);
                },
              ),
            if (_hasMore)
              FxSatelliteListTile(
                title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                onTap: _loadingMore ? null : _carregarMais,
              ),
          ],
        ],
      ),
    );
  }
}
