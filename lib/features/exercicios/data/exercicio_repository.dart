import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/pt_br_display.dart';
import '../models/curated_biblioteca.dart';
import 'enums.dart';
import 'exercicio_page.dart';

class Exercicio {
  final int id;
  final String nome;
  final String? descricao;
  final String? musculoAlvo;
  final String? gifUrl;
  final String? thumbnailUrl;
  final String? videoSource;
  final String? licenseStatus;
  final String? categoria;
  final String? equipamento;
  final String? nivel;
  final String? mecanica;
  final String? objetivo;
  final String? errosComuns;
  final String? contraindicacoes;
  final String? substitutos;
  final String? videoUrl;
  final String? tags;
  final Modalidade? modalidade;
  final PadraoMovimento? padraoMovimento;
  final GrupoMuscular? grupoMuscularPrimario;
  final List<GrupoMuscular> gruposSecundarios;
  final List<Equipamento> equipamentos;
  final List<Espaco> espacosCompativeis;
  final Dificuldade? dificuldade;
  final bool unilateral;
  final bool curado;
  final int? curatedId;
  final bool favoritado;
  final String editorialStatus;
  final String? editorialNotes;
  final DateTime? editorialReviewedAt;

  Exercicio({
    required this.id,
    required this.nome,
    this.descricao,
    this.musculoAlvo,
    this.gifUrl,
    this.thumbnailUrl,
    this.videoSource,
    this.licenseStatus,
    this.categoria,
    this.equipamento,
    this.nivel,
    this.mecanica,
    this.objetivo,
    this.errosComuns,
    this.contraindicacoes,
    this.substitutos,
    this.videoUrl,
    this.tags,
    this.modalidade,
    this.padraoMovimento,
    this.grupoMuscularPrimario,
    this.gruposSecundarios = const [],
    this.equipamentos = const [],
    this.espacosCompativeis = const [],
    this.dificuldade,
    this.unilateral = false,
    this.curado = false,
    this.curatedId,
    this.favoritado = false,
    this.editorialStatus = 'PENDING_REVIEW',
    this.editorialNotes,
    this.editorialReviewedAt,
  });

  Exercicio copyWith({bool? favoritado}) {
    return Exercicio(
      id: id,
      nome: nome,
      descricao: descricao,
      musculoAlvo: musculoAlvo,
      gifUrl: gifUrl,
      thumbnailUrl: thumbnailUrl,
      videoSource: videoSource,
      licenseStatus: licenseStatus,
      categoria: categoria,
      equipamento: equipamento,
      nivel: nivel,
      mecanica: mecanica,
      objetivo: objetivo,
      errosComuns: errosComuns,
      contraindicacoes: contraindicacoes,
      substitutos: substitutos,
      videoUrl: videoUrl,
      tags: tags,
      modalidade: modalidade,
      padraoMovimento: padraoMovimento,
      grupoMuscularPrimario: grupoMuscularPrimario,
      gruposSecundarios: gruposSecundarios,
      equipamentos: equipamentos,
      espacosCompativeis: espacosCompativeis,
      dificuldade: dificuldade,
      unilateral: unilateral,
      curado: curado,
      curatedId: curatedId,
      favoritado: favoritado ?? this.favoritado,
      editorialStatus: editorialStatus,
      editorialNotes: editorialNotes,
      editorialReviewedAt: editorialReviewedAt,
    );
  }

