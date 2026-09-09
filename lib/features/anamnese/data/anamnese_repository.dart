import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

/// Status do fluxo solicitar → preencher → revisar.
abstract final class AnamneseStatus {
  static const naoIniciada = 'NAO_INICIADA';
  static const solicitada = 'SOLICITADA';
  static const preenchida = 'PREENCHIDA';
  static const revisada = 'REVISADA';
  static const precisaAtestado = 'PRECISA_ATESTADO';

  static const all = {
    naoIniciada,
    solicitada,
    preenchida,
    revisada,
    precisaAtestado,
  };
}

/// Status aceitos no PUT de revisão do personal.
abstract final class AnamneseRevisaoStatus {
  static const revisada = AnamneseStatus.revisada;
  static const precisaAtestado = AnamneseStatus.precisaAtestado;
  static const solicitada = AnamneseStatus.solicitada;
}

class Anamnese {
  final int? id;
  final String status;
  final bool? parqPositivo;
  final bool? parqCompleto;
  final List<String> alertas;

  // PAR-Q+
  final bool? parqCondicaoCardiaca;
  final bool? parqDorPeitoAtividade;
  final bool? parqDorPeitoRepouso;
  final bool? parqTonturaDesmaio;
  final bool? parqProblemaOsseoArticular;
  final bool? parqMedicacaoPressaoCoracao;
  final bool? parqOutraRazao;
  final String? parqOutraRazaoDetalhe;

  // Saúde
  final String? historicoMedico;
  final String? cirurgias;
  final String? doresCronicas;
  final String? lesoes;
  final String? medicamentos;
  final String? alergias;
  final String? gestacaoPosParto;
  final String? historicoFamiliarCv;
  final String? sintomasCv;

  // Hábitos
  final double? sonoHoras;
  final String? qualidadeSono;
  final String? nivelEstresse;
  final String? tabagismo;
  final String? alcool;
  final String? observacoes;

  // Treino / objetivos
  final String? objetivo;
  final String? objetivoDetalhado;
  final int? disponibilidadeSemanal;
  final String? preferenciasTreino;
  final String? restricoesAlimentares;
  final String? historicoAtividade;
  final String? motivoInterrupcoes;
  final String? motivacaoAtual;
  final String? algoMais;

  /// Campo legado — ainda pode vir do backend em fichas antigas.
  final String? nivelAtividade;

  // Personal (revisão)
  final String? notasProfissional;
  final String? atestadoObs;

  // Timestamps
  final String? solicitadaEm;
  final String? preenchidaEm;
  final String? revisadaEm;
  final String? atualizadoEm;

  Anamnese({
    this.id,
    this.status = AnamneseStatus.naoIniciada,
    this.parqPositivo,
    this.parqCompleto,
    this.alertas = const [],
    this.parqCondicaoCardiaca,
    this.parqDorPeitoAtividade,
    this.parqDorPeitoRepouso,
    this.parqTonturaDesmaio,
    this.parqProblemaOsseoArticular,
    this.parqMedicacaoPressaoCoracao,
    this.parqOutraRazao,
    this.parqOutraRazaoDetalhe,
    this.historicoMedico,
    this.cirurgias,
    this.doresCronicas,
    this.lesoes,
    this.medicamentos,
    this.alergias,
    this.gestacaoPosParto,
    this.historicoFamiliarCv,
    this.sintomasCv,
    this.sonoHoras,
    this.qualidadeSono,
    this.nivelEstresse,
    this.tabagismo,
    this.alcool,
    this.observacoes,
    this.objetivo,
    this.objetivoDetalhado,
    this.disponibilidadeSemanal,
    this.preferenciasTreino,
    this.restricoesAlimentares,
    this.historicoAtividade,
    this.motivoInterrupcoes,
    this.motivacaoAtual,
    this.algoMais,
    this.nivelAtividade,
    this.notasProfissional,
    this.atestadoObs,
    this.solicitadaEm,
    this.preenchidaEm,
    this.revisadaEm,
    this.atualizadoEm,
  });

  bool get isNaoIniciada => status == AnamneseStatus.naoIniciada;
  bool get isSolicitada => status == AnamneseStatus.solicitada;
  bool get isPreenchida => status == AnamneseStatus.preenchida;
  bool get isRevisada => status == AnamneseStatus.revisada;
  bool get isPrecisaAtestado => status == AnamneseStatus.precisaAtestado;

  /// Aluno precisa agir (preencher ou atualizar / atestado).
  bool get alunoDevePreencher =>
      isSolicitada || isPrecisaAtestado;

  /// Personal pode revisar o conteúdo preenchido pelo aluno.
  bool get personalPodeRevisar =>
      isPreenchida || isRevisada || isPrecisaAtestado;

