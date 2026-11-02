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
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../../exercicios/data/exercise_enum_api.dart';
import '../../exercicios/providers/exercicios_provider.dart';
import '../../treinos/widgets/exercise_group_chips.dart';

/// `id` nulo: texto livre, fora da biblioteca.
typedef ExercicioEscolhido = ({int? id, String nome});

/// Campo do recorde: um toque abre a biblioteca inteira.
class EscolherExercicioCampo extends StatelessWidget {
  const EscolherExercicioCampo({
    super.key,
    required this.escolhido,
    required this.onEscolher,
    this.recentes = const [],
  });

  final ExercicioEscolhido? escolhido;
  final ValueChanged<ExercicioEscolhido> onEscolher;

  /// Exercícios que este aluno já registrou.
  final List<ExercicioEscolhido> recentes;

  Future<void> _escolher(BuildContext context) async {
    final escolha = await showFxHomeSheet<ExercicioEscolhido>(
      context,
      builder: (_) => BuscaExercicio(recentes: recentes),
    );
    FxKeyboardDismissScope.dismiss();
    if (escolha != null) onEscolher(escolha);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final nome = escolhido?.nome ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Semantics(
        button: true,
        label: nome.isEmpty ? ptS.escolherEscolherExercicio : nome,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          onTap: () => _escolher(context),
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

/// Favoritos, recentes do aluno e toda a biblioteca, paginada.
class BuscaExercicio extends ConsumerStatefulWidget {
  const BuscaExercicio({super.key, this.recentes = const []});

  final List<ExercicioEscolhido> recentes;

  @override
  ConsumerState<BuscaExercicio> createState() => _BuscaExercicioState();
}

class _BuscaExercicioState extends ConsumerState<BuscaExercicio> {
  final _rolagem = ScrollController();
  Timer? _espera;
  String _termo = '';
  GrupoMuscular? _grupo;
  List<Exercicio> _favoritos = const [];
  List<Exercicio> _lista = const [];
  int _pagina = 0;
  bool _temMais = false;
  bool _carregando = true;
  bool _carregandoMais = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _rolagem.addListener(_perto);
    _carregar();
  }

  void _perto() {
    if (_rolagem.position.extentAfter < 240) _carregarMais();
  }

  void _buscar(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 300), () {
      _termo = texto.trim();
      _carregar();
    });
  }

  bool get _semFiltro => _termo.isEmpty && _grupo == null;

  Future<void> _carregar() async {
    final termo = _termo;
    final grupo = _grupo;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final repo = ref.read(exercicioRepositoryProvider);
      final pagina = await repo.listarPickerPagina(
        busca: termo,
        grupoMuscularPrimario: grupo == null ? null : enumQueryParam(grupo),
      );
      final favoritos =
          termo.isEmpty && grupo == null
              ? (await repo.listarPickerPagina(favoritos: true, size: 50)).content
              : const <Exercicio>[];
      if (!mounted || termo != _termo || grupo != _grupo) return;
      setState(() {
        _lista = pagina.content;
        _favoritos = favoritos;
        _pagina = 0;
        _temMais = pagina.content.length >= 30;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted || termo != _termo || grupo != _grupo) return;
      setState(() {
        _erro = friendlyError(e);
        _carregando = false;
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregando || _carregandoMais || !_temMais) return;
    setState(() => _carregandoMais = true);
    try {
      final pagina = await ref.read(exercicioRepositoryProvider).listarPickerPagina(
        busca: _termo,
        grupoMuscularPrimario: _grupo == null ? null : enumQueryParam(_grupo),
        page: _pagina + 1,
      );
      if (!mounted) return;
      final vistos = _lista.map((e) => e.id).toSet();
      setState(() {
        _lista = [..._lista, ...pagina.content.where((e) => vistos.add(e.id))];
        _pagina += 1;
        _temMais = pagina.content.length >= 30;
        _carregandoMais = false;
      });
    } catch (_) {
      if (mounted) setState(() => _carregandoMais = false);
    }
  }

  @override
  void dispose() {
    _espera?.cancel();
    _rolagem.dispose();
    super.dispose();
  }

  Widget _secao(String titulo, ShellPalette chrome) => Padding(
    padding: const EdgeInsets.only(top: TokensStrip.s3, bottom: TokensStrip.s1),
    child: Text(titulo, style: FocuxHubTypography.chip(chrome.mute)),
  );

  Widget _linha(ExercicioEscolhido item, {String? grupo}) => FxSatelliteListTile(
    title: item.nome,
    titleCase: false,
    subtitle: grupo == null ? null : Text(grupo),
    onTap: () => Navigator.pop(context, item),
  );

  Widget _linhaDe(Exercicio e) => _linha(
    (id: e.id, nome: e.nome),
    grupo: TaxonomyLabels.grupo[e.grupoMuscularPrimario],
  );

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return FxSheetFrame(
      title: ptS.escolherEscolherExercicio,
      expand: true,
      rolar: false,
      child: Column(
        children: [
          FxSheetSearchField(
            dica: ptS.escolherBuscarExercicio,
            onChanged: _buscar,
          ),
          const SizedBox(height: TokensStrip.s2),
          ExerciseGroupChips(
            selecionados: {if (_grupo != null) _grupo!},
            noTreino: const {},
            primary: primary,
            isDark: chrome.isDark,
            onToggle: (g) {
              _grupo = _grupo == g ? null : g;
              _carregar();
            },
          ),
          if (_termo.length >= 2)
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FxTonalButton(
                  label: ptS.escolherUsarTexto(_termo),
                  compact: true,
                  onPressed:
                      () => Navigator.pop<ExercicioEscolhido>(
                        context,
                        (id: null, nome: _termo),
                      ),
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
                      onRetry: _carregar,
                    )
                    : _lista.isEmpty && _favoritos.isEmpty
                    ? Center(
                      child: Text(
                        ptS.escolherNadaEncontrado,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    )
                    : ListView(
                      controller: _rolagem,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        if (_semFiltro && _favoritos.isNotEmpty) ...[
                          _secao(ptS.escolherFavoritos, chrome),
                          for (final e in _favoritos) _linhaDe(e),
                        ],
                        if (_semFiltro && widget.recentes.isNotEmpty) ...[
                          _secao(ptS.escolherRecentes, chrome),
                          for (final r in widget.recentes) _linha(r),
                        ],
                        if (_semFiltro) _secao(ptS.escolherTodos, chrome),
                        for (final e in _lista) _linhaDe(e),
                        if (_carregandoMais)
                          Padding(
                            padding: const EdgeInsets.all(TokensStrip.s3),
                            child: Center(child: FxLoading(color: primary)),
                          ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