  factory Exercicio.fromJson(Map<String, dynamic> json) => Exercicio(
    id: json['id'] as int,
    nome: json['nome'] as String,
    descricao: json['descricao'] as String?,
    musculoAlvo: json['musculoAlvo'] as String?,
    gifUrl: json['gifUrl'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
    videoSource: json['videoSource'] as String?,
    licenseStatus: json['licenseStatus'] as String?,
    categoria: json['categoria'] as String?,
    equipamento: json['equipamento'] as String?,
    nivel: json['nivel'] as String?,
    mecanica: json['mecanica'] as String?,
    objetivo: json['objetivo'] as String?,
    errosComuns: json['errosComuns'] as String?,
    contraindicacoes: json['contraindicacoes'] as String?,
    substitutos: json['substitutos'] as String?,
    videoUrl: json['videoUrl'] as String?,
    tags: json['tags'] as String?,
    modalidade: tryParseEnum(Modalidade.values, json['modalidade'] as String?),
    padraoMovimento: tryParseEnum(
      PadraoMovimento.values,
      json['padraoMovimento'] as String?,
    ),
    grupoMuscularPrimario: tryParseEnum(
      GrupoMuscular.values,
      json['grupoMuscularPrimario'] as String?,
    ),
    gruposSecundarios: parseEnumCsv(
      GrupoMuscular.values,
      json['gruposSecundarios'],
    ),
    equipamentos: parseEnumCsv(
      Equipamento.values,
      json['equipamentosCurado'] ?? json['equipamentos'],
    ),
    espacosCompativeis: parseEnumCsv(Espaco.values, json['espacosCompativeis']),
    dificuldade: tryParseEnum(
      Dificuldade.values,
      json['dificuldade'] as String?,
    ),
    unilateral: json['unilateral'] as bool? ?? false,
    curado: json['curado'] as bool? ?? false,
    curatedId: (json['curatedId'] as num?)?.toInt(),
    favoritado: json['favoritado'] as bool? ?? false,
    editorialStatus: json['editorialStatus'] as String? ?? 'PENDING_REVIEW',
    editorialNotes: json['editorialNotes'] as String?,
    editorialReviewedAt:
        json['editorialReviewedAt'] == null
            ? null
            : DateTime.tryParse(json['editorialReviewedAt'].toString()),
  );

  bool get hasPlayableMedia =>
      (videoUrl?.trim().isNotEmpty ?? false) ||
      (gifUrl?.trim().isNotEmpty ?? false);

  bool get isPersonalUpload =>
      videoSource == 'PERSONAL_UPLOAD' || licenseStatus == 'PERSONAL_OWNED';

  bool get isLicensedMedia => licenseStatus == 'LICENSED';

  /// Exercício da biblioteca curada Focux (seed + mídia padrão).
  bool get isFocuxLibrary =>
      videoSource == 'FOCUX_LIBRARY' || curado || curatedId != null;

  bool get isProductionPending =>
      videoSource == 'PRODUCTION_PENDING' || videoSource == 'CURATION_REQUIRED';

  String? get primaryGroupLabel =>
      grupoMuscularPrimario?.backendName ?? musculoAlvo;

  String get nomeDisplay => displayExerciseName(nome);

  String? get modalityLabel => modalidade?.backendName ?? categoria;

  String? get difficultyLabel => dificuldade?.backendName ?? nivel;

  bool get isEditorialApproved => editorialStatus == 'APPROVED';

  bool get isReadyForStudent =>
      hasPlayableMedia &&
      (isLicensedMedia ||
          isPersonalUpload ||
          (isFocuxLibrary && isEditorialApproved));

  /// Biblioteca curada com mídia já pode ser prescrita sem alerta no treino.
  bool get isReadyForPrescription =>
      hasPlayableMedia &&
      (isLicensedMedia || isPersonalUpload || isFocuxLibrary);

  /// Evita badge de “licença pendente” em exercícios curados com demonstração.
  bool get showMediaBadgeInWorkoutList {
    if (isFocuxLibrary && hasPlayableMedia) return false;
    if (mediaTrustLevel == 'READY') return false;
    return true;
  }

  String get mediaTrustLevel {
    if (isReadyForPrescription &&
        (isEditorialApproved || isFocuxLibrary || isPersonalUpload)) {
      return 'READY';
    }
    if (!hasPlayableMedia) return 'NO_VIDEO';
    if (!isEditorialApproved && !isFocuxLibrary) return 'NEEDS_REVIEW';
    if (!isLicensedMedia && !isPersonalUpload && !isFocuxLibrary) {
      return 'NEEDS_LICENSE';
    }
    return 'NEEDS_REVIEW';
  }

  String get mediaTrustLabel {
    return switch (mediaTrustLevel) {
      'READY' =>
        isPersonalUpload
            ? 'Vídeo do personal'
            : isFocuxLibrary
            ? 'Demonstração Focux'
            : 'Demonstração licenciada',
      'NO_VIDEO' => 'Sem demonstração',
      'NEEDS_LICENSE' =>
        isFocuxLibrary ? 'Demonstração Focux' : 'Mídia em validação',
      _ => 'Revisar demonstração',
    };
  }

  String get mediaTrustDescription {
    return switch (mediaTrustLevel) {
      'READY' =>
        isPersonalUpload
            ? 'Demonstração própria validada para passar mais confiança ao aluno.'
            : isFocuxLibrary
            ? 'Vídeo padrão da biblioteca Focux, pronto para prescrição.'
            : 'Mídia licenciada e aprovada para prescrição.',
      'NO_VIDEO' => 'Adicione vídeo ou GIF antes de priorizar este exercício.',
      'NEEDS_LICENSE' =>
        isFocuxLibrary
            ? 'A demonstração da biblioteca será liberada em instantes.'
            : 'Informe se a mídia é licenciada ou própria do personal.',
      _ => 'Aprove a curadoria antes de usar como exercício premium.',
    };
  }
}

class ExercicioCuradoriaBucket {
  final String label;
  final int total;
  final int comVideo;
  final int licenciados;
  final int prontosParaAluno;