  factory Anamnese.fromJson(Map<String, dynamic> j) => Anamnese(
    id: j['id'] as int?,
    status: _statusOrDefault(j['status']),
    parqPositivo: j['parqPositivo'] as bool?,
    parqCompleto: j['parqCompleto'] as bool?,
    alertas: _stringList(j['alertas']),
    parqCondicaoCardiaca: j['parqCondicaoCardiaca'] as bool?,
    parqDorPeitoAtividade: j['parqDorPeitoAtividade'] as bool?,
    parqDorPeitoRepouso: j['parqDorPeitoRepouso'] as bool?,
    parqTonturaDesmaio: j['parqTonturaDesmaio'] as bool?,
    parqProblemaOsseoArticular: j['parqProblemaOsseoArticular'] as bool?,
    parqMedicacaoPressaoCoracao: j['parqMedicacaoPressaoCoracao'] as bool?,
    parqOutraRazao: j['parqOutraRazao'] as bool?,
    parqOutraRazaoDetalhe: j['parqOutraRazaoDetalhe'] as String?,
    historicoMedico: j['historicoMedico'] as String?,
    cirurgias: j['cirurgias'] as String?,
    doresCronicas: j['doresCronicas'] as String?,
    lesoes: j['lesoes'] as String?,
    medicamentos: j['medicamentos'] as String?,
    alergias: j['alergias'] as String?,
    gestacaoPosParto: j['gestacaoPosParto'] as String?,
    historicoFamiliarCv: j['historicoFamiliarCv'] as String?,
    sintomasCv: j['sintomasCv'] as String?,
    sonoHoras: _parseSonoHoras(j['sonoHoras']),
    qualidadeSono: j['qualidadeSono'] as String?,
    nivelEstresse: j['nivelEstresse'] as String?,
    tabagismo: j['tabagismo'] as String?,
    alcool: j['alcool'] as String?,
    observacoes: j['observacoes'] as String?,
    objetivo: j['objetivo'] as String?,
    objetivoDetalhado: j['objetivoDetalhado'] as String?,
    disponibilidadeSemanal: (j['disponibilidadeSemanal'] as num?)?.toInt(),
    preferenciasTreino: j['preferenciasTreino'] as String?,
    restricoesAlimentares: j['restricoesAlimentares'] as String?,
    historicoAtividade: j['historicoAtividade'] as String?,
    motivoInterrupcoes: j['motivoInterrupcoes'] as String?,
    motivacaoAtual: j['motivacaoAtual'] as String?,
    algoMais: j['algoMais'] as String?,
    nivelAtividade: j['nivelAtividade'] as String?,
    notasProfissional: j['notasProfissional'] as String?,
    atestadoObs: j['atestadoObs'] as String?,
    solicitadaEm: j['solicitadaEm'] as String?,
    preenchidaEm: j['preenchidaEm'] as String?,
    revisadaEm: j['revisadaEm'] as String?,
    atualizadoEm: j['atualizadoEm'] as String?,
  );

  static String _statusOrDefault(Object? raw) {
    final s = raw as String?;
    if (s != null && AnamneseStatus.all.contains(s)) return s;
    return AnamneseStatus.naoIniciada;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}

class AnamneseRevisaoRequest {
  const AnamneseRevisaoRequest({
    required this.status,
    this.notasProfissional,
    this.atestadoObs,
  });

  final String status;
  final String? notasProfissional;
  final String? atestadoObs;

  Map<String, dynamic> toJson() => {
    'status': status,
    if (notasProfissional != null) 'notasProfissional': notasProfissional,
    if (atestadoObs != null) 'atestadoObs': atestadoObs,
  };
}

class AnamneseRepository {
  final Dio _dio;
  AnamneseRepository(ApiClient c) : _dio = c.dio;

  /// Personal: lê a ficha do aluno.
  Future<Anamnese> buscar(int alunoId) async => Anamnese.fromJson(
    (await _dio.get('/api/alunos/$alunoId/anamnese')).data,
  );

  /// Personal: solicita preenchimento (NAO_INICIADA / REVISADA → SOLICITADA).
  Future<Anamnese> solicitar(int alunoId) async => Anamnese.fromJson(
    (await _dio.post('/api/alunos/$alunoId/anamnese/solicitar')).data,
  );

  /// Personal: revisa (REVISADA | PRECISA_ATESTADO | SOLICITADA).
  Future<Anamnese> revisar(int alunoId, AnamneseRevisaoRequest body) async =>
      Anamnese.fromJson(
        (await _dio.put(
          '/api/alunos/$alunoId/anamnese/revisao',
          data: body.toJson(),
        )).data,
      );

  /// Aluno: lê a própria ficha.
  Future<Anamnese> buscarMinha() async =>
      Anamnese.fromJson((await _dio.get('/api/aluno/anamnese')).data);

  /// Aluno: preenche/atualiza → sempre PREENCHIDA.
  Future<Anamnese> salvarMinha(Map<String, dynamic> data) async =>
      Anamnese.fromJson(
        (await _dio.put('/api/aluno/anamnese', data: data)).data,
      );
}

double? _parseSonoHoras(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final trimmed = raw.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
  return null;
}
