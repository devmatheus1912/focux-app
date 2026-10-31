import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../../l10n/pt.dart';

/// Atalho do recorde: escolhe da biblioteca e preenche o nome, que continua editável.
class EscolherExercicioCampo extends ConsumerWidget {
  const EscolherExercicioCampo({super.key, required this.controller});

  final TextEditingController controller;

  Future<void> _escolher(BuildContext context) async {
    final nome = await showFxHomeSheet<String>(
      context,
      builder: (_) => const _BuscaExercicio(),
    );
    if (nome != null) controller.text = nome;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: FxActionLink(
        label: ptS.escolherEscolherDaBiblioteca,
        onTap: () => _escolher(context),
      ),
    ),
  );
}

class _BuscaExercicio extends ConsumerStatefulWidget {
  const _BuscaExercicio();

  @override
  ConsumerState<_BuscaExercicio> createState() => _BuscaExercicioState();
}

class _BuscaExercicioState extends ConsumerState<_BuscaExercicio> {
  Timer? _espera;
  List<String> _nomes = const [];

  void _buscar(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 300), () async {
      final termo = texto.trim();
      final lista =
          termo.length < 2
              ? const <String>[]
              : (await ref.read(exercicioRepositoryProvider).listar(nome: termo))
                  .map((e) => e.nome)
                  .toList();
      if (mounted) setState(() => _nomes = lista);
    });
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return FxSheetFrame(
      title: ptS.escolherEscolherExercicio,
      expand: true,
      child: Column(
        children: [
          FxSheetSearchField(
            dica: ptS.escolherBuscarExercicio,
            autofocus: true,
            onChanged: _buscar,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _nomes.length,
              itemBuilder:
                  (context, i) => ListTile(
                    title: Text(
                      _nomes[i],
                      style: FocuxHubTypography.body(color: chrome.ink),
                    ),
                    onTap: () => Navigator.pop(context, _nomes[i]),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