  ExercicioCuradoriaBucket({
    required this.label,
    required this.total,
    required this.comVideo,
    required this.licenciados,
    required this.prontosParaAluno,
  });

  factory ExercicioCuradoriaBucket.fromJson(Map<String, dynamic> json) =>
      ExercicioCuradoriaBucket(
        label: json['label'] as String? ?? 'NAO_INFORMADO',
        total: (json['total'] as num?)?.toInt() ?? 0,
        comVideo: (json['comVideo'] as num?)?.toInt() ?? 0,
        licenciados: (json['licenciados'] as num?)?.toInt() ?? 0,
        prontosParaAluno: (json['prontosParaAluno'] as num?)?.toInt() ?? 0,
      );
}

class ExercicioCuradoriaResumo {
  final int total;
  final int metaPremium;
  final int faltamParaMeta;
  final int comVideo;
  final int semVideo;
  final int comThumbnail;
  final int licenciados;
  final int videosProprios;
  final int pendentesLicenca;
  final int comOrientacao;
  final int prontosParaAluno;
  final int scoreProntidao;
  final List<ExercicioCuradoriaBucket> porGrupoMuscular;
  final List<String> alertas;

  ExercicioCuradoriaResumo({
    required this.total,
    required this.metaPremium,
    required this.faltamParaMeta,
    required this.comVideo,
    required this.semVideo,
    required this.comThumbnail,
    required this.licenciados,
    required this.videosProprios,
    required this.pendentesLicenca,
    required this.comOrientacao,
    required this.prontosParaAluno,
    required this.scoreProntidao,
    required this.porGrupoMuscular,
    required this.alertas,
  });

  factory ExercicioCuradoriaResumo.fromJson(Map<String, dynamic> json) {
    List<ExercicioCuradoriaBucket> buckets(String key) =>
        ((json[key] as List<dynamic>?) ?? [])
            .map(
              (e) =>
                  ExercicioCuradoriaBucket.fromJson(e as Map<String, dynamic>),
            )
            .toList();

    return ExercicioCuradoriaResumo(
      total: (json['total'] as num?)?.toInt() ?? 0,
      metaPremium: (json['metaPremium'] as num?)?.toInt() ?? 1500,
      faltamParaMeta: (json['faltamParaMeta'] as num?)?.toInt() ?? 0,
      comVideo: (json['comVideo'] as num?)?.toInt() ?? 0,
      semVideo: (json['semVideo'] as num?)?.toInt() ?? 0,
      comThumbnail: (json['comThumbnail'] as num?)?.toInt() ?? 0,
      licenciados: (json['licenciados'] as num?)?.toInt() ?? 0,
      videosProprios: (json['videosProprios'] as num?)?.toInt() ?? 0,
      pendentesLicenca: (json['pendentesLicenca'] as num?)?.toInt() ?? 0,
      comOrientacao: (json['comOrientacao'] as num?)?.toInt() ?? 0,
      prontosParaAluno: (json['prontosParaAluno'] as num?)?.toInt() ?? 0,
      scoreProntidao: (json['scoreProntidao'] as num?)?.toInt() ?? 0,
      porGrupoMuscular: buckets('porGrupoMuscular'),
      alertas:
          ((json['alertas'] as List<dynamic>?) ?? [])
              .map((e) => e.toString())
              .toList(),
    );
  }
}

class CuradoriaLoteResultado {
  final int afetados;
  final int comVideo;
  final int comThumbnail;
  final int videosProprios;
  final int pendentesLicenca;
  final int prontosParaAluno;

