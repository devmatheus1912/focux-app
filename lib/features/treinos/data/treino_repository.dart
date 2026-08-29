import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../exercicios/data/exercicio_repository.dart';
import '../utils/treinos_list_labels.dart';

class TreinoExercicioItem {
  final int id;
  final Exercicio exercicio;
  final int series;
  final String repeticoes;
  final double? cargaKg;
  final int? descansoSegundos;
  final int ordem;
  final String? observacoes;
  final String tipoSerie;
  final int? grupoSuperset;

  TreinoExercicioItem({
    required this.id,
    required this.exercicio,
    required this.series,
    required this.repeticoes,
    this.cargaKg,
    this.descansoSegundos,
    required this.ordem,
    this.observacoes,
    this.tipoSerie = 'NORMAL',
    this.grupoSuperset,
  });

  factory TreinoExercicioItem.fromJson(Map<String, dynamic> json) =>
      TreinoExercicioItem(
        id: json['id'] as int,
        exercicio: Exercicio.fromJson(
          json['exercicio'] as Map<String, dynamic>,
        ),
        series: json['series'] as int,
        repeticoes: json['repeticoes'] as String,
        cargaKg: (json['cargaKg'] as num?)?.toDouble(),
        descansoSegundos: json['descansoSegundos'] as int?,
        ordem: json['ordem'] as int,
        observacoes: json['observacoes'] as String?,
        tipoSerie: json['tipoSerie'] as String? ?? 'NORMAL',
        grupoSuperset: json['grupoSuperset'] as int?,
      );
}

class Treino {
  final int id;
  final String nome;
  final String? descricao;
  final String? objetivo;
  final String? nivel;
  final bool isTemplate;
  final List<TreinoExercicioItem> exercicios;
  final int? _exerciciosCount;
  final int? _seriesTotal;

  Treino({
    required this.id,
    required this.nome,
    this.descricao,
    this.objetivo,
    this.nivel,
    this.isTemplate = false,
    required this.exercicios,
    int? exerciciosCount,
    int? seriesTotal,
  }) : _exerciciosCount = exerciciosCount,
       _seriesTotal = seriesTotal;

  int get exerciciosCount => _exerciciosCount ?? exercicios.length;

  int get seriesTotal =>
      _seriesTotal ??
      exercicios.fold<int>(0, (sum, item) => sum + item.series);

  bool get pronto => exerciciosCount > 0;

  factory Treino.fromJson(Map<String, dynamic> json) => Treino(
    id: json['id'] as int,
    nome: json['nome'] as String,
    descricao: json['descricao'] as String?,
    objetivo: json['objetivo'] as String?,
    nivel: json['nivel'] as String?,
    isTemplate: json['isTemplate'] as bool? ?? false,
    exercicios:
        ((json['exercicios'] as List<dynamic>?) ?? [])
            .map((e) => TreinoExercicioItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    exerciciosCount: json['exerciciosCount'] as int?,
    seriesTotal: json['seriesTotal'] as int?,
  );

  factory Treino.fromHomeItemJson(Map<String, dynamic> json) => Treino(
    id: (json['id'] as num).toInt(),
    nome: json['nome'] as String,
    descricao: json['descricao'] as String?,
    objetivo: json['objetivo'] as String?,
    nivel: json['nivel'] as String?,
    isTemplate: json['isTemplate'] as bool? ?? false,
    exercicios: const [],
    exerciciosCount: (json['exerciciosCount'] as num?)?.toInt() ?? 0,
    seriesTotal: (json['seriesTotal'] as num?)?.toInt() ?? 0,
  );
}

class TreinosHomeResumo {
  final int totalPlanos;
  final int prontos;
  final int emMontagem;
  final int templates;
  final int totalExercicios;

  const TreinosHomeResumo({
    required this.totalPlanos,
    required this.prontos,
    required this.emMontagem,
    required this.templates,
    required this.totalExercicios,
  });

  factory TreinosHomeResumo.fromJson(Map<String, dynamic> j) => TreinosHomeResumo(
    totalPlanos: (j['totalPlanos'] as num?)?.toInt() ?? 0,
    prontos: (j['prontos'] as num?)?.toInt() ?? 0,
    emMontagem: (j['emMontagem'] as num?)?.toInt() ?? 0,
    templates: (j['templates'] as num?)?.toInt() ?? 0,
    totalExercicios: (j['totalExercicios'] as num?)?.toInt() ?? 0,
  );
}

class TreinosHomeUiHints {
  final String? emptyTitle;
  final String? emptySubtitle;
  final String libraryCaption;
  final String createCtaLabel;
  final String? emMontagemHint;

  const TreinosHomeUiHints({
    this.emptyTitle,
    this.emptySubtitle,
    required this.libraryCaption,
    required this.createCtaLabel,
    this.emMontagemHint,
  });

