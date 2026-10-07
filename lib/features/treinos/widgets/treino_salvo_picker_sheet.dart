import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_option.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../l10n/app_localizations.dart';
import '../data/treino_repository.dart';
import '../providers/treinos_provider.dart';
import 'treino_home_sheet.dart';

/// Templates primeiro, sem os planos de [excluirIds] (já vinculados ao aluno).
List<Treino> planosSalvosParaEscolha(
  List<Treino> treinos, {
  Set<int> excluirIds = const {},
}) {
  final disponiveis = treinos.where((t) => !excluirIds.contains(t.id));
  return [
    ...disponiveis.where((t) => t.isTemplate),
    ...disponiveis.where((t) => !t.isTemplate),
  ];
}

Future<Treino?> showTreinoSalvoPicker(
  BuildContext context, {
  Set<int> excluirIds = const {},
}) {
  return showFxHomeSheet<Treino>(
    context,
    builder:
        (_) => TreinoSalvoPickerSheet(
          isDark: Theme.of(context).brightness == Brightness.dark,
          excluirIds: excluirIds,
        ),
  );
}

class TreinoSalvoPickerSheet extends ConsumerStatefulWidget {
  const TreinoSalvoPickerSheet({
    super.key,
    required this.isDark,
    this.excluirIds = const {},
  });

  final bool isDark;
  final Set<int> excluirIds;

  @override
  ConsumerState<TreinoSalvoPickerSheet> createState() =>
      _TreinoSalvoPickerSheetState();
}

class _TreinoSalvoPickerSheetState
    extends ConsumerState<TreinoSalvoPickerSheet> {
  final _buscaCtrl = TextEditingController();
  Timer? _debounce;
  late Future<List<Treino>> _planos = _carregar('');

  Future<List<Treino>> _carregar(String q) async {
    final repo = ref.read(treinoRepositoryProvider);
    final treinos = <Treino>[];
    for (var page = 0; page < _maxPaginas; page++) {
      final bundle = await repo.getHome(q: q, page: page);
      treinos.addAll(bundle.treinos);
      if (!bundle.hasNext) break;
    }
    return planosSalvosParaEscolha(treinos, excluirIds: widget.excluirIds);
  }

  static const _maxPaginas = 10;

  void _onBusca(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _planos = _carregar(value.trim()));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _buscaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = widget.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final mute = fxScreenMute(context);

    return TreinoHomeSheetSurface(
      isDark: isDark,
      maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: s.treinoPlanoSalvoTitulo,
            subtitle: s.treinoPlanoSalvoUsarSubtitulo,
            leading: Icon(
              Icons.grid_view_rounded,
              color: soft,
              size: FxSettingsLayout.iconSize,
            ),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          TextField(
            controller: _buscaCtrl,
            onChanged: _onBusca,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: s.treinoPlanoSalvoBusca,
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
            ),
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          Flexible(
            child: FutureBuilder<List<Treino>>(
              future: _planos,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const SkeletonList(count: 4);
                }
                final planos = snap.data;
                if (snap.hasError || planos == null || planos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      snap.hasError
                          ? s.treinoPlanoSalvoErro
                          : s.treinoPlanoSalvoVazio,
                      textAlign: TextAlign.center,
                      style: FxSettingsLayout.subhead(color: mute),
                    ),
                  );
                }
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FxSettingsGroup(
                    accent: primary,
                    edgeToEdgeRows: true,
                    children: FxInsetPickerOption.list(
                      accent: soft,
                      items: [
                        for (final plano in planos)
                          FxInsetPickerOptionSpec(
                            label: displayWorkoutName(plano.nome),
                            subtitle: s.treinoPlanoSalvoExercicios(
                              plano.exerciciosCount,
                            ),
                            icon:
                                plano.isTemplate
                                    ? Icons.bookmark_rounded
                                    : Icons.fitness_center_rounded,
                            selected: false,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              Navigator.pop(context, plano);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: FxSettingsLayout.footerAfterGroup),
        ],
      ),
    );
  }
}
