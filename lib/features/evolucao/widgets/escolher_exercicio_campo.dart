import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../../l10n/pt.dart';

/// Campo do recorde: um toque abre a busca da biblioteca.
class EscolherExercicioCampo extends ConsumerStatefulWidget {
  const EscolherExercicioCampo({super.key, required this.controller});

  final TextEditingController controller;

  @override
  ConsumerState<EscolherExercicioCampo> createState() =>
      _EscolherExercicioCampoState();
}

class _EscolherExercicioCampoState
    extends ConsumerState<EscolherExercicioCampo> {
  Future<void> _escolher() async {
    final nome = await showFxHomeSheet<String>(
      context,
      builder: (_) => const _BuscaExercicio(),
    );
    FxKeyboardDismissScope.dismiss();
    if (nome != null && mounted) {
      setState(() => widget.controller.text = nome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final nome = widget.controller.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Semantics(
        button: true,
        label: nome.isEmpty ? ptS.escolherEscolherExercicio : nome,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          onTap: _escolher,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Icon(Icons.fitness_center_outlined, color: chrome.mute),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: Text(
                    nome.isEmpty ? ptS.escolherEscolherExercicio : nome,
                    style: FocuxHubTypography.body(
                      color: nome.isEmpty ? chrome.mute : chrome.ink,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: chrome.mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuscaExercicio extends ConsumerStatefulWidget {
  const _BuscaExercicio();

  @override
  ConsumerState<_BuscaExercicio> createState() => _BuscaExercicioState();
}

class _BuscaExercicioState extends ConsumerState<_BuscaExercicio> {
  Timer? _espera;
  List<String> _nomes = const [];
  String _termo = '';
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar('');
  }

  void _buscar(String texto) {
    _espera?.cancel();
    _espera = Timer(
      const Duration(milliseconds: 300),
      () => _carregar(texto.trim()),
    );
  }

  /// Sem termo, abre com os favoritos para a folha nunca nascer em branco.
  Future<void> _carregar(String termo) async {
    setState(() {
      _termo = termo;
      _carregando = true;
      _erro = null;
    });
    try {
      final repo = ref.read(exercicioRepositoryProvider);
      var lista =
          termo.isEmpty
              ? await repo.listar(favoritos: true)
              : await repo.listar(nome: termo);
      if (termo.isEmpty && lista.isEmpty) lista = await repo.listar();
      if (!mounted || termo != _termo) return;
      setState(() {
        _nomes = lista.map((e) => e.nome).toList();
        _carregando = false;
      });
    } catch (e) {
      if (!mounted || termo != _termo) return;
      setState(() {
        _erro = friendlyError(e);
        _carregando = false;
      });
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return FxSheetFrame(
      title: ptS.escolherEscolherExercicio,
      expand: true,
      child: Column(
        children: [
          FxSheetSearchField(
            dica: ptS.escolherBuscarExercicio,
            onChanged: _buscar,
          ),
          if (_termo.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FxTonalButton(
                  label: ptS.escolherUsarTexto(_termo),
                  compact: true,
                  onPressed: () => Navigator.pop(context, _termo),
                ),
              ),
            ),
          Expanded(
            child:
                _carregando
                    ? Center(child: FxLoading(color: primary))
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      message: _erro!,
                      onRetry: () => _carregar(_termo),
                    )
                    : _nomes.isEmpty
                    ? Center(
                      child: Text(
                        ptS.escolherNadaEncontrado,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    )
                    : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
