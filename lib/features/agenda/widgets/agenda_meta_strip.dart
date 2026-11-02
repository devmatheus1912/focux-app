import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Data, horário e status: o mesmo bloco para personal e aluno.
class AgendaMetaStrip extends StatelessWidget {
  const AgendaMetaStrip({
    super.key,
    required this.date,
    required this.time,
    required this.status,
  });

  final String date;
  final String time;
  final String status;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: fxListCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _Celula(label: 'Data', value: date)),
              _Divisor(color: primary),
              Expanded(child: _Celula(label: 'Horário', value: time)),
              _Divisor(color: primary),
              Expanded(child: _Celula(label: 'Status', value: status)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divisor extends StatelessWidget {
  const _Divisor({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
    child: VerticalDivider(
      width: 1,
      thickness: 1,
      color: color.withValues(alpha: 0.16),
    ),
  );
}

class _Celula extends StatelessWidget {
  const _Celula({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: FocuxHubTypography.chip(chrome.mute)),
        const SizedBox(height: TokensStrip.s1),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: FocuxHubTypography.bodyMuted(
            color: chrome.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
