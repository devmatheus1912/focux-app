import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';
import 'widgets/exercicios_batch_actions.dart';
import 'widgets/exercicios_filter_bar.dart';
import 'widgets/exercicios_list_view.dart';

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
    FeedbackHelper.showInfo(context, 'Enviando video de ${exercicio.nome}...');
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .uploadVideo(
            id: exercicio.id,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': exercicio.id},
      );
      _refresh();
      if (mounted) FeedbackHelper.showSuccess(context, 'Video adicionado.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
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
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
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
        FeedbackHelper.showSuccess(context, 'Exercicio excluido.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
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
      FeedbackHelper.showError(context, friendlyError(e));
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

  void _selectAllVisible(List<Exercicio> exercicios) {
    setState(() {
      _selected
        ..clear()
        ..addAll(exercicios.map((e) => e.id));
    });
  }

  Future<void> _deleteBatch(List<Exercicio> exercicios) async {
    final count = _selected.length;
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Excluir $count exercicios?'),
            content: Text(
              'Esta acao remove os exercicios selecionados da biblioteca. '
              'Se algum estiver cadastrado em treino de aluno, ele sera mantido '
              'e eu vou te mostrar quais foram bloqueados.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    final repo = ref.read(exercicioRepositoryProvider);
    final byId = {for (final ex in exercicios) ex.id: ex};
    final deleted = <int>[];
    final blocked = <_DeleteFailure>[];
    final selectedIds = _selected.toList();

    for (final id in selectedIds) {
      final ex = byId[id];
      try {
        await repo.excluir(id);
        deleted.add(id);
      } catch (e) {
        blocked.add(
          _DeleteFailure(
            id: id,
            nome: ex?.nome ?? 'Exercicio #$id',
            motivo: friendlyError(e),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() {
      _selected
        ..removeAll(deleted)
        ..removeAll(blocked.map((e) => e.id));
      if (blocked.isEmpty) _selected.clear();
    });
    _refresh();
    if (blocked.isEmpty) {
      FeedbackHelper.showSuccess(
        context,
        deleted.length == 1
            ? '1 exercicio excluido.'
            : '${deleted.length} exercicios excluidos.',
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Alguns exercicios nao foram excluidos'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (deleted.isNotEmpty)
                    Text('${deleted.length} excluido(s) com sucesso.'),
                  const SizedBox(height: 8),
                  const Text(
                    'Mantidos porque estao cadastrados para aluno ou em treino:',
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: blocked.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, index) {
                        final item = blocked[index];
                        return Text(
                          '${item.nome}\n${item.motivo}',
                          style: const TextStyle(fontSize: 13),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FxLiquidPrimaryButton(
                label: 'Entendi',
                onPressed: () => Navigator.pop(ctx),
                expand: false,
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(exerciciosProvider);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Exercicios',
      child: FxShellScaffold(
        useMesh: true,
        appBar:
            _selected.isEmpty
                ? FxShellAppBar(
                  title: 'Exercicios',
                  subtitle: 'BIBLIOTECA',
                  onBack: () => safePopOrGo(context, '/dashboard/personal'),
                  actions: [
                    IconButton(
                      tooltip: 'Selecionar exercicios',
                      icon: const Icon(Icons.checklist_rounded),
                      onPressed:
                          () => asyncList.whenData((value) {
                            final filtered = _applyFilter(value);
                            if (filtered.isEmpty) return;
                            setState(() => _selected.add(filtered.first.id));
                          }),
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
                )
                : null,
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
                  onSelectAll:
                      () => asyncList.whenData(
                        (value) => _selectAllVisible(_applyFilter(value)),
                      ),
                  onFavorite:
                      () =>
                          asyncList.whenData((value) => _favoriteBatch(value)),
                  onDelete:
                      () => asyncList.whenData(
                        (value) => _deleteBatch(_applyFilter(value)),
                      ),
                )
              else
                const SizedBox.shrink(),
              ExerciciosFilterBar(
                filter: _filter,
                onChanged: (value) => setState(() => _filter = value),
                onClear:
                    () => setState(() => _filter = const ExerciciosUiFilter()),
              ),
              Expanded(
                child: asyncList.when(
                  loading: () => const SkeletonList(count: 6),
                  error:
                      (e, _) => FxErrorState(
                        chromeOnDark: isDark,
                        primary: primary,
                        message: friendlyError(e),
                        onRetry: _refresh,
                        title: 'Não conseguimos carregar os exercícios',
                      ),
                  data: (exercicios) {
                    final filtered = _applyFilter(exercicios);
                    if (exercicios.isEmpty) {
                      return FxEmptyState(
                        icon: 'dumbbell',
                        title: 'Sua biblioteca está vazia',
                        subtitle:
                            'Carregue a biblioteca curada ou cadastre o primeiro exercício.',
                        action: FxEmptyAction(
                          label: 'Carregar biblioteca',
                          onTap: () async {
                            final imported = await context.push<bool>(
                              '/exercicios/biblioteca-wizard',
                            );
                            if (imported == true) _refresh();
                          },
                        ),
                      );
                    }
                    if (filtered.isEmpty) {
                      return FxEmptyState(
                        icon: 'search',
                        title: 'Nenhum exercício encontrado',
                        subtitle:
                            'Ajuste os filtros ou a busca para ver outros exercícios.',
                        action: FxEmptyAction(
                          label: 'Limpar filtros',
                          onTap:
                              () => setState(
                                () => _filter = const ExerciciosUiFilter(),
                              ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            0,
                            16,
                            10,
                          ),
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
                                (exercicio) =>
                                    setState(() => _selected.add(exercicio.id)),
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
      ),
    );
  }
}

class _DeleteFailure {
  final int id;
  final String nome;
  final String motivo;

  const _DeleteFailure({
    required this.id,
    required this.nome,
    required this.motivo,
  });
}
