part of 'exercicios_list_screen.dart';

extension on _ExerciciosListScreenState {
  Widget _libraryBody({
    required bool isDark,
    required Color primary,
    required List<Exercicio> visible,
  }) {
    if (_loading) return const SkeletonList(count: 6);
    if (_error != null) {
      return FxErrorState(
        chromeOnDark: isDark,
        primary: primary,
        message: _error!,
        onRetry: _refresh,
        title: 'Não conseguimos carregar os exercícios',
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: () => _fetchPage(reset: true),
      child: _libraryScroll(primary: primary, visible: visible),
    );
  }

  Widget _libraryScroll({
    required Color primary,
    required List<Exercicio> visible,
  }) {
    if (_totalElements == 0 && !_filter.hasActive) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FxEmptyState(
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
          ),
        ],
      );
    }
    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FxEmptyState(
            icon: 'search',
            title: 'Nenhum exercício encontrado',
            subtitle:
                'Ajuste os filtros ou a busca para ver outros exercícios.',
            action: FxEmptyAction(
              label: 'Limpar filtros',
              onTap: () {
                setState(() => _filter = const ExerciciosUiFilter());
                _fetchPage(reset: true);
              },
            ),
          ),
        ],
      );
    }
    return ExerciciosListView(
      controller: _scrollCtrl,
      exercicios: visible,
      selectedIds: _selected,
      accent: primary,
      loadingMore: _loadingMore,
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
      onLongPress: (exercicio) => setState(() => _selected.add(exercicio.id)),
      onFavorite: _favorite,
      onUploadVideo: _uploadVideo,
      onDelete: _deleteOne,
    );
  }
}