  factory TreinosHomeUiHints.fromJson(Map<String, dynamic> j) => TreinosHomeUiHints(
    emptyTitle: j['emptyTitle'] as String?,
    emptySubtitle: j['emptySubtitle'] as String?,
    libraryCaption: j['libraryCaption'] as String? ?? '',
    createCtaLabel: j['createCtaLabel'] as String? ?? 'Criar treino',
    emMontagemHint: j['emMontagemHint'] as String?,
  );

  factory TreinosHomeUiHints.fallback({required TreinosHomeResumo resumo}) =>
      TreinosHomeUiHints(
        emptyTitle:
            resumo.totalPlanos == 0 ? 'Sua biblioteca começa aqui' : null,
        emptySubtitle:
            resumo.totalPlanos == 0
                ? 'Crie um plano base, adicione exercícios e use como ponto de partida para seus alunos.'
                : null,
        libraryCaption:
            '${TreinosListLabels.readyCount(resumo.prontos)} · ${resumo.totalExercicios} exercícios',
        createCtaLabel: 'Criar treino',
        emMontagemHint:
            resumo.emMontagem > 0
                ? (resumo.emMontagem == 1
                    ? '1 plano ainda em montagem — adicione exercícios.'
                    : '${resumo.emMontagem} planos ainda em montagem — adicione exercícios.')
                : null,
      );
}

class TreinosHomeBundle {
  final List<Treino> treinos;
  final TreinosHomeResumo resumo;
  final TreinosHomeUiHints uiHints;

  const TreinosHomeBundle({
    required this.treinos,
    required this.resumo,
    required this.uiHints,
  });

  factory TreinosHomeBundle.fromJson(Map<String, dynamic> j) {
    final resumo = TreinosHomeResumo.fromJson(
      (j['resumo'] as Map<String, dynamic>?) ?? const {},
    );
    final hintsRaw = j['uiHints'] as Map<String, dynamic>?;
    return TreinosHomeBundle(
      treinos:
          ((j['treinos'] as List?) ?? const [])
              .map((e) => Treino.fromHomeItemJson(e as Map<String, dynamic>))
              .toList(),
      resumo: resumo,
      uiHints:
          hintsRaw == null
              ? TreinosHomeUiHints.fallback(resumo: resumo)
              : TreinosHomeUiHints.fromJson(hintsRaw),
    );
  }
}

class TreinoPickerUiHints {
  final String searchPlaceholder;
  final String createCtaLabel;
  final String? emptyLibraryHint;

  const TreinoPickerUiHints({
    required this.searchPlaceholder,
    required this.createCtaLabel,
    this.emptyLibraryHint,
  });

  factory TreinoPickerUiHints.fromJson(Map<String, dynamic> j) =>
      TreinoPickerUiHints(
        searchPlaceholder: j['searchPlaceholder'] as String? ??
            'Supino, agachamento, remada…',
        createCtaLabel: j['createCtaLabel'] as String? ?? 'Novo exercício',
        emptyLibraryHint: j['emptyLibraryHint'] as String?,
      );

  factory TreinoPickerUiHints.fallback({required int librarySize}) =>
      TreinoPickerUiHints(
        searchPlaceholder: 'Supino, agachamento, remada…',
        createCtaLabel: 'Cadastrar exercício',
        emptyLibraryHint: librarySize == 0
            ? 'Importe a biblioteca ou crie seu primeiro exercício.'
            : null,
      );
}

class TreinoPickerHomeBundle {
  final Treino treino;
  final int libraryCount;
  final List<Exercicio> shortcuts;
  final TreinoPickerUiHints uiHints;

  const TreinoPickerHomeBundle({
    required this.treino,
    required this.libraryCount,
    required this.shortcuts,
    required this.uiHints,
  });

  /// Atalho legado — shortcuts do BFF (não carrega biblioteca inteira).
  List<Exercicio> get exercicios => shortcuts;

  factory TreinoPickerHomeBundle.fromJson(Map<String, dynamic> j) {
    final treino = Treino.fromJson(j['treino'] as Map<String, dynamic>);
    final hintsRaw = j['uiHints'] as Map<String, dynamic>?;
    final shortcutsRaw = j['shortcuts'] as List?;
    final legacyRaw = j['exercicios'] as List?;
    final shortcutsSource = shortcutsRaw ?? legacyRaw ?? const [];
    final shortcuts =
        shortcutsSource
            .map((e) => Exercicio.fromJson(e as Map<String, dynamic>))
            .toList();
    final libraryCount =
        (j['libraryCount'] as num?)?.toInt() ??
        legacyRaw?.length ??
        shortcuts.length;
    return TreinoPickerHomeBundle(
      treino: treino,
      libraryCount: libraryCount,
      shortcuts: shortcuts,
      uiHints: hintsRaw == null
          ? TreinoPickerUiHints.fallback(librarySize: libraryCount)
          : TreinoPickerUiHints.fromJson(hintsRaw),
    );
  }
}

class TreinoRepository {
  final Dio _dio;