  CuradoriaLoteResultado({
    required this.afetados,
    required this.comVideo,
    required this.comThumbnail,
    required this.videosProprios,
    required this.pendentesLicenca,
    required this.prontosParaAluno,
  });

  factory CuradoriaLoteResultado.fromJson(Map<String, dynamic> json) =>
      CuradoriaLoteResultado(
        afetados: (json['afetados'] as num?)?.toInt() ?? 0,
        comVideo: (json['comVideo'] as num?)?.toInt() ?? 0,
        comThumbnail: (json['comThumbnail'] as num?)?.toInt() ?? 0,
        videosProprios: (json['videosProprios'] as num?)?.toInt() ?? 0,
        pendentesLicenca: (json['pendentesLicenca'] as num?)?.toInt() ?? 0,
        prontosParaAluno: (json['prontosParaAluno'] as num?)?.toInt() ?? 0,
      );
}

class ImportarMidiasResultado {
  final int total;
  final int atualizados;
  final int naoEncontrados;
  final int prontosParaAluno;
  final List<String> naoEncontradosKeys;

  ImportarMidiasResultado({
    required this.total,
    required this.atualizados,
    required this.naoEncontrados,
    required this.prontosParaAluno,
    required this.naoEncontradosKeys,
  });

  factory ImportarMidiasResultado.fromJson(Map<String, dynamic> json) =>
      ImportarMidiasResultado(
        total: (json['total'] as num?)?.toInt() ?? 0,
        atualizados: (json['atualizados'] as num?)?.toInt() ?? 0,
        naoEncontrados: (json['naoEncontrados'] as num?)?.toInt() ?? 0,
        prontosParaAluno: (json['prontosParaAluno'] as num?)?.toInt() ?? 0,
        naoEncontradosKeys:
            ((json['naoEncontradosKeys'] as List<dynamic>?) ?? [])
                .map((e) => e.toString())
                .toList(),
      );
}

class ExercicioMediaImportBatch {
  final int id;
  final int total;
  final int atualizados;
  final int naoEncontrados;
  final int prontosParaAluno;
  final List<String> naoEncontradosKeys;
  final DateTime? criadoEm;

  ExercicioMediaImportBatch({
    required this.id,
    required this.total,
    required this.atualizados,
    required this.naoEncontrados,
    required this.prontosParaAluno,
    required this.naoEncontradosKeys,
    required this.criadoEm,
  });

