import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Faixa "Adicionado · Desfazer" logo depois de adicionar um exercício.
/// Some sozinha em [duracao]; o botão remove o item recém-criado.
class AddUndoBar extends StatefulWidget {
  const AddUndoBar({
    super.key,
    required this.nome,
    required this.onDesfazer,
    required this.onExpirar,
    this.duracao = const Duration(seconds: 5),
  });

  final String nome;
  final VoidCallback onDesfazer;
  final VoidCallback onExpirar;
  final Duration duracao;

  @override
  State<AddUndoBar> createState() => _AddUndoBarState();
}

class _AddUndoBarState extends State<AddUndoBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duracao, widget.onExpirar);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s1,
          TokensStrip.s2,
          TokensStrip.s1,
        ),
        decoration: BoxDecoration(
          color: chrome.isDark ? EagleTokens.darkCardHi : Colors.white,
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          border: Border.all(color: chrome.lineStrong),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 20, color: chrome.ink),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: Text(
                'Adicionado · ${widget.nome}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.body(
                  color: chrome.ink,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FxTonalButton(
              label: 'Desfazer',
              icon: Icons.undo_rounded,
              compact: true,
              onPressed: () {
                _timer?.cancel();
                widget.onDesfazer();
              },
            ),
          ],
        ),
      ),
    );
  }
}
