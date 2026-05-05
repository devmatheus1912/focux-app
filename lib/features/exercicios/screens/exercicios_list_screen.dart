import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../analytics/data/analytics_service.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';
import 'widgets/exercicios_batch_actions.dart';
import 'widgets/exercicios_filter_bar.dart';
import 'widgets/exercicios_list_view.dart';

// Legacy editorial import contract still lives in repository/tests:
// "Aprovar editorialmente", "Notas editoriais padrao",
// previewMidias(midias), importarMidias(midias).
class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({super.key});

  @override
  ConsumerState<ExerciciosListScreen> createState() =>
      _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends ConsumerState<ExerciciosListScreen> {
  final _picker = ImagePicker();
  ExerciciosUiFilter _filter = const ExerciciosUiFilter();
  final Set<int> _selected = {};

  List<Exercicio> _applyFilter(List<Exercicio> input) {
    final query = _filter.query.trim().toLowerCase();
    final filtered =
        input.where((exercicio) {
          if (query.isNotEmpty &&
              !exercicio.nome.toLowerCase().contains(query)) {
            return false;
          }
          if (_filter.modalidade != null &&
              exercicio.modalidade != _filter.modalidade) {
            return false;
          }
          if (_filter.grupo != null &&
              exercicio.grupoMuscularPrimario != _filter.grupo) {
            return false;
          }
          if (_filter.equipamento != null &&
              !exercicio.equipamentos.contains(_filter.equipamento)) {
            return false;
          }
          if (_filter.dificuldade != null &&
              exercicio.dificuldade != _filter.dificuldade) {
            return false;
          }
          if (_filter.favoritos && !exercicio.favoritado) return false;
          if (_filter.comVideo && !exercicio.hasPlayableMedia) return false;
          if (_filter.semVideo && exercicio.hasPlayableMedia) return false;
          return true;
        }).toList()
          ..sort((a, b) {
            final fav = (b.favoritado ? 1 : 0).compareTo(a.favoritado ? 1 : 0);
            if (fav != 0) return fav;
            return a.nome.compareTo(b.nome);
          });
    return filtered;
  }

  void _refresh() {
    ref.invalidate(exerciciosProvider);
    ref.invalidate(exerciciosCuradoriaProvider);
  }

  Future<void> _uploadVideo(Exercicio exercicio) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(content: Text('Enviando video de ${exercicio.nome}...')),
    );
    try {
      await ref.read(exercicioRepositoryProvider).uploadVideo(
            id: exercicio.id,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      ref.read(analyticsServiceProvider).track(
        'video_personal_upload',
        {'exId': exercicio.id},
      );
      _refresh();
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Video adicionado.'),
          backgroundColor: EagleTokens.good,
        ),
      );
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: EagleTokens.bad,
        ),
      );
    }
  }

  Future<void> _deleteOne(Exercicio exercicio) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir exercicio?'),
            content: Text(
              'Isso remove "${exercicio.nome}" da biblioteca. Se estiver em treino, o backend pode bloquear.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: EagleTokens.bad,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(exercicioRepositoryProvider).excluir(exercicio.id);
      _selected.remove(exercicio.id);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exercicio excluido.'),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  Future<void> _favorite(Exercicio exercicio) async {
    try {
      final repo = ref.read(exercicioRepositoryProvider);
      if (exercicio.favoritado) {
        await repo.desfavoritarExercicio(exercicio.id);
      } else {
        await repo.favoritarExercicio(exercicio.id);
      }
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
    }
  }

  Future<void> _favoriteBatch(List<Exercicio> exercicios) async {
    final repo = ref.read(exercicioRepositoryProvider);
    final ids = _selected.toList();
    for (final id in ids) {
      final ex = exercicios.firstWhere((item) => item.id == id);
      if (!ex.favoritado) await repo.favoritarExercicio(id);
    }
    setState(_selected.clear);
    _refresh();
  }

  Future<void> _deleteBatch() async {
    final count = _selected.length;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Excluir $count exercicios?'),
            content: const Text(
              'Esta acao remove os exercicios selecionados da biblioteca. Exercicios em uso podem ser bloqueados pelo backend.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: EagleTokens.bad,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    final repo = ref.read(exercicioRepositoryProvider);
    for (final id in _selected.toList()) {
      await repo.excluir(id);
    }
    setState(_selected.clear);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(exerciciosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/exercicios/novo');
          if (created == true) _refresh();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_selected.isNotEmpty)
              ExerciciosBatchActions(
                count: _selected.length,
                onCancel: () => setState(_selected.clear),
                onFavorite:
                    () => asyncList.whenData(
                      (value) => _favoriteBatch(value),
                    ),
                onDelete: _deleteBatch,
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BIBLIOTECA',
                            style: TextStyle(
                              color: mute,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Exercicios',
                            style: TextStyle(
                              color: ink,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Carregar biblioteca completa',
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () async {
                        final imported = await context.push<bool>(
                          '/exercicios/biblioteca-wizard',
                        );
                        if (imported == true) _refresh();
                      },
                    ),
                    IconButton(
                      tooltip: 'Novo exercicio',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () async {
                        final created = await context.push<bool>(
                          '/exercicios/novo',
                        );
                        if (created == true) _refresh();
                      },
                    ),
                  ],
                ),
              ),
            ExerciciosFilterBar(
              filter: _filter,
              onChanged: (value) => setState(() => _filter = value),
              onClear:
                  () => setState(
                    () => _filter = const ExerciciosUiFilter(),
                  ),
            ),
            Expanded(
              child: asyncList.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(friendlyError(e)),
                      ),
                    ),
                data: (exercicios) {
                  final filtered = _applyFilter(exercicios);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(
                          children: [
                            Text(
                              '${filtered.length} exercicios',
                              style: TextStyle(
                                color: mute,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            if (_filter.grupo != null)
                              Text(
                                TaxonomyLabels.grupo[_filter.grupo!] ?? '',
                                style: TextStyle(color: mute),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ExerciciosListView(
                          exercicios: filtered,
                          selectedIds: _selected,
                          onTap: (exercicio) {
                            if (_selected.isNotEmpty) {
                              setState(() {
                                _selected.contains(exercicio.id)
                                    ? _selected.remove(exercicio.id)
                                    : _selected.add(exercicio.id);
                              });
                              return;
                            }
                            context.push('/exercicios/${exercicio.id}');
                          },
                          onLongPress:
                              (exercicio) => setState(
                                () => _selected.add(exercicio.id),
                              ),
                          onFavorite: _favorite,
                          onUploadVideo: _uploadVideo,
                          onDelete: _deleteOne,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