  factory ExercicioMediaImportBatch.fromJson(Map<String, dynamic> json) =>
      ExercicioMediaImportBatch(
        id: (json['id'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        atualizados: (json['atualizados'] as num?)?.toInt() ?? 0,
        naoEncontrados: (json['naoEncontrados'] as num?)?.toInt() ?? 0,
        prontosParaAluno: (json['prontosParaAluno'] as num?)?.toInt() ?? 0,
        naoEncontradosKeys:
            ((json['naoEncontradosKeys'] as List<dynamic>?) ?? [])
                .map((e) => e.toString())
                .toList(),
        criadoEm:
            json['criadoEm'] == null
                ? null
                : DateTime.tryParse(json['criadoEm'].toString()),
      );
}

class ExercicioEditorialQueue {
  final int total;
  final List<Exercicio> items;

  ExercicioEditorialQueue({required this.total, required this.items});
}

class ExercicioRepository {
  final Dio _dio;

  ExercicioRepository(ApiClient client) : _dio = client.dio;

  Future<List<Exercicio>> listar({
    String? nome,
    String? categoria,
    String? tag,
    String? musculoAlvo,
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    bool? hasVideo,
    String? videoSource,
    String? licenseStatus,
    String? editorialStatus,
    bool? favoritos,
  }) async {
    final queryParams = <String, dynamic>{};
    if (nome != null && nome.isNotEmpty) {
      queryParams['nome'] = nome;
    }
    if (categoria != null && categoria.isNotEmpty) {
      queryParams['categoria'] = categoria;
    }
    if (tag != null && tag.isNotEmpty) {
      queryParams['tag'] = tag;
    }
    if (musculoAlvo != null && musculoAlvo.isNotEmpty) {
      queryParams['musculoAlvo'] = musculoAlvo;
    }
    if (equipamento != null && equipamento.isNotEmpty) {
      queryParams['equipamento'] = equipamento;
    }
    if (nivel != null && nivel.isNotEmpty) {
      queryParams['nivel'] = nivel;
    }
    if (mecanica != null && mecanica.isNotEmpty) {
      queryParams['mecanica'] = mecanica;
    }
    if (objetivo != null && objetivo.isNotEmpty) {
      queryParams['objetivo'] = objetivo;
    }
    if (hasVideo != null) {
      queryParams['hasVideo'] = hasVideo ? 'true' : 'false';
    }
    if (videoSource != null && videoSource.isNotEmpty) {
      queryParams['videoSource'] = videoSource;
    }
    if (licenseStatus != null && licenseStatus.isNotEmpty) {
      queryParams['licenseStatus'] = licenseStatus;
    }
    if (editorialStatus != null && editorialStatus.isNotEmpty) {
      queryParams['editorialStatus'] = editorialStatus;
    }
    if (favoritos == true) {
      queryParams['favoritos'] = 'true';
    }
    queryParams['page'] = 0;
    queryParams['size'] = 200;
    queryParams['sort'] = 'nome,asc';
    final all = <Exercicio>[];
    var page = 0;
    const pageSize = 200;

    while (page < 20) {
      queryParams['page'] = page;
      queryParams['size'] = pageSize;
      final response = await _dio.get(
        '/api/exercicios/v2',
        queryParameters: queryParams,
      );
      final data = response.data;
      final list =
          data is Map<String, dynamic>
              ? data['content'] as List<dynamic>
              : data as List<dynamic>;
      if (list.isEmpty) break;
      all.addAll(
        list.map((e) => Exercicio.fromJson(e as Map<String, dynamic>)),
      );
      page += 1;
      if (data is Map<String, dynamic> && data['hasNext'] == false) break;
      if (list.length < pageSize) break;
      final totalPages =
          data is Map<String, dynamic>
              ? (data['totalPages'] as num?)?.toInt()
              : null;
      if (totalPages != null && page >= totalPages) break;
    }

    return all;
  }

  /// Uma página da biblioteca — sem loop client-side.
  Future<ExercicioPage> listarPagina({
    String? nome,
    String? busca,
    String? categoria,
    String? tag,
    String? musculoAlvo,
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    bool? hasVideo,
    String? videoSource,
    String? licenseStatus,
    String? editorialStatus,
    bool? favoritos,
    String? padraoMovimento,
    String? grupoMuscularPrimario,
    String? modalidade,
    String? dificuldade,
    int page = 0,
    int size = 40,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': 'nome,asc',
    };
    void put(String key, String? value) {
      if (value != null && value.isNotEmpty) queryParams[key] = value;
    }

    put('nome', nome);
    put('busca', busca);
    put('categoria', categoria);
    put('tag', tag);
    put('musculoAlvo', musculoAlvo);
    put('equipamento', equipamento);
    put('nivel', nivel);
    put('mecanica', mecanica);
    put('objetivo', objetivo);
    put('videoSource', videoSource);
    put('licenseStatus', licenseStatus);
    put('editorialStatus', editorialStatus);
    put('padraoMovimento', padraoMovimento);
    put('grupoMuscularPrimario', grupoMuscularPrimario);
    put('modalidade', modalidade);
    put('dificuldade', dificuldade);
    if (hasVideo != null) {
      queryParams['hasVideo'] = hasVideo ? 'true' : 'false';
    }
    if (favoritos == true) queryParams['favoritos'] = 'true';

    final response = await _dio.get(
      '/api/exercicios/v2',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['content'] as List? ?? const [])
        .map((e) => Exercicio.fromJson(e as Map<String, dynamic>))
        .toList();
    return ExercicioPage(
      content: list,
      meta: ExercicioPageMeta.fromJson(data),
    );
  }

  Future<ExercicioPickerPage> listarPickerPagina({
    String? busca,
    String? padraoMovimento,
    String? grupoMuscularPrimario,
    String? modalidade,
    String? dificuldade,
    String? espaco,
    String? equipamento,
    String? equipamentos,
    bool? hasVideo,
    bool? favoritos,
    int page = 0,
    int size = 30,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'size': size,
      'sort': 'nome,asc',
    };
    void put(String key, String? value) {
      if (value != null && value.isNotEmpty) queryParams[key] = value;
    }

    put('busca', busca);
    put('padraoMovimento', padraoMovimento);
    put('grupoMuscularPrimario', grupoMuscularPrimario);
    put('modalidade', modalidade);
    put('dificuldade', dificuldade);
    put('espaco', espaco);
    put('equipamento', equipamento);
    put('equipamentos', equipamentos);
    if (hasVideo != null) {
      queryParams['hasVideo'] = hasVideo ? 'true' : 'false';
    }
    if (favoritos == true) queryParams['favoritos'] = 'true';

    final response = await _dio.get(
      '/api/exercicios/picker',
      queryParameters: queryParams,
    );
    final data = response.data as Map<String, dynamic>;
    final list = (data['content'] as List? ?? const [])
        .map((e) => exercicioFromPickerJson(e as Map<String, dynamic>))
        .toList();
    final pageMeta = data['page'] as Map<String, dynamic>? ?? const {};
    return ExercicioPickerPage(
      content: list,
      meta: ExercicioPageMeta.fromJson(pageMeta),
    );
  }

  Future<ExercicioPickerStats> buscarPickerStats() async {
    final response = await _dio.get('/api/exercicios/picker/stats');
    return ExercicioPickerStats.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<Exercicio> buscar(int id) async {
    final response = await _dio.get('/api/exercicios/$id');
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> excluir(int id) async {
    await _dio.delete('/api/exercicios/$id');
  }

  Future<ExercicioEditorialQueue> buscarFilaEditorial(
    String status, {
    int size = 20,
  }) async {
    final response = await _dio.get(
      '/api/exercicios/v2',
      queryParameters: {
        'editorialStatus': status,
        'page': 0,
        'size': size,
        'sort': 'nome,asc',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final list =
        (data['content'] as List<dynamic>? ?? [])
            .map((e) => Exercicio.fromJson(e as Map<String, dynamic>))
            .toList();
    return ExercicioEditorialQueue(
      total: (data['totalElements'] as num?)?.toInt() ?? list.length,
      items: list,
    );
  }

  Future<Exercicio> criar({
    required String nome,
    String? descricao,
    String? musculoAlvo,
    String? categoria,
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    Modalidade? modalidade,
    PadraoMovimento? padraoMovimento,
    GrupoMuscular? grupoMuscularPrimario,
    List<Equipamento> equipamentos = const [],
    List<Espaco> espacosCompativeis = const [],
    Dificuldade? dificuldade,
    bool unilateral = false,
    String? errosComuns,
    String? contraindicacoes,
    String? substitutos,
    String? tags,
    String? observacoes,
  }) async {
    final response = await _dio.post(
      '/api/exercicios',
      data: {
        'nome': nome,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        if (musculoAlvo != null && musculoAlvo.isNotEmpty)
          'musculoAlvo': musculoAlvo,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        if (equipamento != null && equipamento.isNotEmpty)
          'equipamento': equipamento,
        if (nivel != null && nivel.isNotEmpty) 'nivel': nivel,
        if (mecanica != null && mecanica.isNotEmpty) 'mecanica': mecanica,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (modalidade != null) 'modalidade': modalidade.backendName,
        if (padraoMovimento != null)
          'padraoMovimento': padraoMovimento.backendName,
        if (grupoMuscularPrimario != null)
          'grupoMuscularPrimario': grupoMuscularPrimario.backendName,
        if (equipamentos.isNotEmpty)
          'equipamentosCurado': equipamentos
              .map((e) => e.backendName)
              .join(','),
        if (espacosCompativeis.isNotEmpty)
          'espacosCompativeis': espacosCompativeis
              .map((e) => e.backendName)
              .join(','),
        if (dificuldade != null) 'dificuldade': dificuldade.backendName,
        'unilateral': unilateral,
        if (errosComuns != null && errosComuns.isNotEmpty)
          'errosComuns': errosComuns,
        if (contraindicacoes != null && contraindicacoes.isNotEmpty)
          'contraindicacoes': contraindicacoes,
        if (substitutos != null && substitutos.isNotEmpty)
          'substitutos': substitutos,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exercicio> atualizar({
    required int id,
    required String nome,
    String? descricao,
    String? musculoAlvo,
    String? categoria,
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    Modalidade? modalidade,
    PadraoMovimento? padraoMovimento,
    GrupoMuscular? grupoMuscularPrimario,
    List<Equipamento> equipamentos = const [],
    List<Espaco> espacosCompativeis = const [],
    Dificuldade? dificuldade,
    bool unilateral = false,
    String? errosComuns,
    String? contraindicacoes,
    String? substitutos,
    String? tags,
    String? observacoes,
  }) async {
    final response = await _dio.put(
      '/api/exercicios/$id',
      data: {
        'nome': nome,
        if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
        if (musculoAlvo != null && musculoAlvo.isNotEmpty)
          'musculoAlvo': musculoAlvo,
        if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
        if (equipamento != null && equipamento.isNotEmpty)
          'equipamento': equipamento,
        if (nivel != null && nivel.isNotEmpty) 'nivel': nivel,
        if (mecanica != null && mecanica.isNotEmpty) 'mecanica': mecanica,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (modalidade != null) 'modalidade': modalidade.backendName,
        if (padraoMovimento != null)
          'padraoMovimento': padraoMovimento.backendName,
        if (grupoMuscularPrimario != null)
          'grupoMuscularPrimario': grupoMuscularPrimario.backendName,
        if (equipamentos.isNotEmpty)
          'equipamentosCurado': equipamentos
              .map((e) => e.backendName)
              .join(','),
        if (espacosCompativeis.isNotEmpty)
          'espacosCompativeis': espacosCompativeis
              .map((e) => e.backendName)
              .join(','),
        if (dificuldade != null) 'dificuldade': dificuldade.backendName,
        'unilateral': unilateral,
        if (errosComuns != null && errosComuns.isNotEmpty)
          'errosComuns': errosComuns,
        if (contraindicacoes != null && contraindicacoes.isNotEmpty)
          'contraindicacoes': contraindicacoes,
        if (substitutos != null && substitutos.isNotEmpty)
          'substitutos': substitutos,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exercicio> uploadVideo({
    required int id,
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: _videoContentType(filename),
      ),
    });
    final response = await _dio.post('/api/exercicios/$id/video', data: form);
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exercicio> removerVideo({required int id}) async {
    final response = await _dio.delete('/api/exercicios/$id/video');
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CuratedBibliotecaPreview> previewCuratedV2({
    required Set<Modalidade> modalidades,
    required Set<Espaco> espacos,
  }) async {
    final response = await _dio.get(
      '/api/exercicios/seed/curated/v2/preview',
      queryParameters: {
        'modalidades': modalidades.map((e) => e.backendName).join(','),
        'espacos': espacos.map((e) => e.backendName).join(','),
      },
    );
    return CuratedBibliotecaPreview.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<CuratedBibliotecaImport> importarCuratedV2({
    required Set<Modalidade> modalidades,
    required Set<Espaco> espacos,
  }) async {
    final response = await _dio.post(
      '/api/exercicios/seed/curated/v2/import',
      data: {
        'modalidades': modalidades.map((e) => e.backendName).toList(),
        'espacos': espacos.map((e) => e.backendName).toList(),
      },
    );
    return CuratedBibliotecaImport.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<Exercicio> uploadVideoExercicio(
    int exercicioId,
    String filePath,
  ) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(
      '/api/exercicios/$exercicioId/video',
      data: form,
    );
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  DioMediaType _videoContentType(String filename) {
    final ext = filename.toLowerCase().split('.').lastOrNull ?? '';
    return switch (ext) {
      'mov' => DioMediaType('video', 'quicktime'),
      'm4v' => DioMediaType('video', 'x-m4v'),
      'webm' => DioMediaType('video', 'webm'),
      _ => DioMediaType('video', 'mp4'),
    };
  }

  Future<Exercicio> atualizarCuradoriaEditorial({
    required int id,
    required String status,
    String? notes,
  }) async {
    final response = await _dio.patch(
      '/api/exercicios/$id/curadoria-editorial',
      data: {
        'editorialStatus': status,
        if (notes != null) 'editorialNotes': notes,
      },
    );
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> atualizarCuradoriaEditorialLote({
    required List<int> ids,
    required String status,
    String? notes,
  }) async {
    final response = await _dio.patch(
      '/api/exercicios/curadoria-editorial/lote',
      data: {
        'ids': ids,
        'editorialStatus': status,
        if (notes != null) 'editorialNotes': notes,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['atualizados'] as num?)?.toInt() ?? 0;
  }

  Future<int> importarSeedV1() async {
    final response = await _dio.post('/api/exercicios/importar/seed/v1');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['importados'] as int?) ?? (data['total'] as int?) ?? 0;
    }
    return 0;
  }

  Future<int> importarSeedPremiumV1() async {
    final data = await importarCuratedV2(
      modalidades: {
        Modalidade.musculacao,
        Modalidade.mobilidade,
        Modalidade.cardio,
      },
      espacos: {
        Espaco.academiaCompleta,
        Espaco.academiaBasica,
        Espaco.casaEquipada,
        Espaco.casaSemEquipo,
        Espaco.outdoor,
      },
    );
    return data.importados;
  }

  Future<int> enriquecerBibliotecaCurada() async {
    final response = await _dio.post(
      '/api/exercicios/seed/curated/v2/enriquecer',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['atualizados'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<int> publicarMidiasCuradas() async {
    final response = await _dio.post(
      '/api/exercicios/seed/curated/v2/publicar-midias',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['publicados'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<ExercicioCuradoriaResumo> buscarCuradoria() async {
    final response = await _dio.get('/api/exercicios/curadoria/resumo');
    return ExercicioCuradoriaResumo.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CuradoriaLoteResultado> curarLote({
    String? nome,
    String? categoria,
    String? tag,
    String? musculoAlvo,
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    bool? hasVideo,
    String? videoSource,
    String? licenseStatus,
    String? novoVideoUrl,
    String? novoThumbnailUrl,
    String? novoVideoSource,
    String? novoLicenseStatus,
  }) async {
    final data = <String, dynamic>{
      if (nome != null && nome.isNotEmpty) 'nome': nome,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      if (tag != null && tag.isNotEmpty) 'tag': tag,
      if (musculoAlvo != null && musculoAlvo.isNotEmpty)
        'musculoAlvo': musculoAlvo,
      if (equipamento != null && equipamento.isNotEmpty)
        'equipamento': equipamento,
      if (nivel != null && nivel.isNotEmpty) 'nivel': nivel,
      if (mecanica != null && mecanica.isNotEmpty) 'mecanica': mecanica,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (hasVideo != null) 'hasVideo': hasVideo,
      if (videoSource != null && videoSource.isNotEmpty)
        'videoSource': videoSource,
      if (licenseStatus != null && licenseStatus.isNotEmpty)
        'licenseStatus': licenseStatus,
      if (novoVideoUrl != null && novoVideoUrl.isNotEmpty)
        'novoVideoUrl': novoVideoUrl,
      if (novoThumbnailUrl != null && novoThumbnailUrl.isNotEmpty)
        'novoThumbnailUrl': novoThumbnailUrl,
      if (novoVideoSource != null && novoVideoSource.isNotEmpty)
        'novoVideoSource': novoVideoSource,
      if (novoLicenseStatus != null && novoLicenseStatus.isNotEmpty)
        'novoLicenseStatus': novoLicenseStatus,
    };
    final response = await _dio.patch(
      '/api/exercicios/curadoria/lote',
      data: data,
    );
    return CuradoriaLoteResultado.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ImportarMidiasResultado> importarMidias(
    List<Map<String, dynamic>> midias,
  ) async {
    final response = await _dio.post(
      '/api/exercicios/curadoria/midias/importar',
      data: {'midias': midias},
    );
    return ImportarMidiasResultado.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ImportarMidiasResultado> previewMidias(
    List<Map<String, dynamic>> midias,
  ) async {
    final response = await _dio.post(
      '/api/exercicios/curadoria/midias/preview',
      data: {'midias': midias},
    );
    return ImportarMidiasResultado.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<ExercicioMediaImportBatch>> historicoImportacaoMidias() async {
    final response = await _dio.get(
      '/api/exercicios/curadoria/midias/historico',
    );
    return ((response.data as List<dynamic>?) ?? [])
        .map(
          (e) => ExercicioMediaImportBatch.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> favoritarExercicio(int id) async {
    await _dio.post('/api/exercicios/$id/favoritar');
  }

  Future<void> desfavoritarExercicio(int id) async {
    await _dio.delete('/api/exercicios/$id/favoritar');
  }
}