  TreinoRepository(ApiClient client) : _dio = client.dio;

  /// BFF tipado — first paint da biblioteca (slim + resumo, sem N+1).
  Future<TreinosHomeBundle> getHome() async {
    final response = await _dio.get('/api/treinos/home');
    return TreinosHomeBundle.fromJson(response.data as Map<String, dynamic>);
  }

  /// BFF tipado — first paint do picker (treino + biblioteca).
  Future<TreinoPickerHomeBundle> getPickerHome(int treinoId) async {
    final response = await _dio.get('/api/treinos/$treinoId/picker/home');
    return TreinoPickerHomeBundle.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<Treino> buscar(int id) async {
    final response = await _dio.get('/api/treinos/$id');
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> criar(
    String nome,
    String? descricao,
    String? objetivo,
    String? nivel,
  ) async {
    final response = await _dio.post(
      '/api/treinos',
      data: {
        'nome': nome,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (nivel != null) 'nivel': nivel,
      },
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> adicionarExercicio(
    int treinoId,
    int exercicioId, {
    int series = 3,
    String repeticoes = '10-12',
    int descanso = 60,
    double? cargaKg,
    String? observacoes,
    String tipoSerie = 'NORMAL',
    int? grupoSuperset,
    int? ordem,
  }) async {
    final response = await _dio.post(
      '/api/treinos/$treinoId/exercicios',
      data: {
        'exercicioId': exercicioId,
        'series': series,
        'repeticoes': repeticoes,
        'descansoSegundos': descanso,
        if (cargaKg != null) 'cargaKg': cargaKg,
        if (observacoes != null && observacoes.trim().isNotEmpty)
          'observacoes': observacoes.trim(),
        'tipoSerie': tipoSerie,
        if (grupoSuperset != null) 'grupoSuperset': grupoSuperset,
        if (ordem != null) 'ordem': ordem,
      },
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> substituirExercicio(
    int treinoId,
    TreinoExercicioItem item,
    int novoExercicioId,
  ) async {
    await removerExercicio(treinoId, item.id);
    return adicionarExercicio(
      treinoId,
      novoExercicioId,
      series: item.series,
      repeticoes: item.repeticoes,
      descanso: item.descansoSegundos ?? 60,
      cargaKg: item.cargaKg,
      observacoes: item.observacoes,
      tipoSerie: item.tipoSerie,
      grupoSuperset: item.grupoSuperset,
      ordem: item.ordem,
    );
  }

  Future<void> atribuirAluno(int treinoId, int alunoId) async {
    await _dio.post('/api/treinos/$treinoId/alunos/$alunoId');
  }

  Future<List<Treino>> listarTreinosDoAluno(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/treinos');
    return (response.data as List<dynamic>)
        .map((e) => Treino.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvarComoTemplate(int id) async {
    await _dio.post('/api/treinos/$id/template');
  }

  Future<Treino> duplicar(int id) async {
    final response = await _dio.post('/api/treinos/$id/duplicar');
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> clonarParaAluno(int treinoId, int alunoId) async {
    final response = await _dio.post(
      '/api/treinos/$treinoId/clonar-para-aluno',
      queryParameters: {'alunoId': alunoId},
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Treino>> listarTemplates() async {
    final response = await _dio.get('/api/treinos/templates');
    return (response.data as List<dynamic>)
        .map((e) => Treino.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> excluirTreino(int id) async {
    await _dio.delete('/api/treinos/$id');
  }

  Future<void> removerExercicio(int treinoId, int itemId) async {
    await _dio.delete('/api/treinos/$treinoId/exercicios/$itemId');
  }

  Future<Treino> reordenarExercicios(int treinoId, List<int> itemIds) async {
    final response = await _dio.patch(
      '/api/treinos/$treinoId/exercicios/ordem',
      data: {'itemIds': itemIds},
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> atualizarExercicioPrescricao(
    int treinoId,
    int itemId, {
    required int series,
    required String repeticoes,
    required int descansoSegundos,
    double? cargaKg,
    String? observacoes,
    required String tipoSerie,
    int? grupoSuperset,
  }) async {
    final response = await _dio.patch(
      '/api/treinos/$treinoId/exercicios/$itemId',
      data: {
        'series': series,
        'repeticoes': repeticoes,
        'descansoSegundos': descansoSegundos,
        'cargaKg': cargaKg,
        'observacoes': observacoes?.trim(),
        'tipoSerie': tipoSerie,
        if (tipoSerie == 'SUPERSET' && grupoSuperset != null)
          'grupoSuperset': grupoSuperset,
      },
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Treino> duplicarExercicio(int treinoId, int itemId) async {
    final response = await _dio.post(
      '/api/treinos/$treinoId/exercicios/$itemId/duplicar',
    );
    return Treino.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> desvincularAluno(int alunoId, int treinoId) async {
    await _dio.delete('/api/alunos/$alunoId/treinos/$treinoId');
  }
}
