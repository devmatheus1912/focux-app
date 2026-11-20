part of 'exercicios_list_screen.dart';

extension on _ExerciciosListScreenState {
  Widget _libraryBody({required bool isDark, required Color primary}) {
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
      child: _libraryScroll(),
    );
  }

  Widget _vazio(FxEmptyState estado) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [estado],
  );

  Widget _libraryScroll() {
    if (_items.isEmpty && _filter.hasActive) {
      return _vazio(
        FxEmptyState(
          icon: FxIcons.buscar,
          title: 'Nenhum exercício encontrado',
          subtitle: 'Mude a busca ou os filtros para ver outros exercícios.',
          action: FxEmptyAction(
            label: 'Limpar filtros',
            secondary: true,
            onTap: () => _mudarFiltro(const ExerciciosUiFilter()),
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return switch (_aba) {
        ExerciciosAba.meus => _vazio(
          FxEmptyState(
            icon: FxIcons.video,
            title: exerciciosMeusVazioTitulo,
            subtitle: exerciciosMeusVazioApoio,
            action: FxEmptyAction(
              label: 'Novo exercício',
              onTap: _novoExercicio,
            ),
          ),
        ),
        ExerciciosAba.favoritos => _vazio(
          const FxEmptyState(
            icon: FxIcons.estrela,
            title: 'Nenhum favorito ainda',
            subtitle: 'Segure um exercício da lista para favoritar.',
          ),
        ),
        ExerciciosAba.biblioteca => _vazio(
          FxEmptyState(
            icon: FxIcons.livro,
            title: 'Sua biblioteca está vazia',
            subtitle:
                'Carregue a biblioteca da Focux, com vídeo em cada exercício.',
            action: FxEmptyAction(
              label: 'Carregar biblioteca',
              onTap: _abrirBiblioteca,
            ),
          ),
        ),
      };
    }
    return ExerciciosListView(
      controller: _scrollCtrl,
      exercicios: _items,
      selectedIds: _selected,
      loadingMore: _loadingMore,
      busca: _filter.query,
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
      onFavorite: _favorite,
      onMais: _acoes,
      onPreview: (e) => showExerciseMediaPreview(context, exercicio: e),
    );
  }
}
