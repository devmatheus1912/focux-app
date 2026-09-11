import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../../core/money/fx_money.dart';
import '../../planos/data/planos_repository.dart';

class PixData {
  final int paymentId;
  final String pixCopiaECola;
  final String qrCodeBase64;
  final String status;

  PixData({
    required this.paymentId,
    required this.pixCopiaECola,
    required this.qrCodeBase64,
    required this.status,
  });

  factory PixData.fromJson(Map<String, dynamic> j) => PixData(
    paymentId: (j['paymentId'] as num?)?.toInt() ?? 0,
    pixCopiaECola: j['pixCopiaECola']?.toString() ?? '',
    qrCodeBase64: j['qrCodeBase64']?.toString() ?? '',
    status: j['status']?.toString() ?? '',
  );
}

class Mensalidade {
  final int id;
  final int alunoId;
  final String alunoNome;
  final FxMoney valor;
  final String mesReferencia;
  final String status;
  final String? pagoEm;
  final String? vencimento;
  final List<MensalidadeContato>? contatos;

  Mensalidade({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required Object valor,
    required this.mesReferencia,
    required this.status,
    this.pagoEm,
    this.vencimento,
    this.contatos,
  }) : valor = FxMoney.parse(valor);

  factory Mensalidade.fromJson(Map<String, dynamic> j) {
    final raw = j['contatos'];
    return Mensalidade(
      id: (j['id'] as num?)?.toInt() ?? 0,
      alunoId: (j['alunoId'] as num?)?.toInt() ?? 0,
      alunoNome: j['alunoNome']?.toString() ?? '',
      valor: j['valor'],
      mesReferencia: j['mesReferencia']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      pagoEm: j['pagoEm']?.toString(),
      vencimento: j['vencimento']?.toString(),
      contatos: raw is List
          ? raw
              .whereType<Map>()
              .map(
                (e) => MensalidadeContato.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : null,
    );
  }
}

class MensalidadeContato {
  final int id;
  final String tipo;
  final String? observacao;
  final String? registradoEm;

  const MensalidadeContato({
    required this.id,
    required this.tipo,
    this.observacao,
    this.registradoEm,
  });

  factory MensalidadeContato.fromJson(Map<String, dynamic> j) =>
      MensalidadeContato(
        id: (j['id'] as num).toInt(),
        tipo: j['tipo'] as String? ?? '',
        observacao: j['observacao'] as String?,
        registradoEm: j['registradoEm'] as String?,
      );
}

class VencimentoItem {
  final int mensalidadeId;
  final int? alunoId;
  final String alunoNome;
  final FxMoney valor;
  final String mesReferencia;
  final String? vencimento;
  final String status;

  VencimentoItem({
    required this.mensalidadeId,
    this.alunoId,
    required this.alunoNome,
    required Object valor,
    required this.mesReferencia,
    required this.status,
    this.vencimento,
  }) : valor = FxMoney.parse(valor);

  factory VencimentoItem.fromJson(Map<String, dynamic> j) => VencimentoItem(
    mensalidadeId: j['mensalidadeId'] as int,
    alunoId: (j['alunoId'] as num?)?.toInt(),
    alunoNome: j['alunoNome'] as String,
    valor: j['valor'],
    mesReferencia: j['mesReferencia'] as String,
    vencimento: j['vencimento'] as String?,
    status: j['status'] as String,
  );
}

class TopAlunoItem {
  final int alunoId;
  final String alunoNome;
  final FxMoney totalPago;

  TopAlunoItem({
    required this.alunoId,
    required this.alunoNome,
    required Object totalPago,
  }) : totalPago = FxMoney.parse(totalPago);

  factory TopAlunoItem.fromJson(Map<String, dynamic> j) => TopAlunoItem(
    alunoId: j['alunoId'] as int,
    alunoNome: j['alunoNome'] as String,
    totalPago: j['totalPago'],
  );
}

class EvolucaoMensalItem {
  final String mes;
  final FxMoney recebido;

  EvolucaoMensalItem({required this.mes, required Object recebido})
    : recebido = FxMoney.parse(recebido);

  factory EvolucaoMensalItem.fromJson(Map<String, dynamic> j) =>
      EvolucaoMensalItem(mes: j['mes'] as String, recebido: j['recebido']);
}

class FinanceiroDashboard {
  final FxMoney receitaMes;
  final FxMoney receitaAcumulada;
  final FxMoney ticketMedio;
  final int totalInadimplentes;
  final FxMoney previsaoReceita;
  final List<VencimentoItem> vencimentosProximos;
  final List<TopAlunoItem> topAlunos;
  final List<EvolucaoMensalItem> evolucaoMensal;
  final String? zeroCta;

  FinanceiroDashboard({
    required Object receitaMes,
    required Object receitaAcumulada,
    required Object ticketMedio,
    required this.totalInadimplentes,
    required Object previsaoReceita,
    required this.vencimentosProximos,
    required this.topAlunos,
    required this.evolucaoMensal,
    this.zeroCta,
  }) : receitaMes = FxMoney.parse(receitaMes),
       receitaAcumulada = FxMoney.parse(receitaAcumulada),
       ticketMedio = FxMoney.parse(ticketMedio),
       previsaoReceita = FxMoney.parse(previsaoReceita);

  factory FinanceiroDashboard.fromJson(Map<String, dynamic> j) =>
      FinanceiroDashboard(
        receitaMes: j['receitaMes'],
        receitaAcumulada: j['receitaAcumulada'],
        ticketMedio: j['ticketMedio'],
        totalInadimplentes: j['totalInadimplentes'] as int,
        previsaoReceita: j['previsaoReceita'],
        zeroCta: j['zeroCta'] as String?,
        vencimentosProximos:
            (j['vencimentosProximos'] as List)
                .map((e) => VencimentoItem.fromJson(e as Map<String, dynamic>))
                .toList(),
        topAlunos:
            (j['topAlunos'] as List)
                .map((e) => TopAlunoItem.fromJson(e as Map<String, dynamic>))
                .toList(),
        evolucaoMensal:
            (j['evolucaoMensal'] as List)
                .map(
                  (e) => EvolucaoMensalItem.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
      );
}

class ResumoMensal {
  final FxMoney totalRecebido;
  final FxMoney totalPrevisto;
  final int inadimplentes;
  final FxMoney ticketMedio;
  final FxMoney acumuladoAnual;

  ResumoMensal({
    required Object totalRecebido,
    required Object totalPrevisto,
    required this.inadimplentes,
    required Object ticketMedio,
    required Object acumuladoAnual,
  }) : totalRecebido = FxMoney.parse(totalRecebido),
       totalPrevisto = FxMoney.parse(totalPrevisto),
       ticketMedio = FxMoney.parse(ticketMedio),
       acumuladoAnual = FxMoney.parse(acumuladoAnual);

  factory ResumoMensal.fromJson(Map<String, dynamic> j) => ResumoMensal(
    totalRecebido: j['totalRecebido'] ?? 0,
    totalPrevisto: j['totalPrevisto'] ?? 0,
    inadimplentes:
        (j['inadimplentes'] as num? ?? j['totalInadimplentes'] as num? ?? 0)
            .toInt(),
    ticketMedio: j['ticketMedio'] ?? 0,
    acumuladoAnual: j['acumuladoAnual'] ?? 0,
  );
}

class FinanceiroRepository {
  final Dio _dio;
  FinanceiroRepository(ApiClient c) : _dio = c.dio;

  Future<List<Mensalidade>> listarPorAluno(int alunoId, {int page = 0, int size = 100}) async {
    final r = await _dio.get(
      '/api/alunos/$alunoId/historico-mensalidades',
      queryParameters: {'page': page, 'size': size},
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/alunos/{id}/historico-mensalidades devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (e) => Mensalidade.fromJson(e as Map<String, dynamic>),
    ).content;
  }

  Future<void> registrarContato(
    int mensalidadeId,
    String tipo,
    String? observacao,
  ) async {
    await _dio.post(
      '/api/financeiro/mensalidades/$mensalidadeId/registrar-contato',
      data: {
        'tipo': tipo,
        if (observacao != null && observacao.isNotEmpty)
          'observacao': observacao,
      },
    );
  }

  Future<List<MensalidadeContato>> listarContatos(int mensalidadeId) async {
    final r = await _dio.get(
      '/api/financeiro/mensalidades/$mensalidadeId/contatos',
    );
    return (r.data as List)
        .whereType<Map>()
        .map(
          (e) => MensalidadeContato.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<void> atualizarAtrasos() async {
    await _dio.patch('/api/financeiro/mensalidades/atualizar-atrasos');
  }

  Future<void> marcarLotePago(List<int> alunoIds) async {
    final ids = alunoIds.toSet().toList();
    await _dio.post(
      '/api/financeiro/mensalidades/lote-pago',
      data: {'alunoIds': ids},
      options: ApiClient.idempotent('mensalidade-lote-${ids.join('-')}'),
    );
  }

  /// BFF first paint — dashboard + primeira página + resumo + planoFeatures.
  Future<FinanceiroHomeBundle> getHome() async {
    final r = await _dio.get('/api/financeiro/home');
    return FinanceiroHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MensalidadesPage> listarPagina({
    int page = 0,
    int size = 20,
    String? nomeAluno,
    int? alunoId,
  }) async {
    final r = await _dio.get(
      '/api/financeiro/mensalidades',
      queryParameters: {
        'page': page,
        'size': size,
        if (nomeAluno != null && nomeAluno.trim().isNotEmpty)
          'nomeAluno': nomeAluno.trim(),
        if (alunoId != null) 'alunoId': alunoId,
      },
    );
    return MensalidadesPage.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Mensalidade> buscar(int id) async {
    final r = await _dio.get('/api/financeiro/mensalidades/$id');
    return Mensalidade.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Mensalidade> criar(
    int alunoId,
    FxMoney valor,
    String mesReferencia,
  ) async {
    final r = await _dio.post(
      '/api/financeiro/mensalidades',
      data: {
        'alunoId': alunoId,
        'valor': valor.wire,
        'mesReferencia': mesReferencia,
      },
      // Aluno + mês já identificam a mensalidade: duas submissões são a
      // mesma intenção, não duas cobranças.
      options: ApiClient.idempotent('mensalidade-criar-$alunoId-$mesReferencia'),
    );
    return Mensalidade.fromJson(r.data);
  }

  Future<Mensalidade> pagar(int id) async {
    final r = await _dio.put(
      '/api/financeiro/mensalidades/$id/pagar',
      options: ApiClient.idempotent('mensalidade-pagar-$id'),
    );
    return Mensalidade.fromJson(r.data);
  }

  Future<PixData> gerarPix(int mensalidadeId) async {
    final r = await _dio.post(
      '/api/financeiro/mensalidades/$mensalidadeId/pix',
      // Sem chave estável, dois toques geram duas cobranças PIX para a mesma
      // mensalidade e o aluno recebe dois QR codes válidos.
      options: ApiClient.idempotent('mensalidade-pix-$mensalidadeId'),
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException('POST .../pix devolve objeto PIX.');
    }
    return PixData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<PixData> gerarPixAluno(int mensalidadeId) async {
    final r = await _dio.post(
      '/api/financeiro/mensalidades/aluno/minhas/$mensalidadeId/pix',
      options: ApiClient.idempotent('mensalidade-pix-aluno-$mensalidadeId'),
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException('POST .../aluno/.../pix devolve objeto PIX.');
    }
    return PixData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Mensalidade> editarMensalidade(
    int id, {
    FxMoney? valor,
    String? mesReferencia,
    String? vencimento,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (valor != null) body['valor'] = valor.wire;
    if (mesReferencia != null) body['mesReferencia'] = mesReferencia;
    if (vencimento != null) body['vencimento'] = vencimento;
    if (status != null) body['status'] = status;
    final r = await _dio.put('/api/financeiro/mensalidades/$id', data: body);
    return Mensalidade.fromJson(r.data as Map<String, dynamic>);
  }

  Future<ResumoMensal> resumoMensal(int ano, int mes) async {
    final r = await _dio.get(
      '/api/financeiro/mensalidades/resumo-mensal',
      queryParameters: {'ano': ano, 'mes': mes},
    );
    return ResumoMensal.fromJson(r.data as Map<String, dynamic>);
  }

  Future<String> cobrarViaChat(int id) async {
    final r = await _dio.post('/api/financeiro/mensalidades/$id/cobrar-chat');
    final data = r.data;
    if (data is Map<String, dynamic>) {
      return data['mensagem']?.toString() ??
          data['message']?.toString() ??
          'Cobrança enviada!';
    }
    return data?.toString() ?? 'Cobrança enviada!';
  }

  Future<MensalidadesPage> minhasMensalidades({int page = 0, int size = 20}) async {
    final r = await _dio.get(
      '/api/financeiro/mensalidades/aluno/minhas',
      queryParameters: {'page': page, 'size': size},
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/financeiro/mensalidades/aluno/minhas devolve objeto, não lista crua.',
      );
    }
    return MensalidadesPage.fromJson(Map<String, dynamic>.from(data));
  }
}

/// Página de `GET /api/financeiro/mensalidades` e `.../aluno/minhas`.
class MensalidadesPage {
  final List<Mensalidade> mensalidades;
  final int page;
  final int size;
  final bool hasMore;

  MensalidadesPage({
    required this.mensalidades,
    this.page = 0,
    this.size = 20,
    this.hasMore = false,
  });

  factory MensalidadesPage.fromJson(Map<String, dynamic> j) => MensalidadesPage(
    mensalidades:
        (j['mensalidades'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) => Mensalidade.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList(),
    page: (j['page'] as num?)?.toInt() ?? 0,
    size: (j['size'] as num?)?.toInt() ?? 20,
    hasMore: j['hasMore'] == true,
  );
}

/// BFF `GET /api/financeiro/home`.
class FinanceiroHomeBundle {
  final FinanceiroDashboard dashboard;
  final List<Mensalidade> mensalidades;
  final ResumoMensal resumoMesAtual;
  final PlanoFeatures? planoFeatures;
  final int page;
  final int size;
  final bool hasMore;
  final DateTime fetchedAt;

  FinanceiroHomeBundle({
    required this.dashboard,
    required this.mensalidades,
    required this.resumoMesAtual,
    this.planoFeatures,
    this.page = 0,
    this.size = 20,
    this.hasMore = false,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory FinanceiroHomeBundle.fromJson(Map<String, dynamic> j) {
    final planoRaw = j['planoFeatures'];
    return FinanceiroHomeBundle(
      dashboard: FinanceiroDashboard.fromJson(
        j['dashboard'] as Map<String, dynamic>,
      ),
      mensalidades:
          (j['mensalidades'] as List? ?? const [])
              .map((e) => Mensalidade.fromJson(e as Map<String, dynamic>))
              .toList(),
      resumoMesAtual: ResumoMensal.fromJson(
        j['resumoMesAtual'] as Map<String, dynamic>? ?? const {},
      ),
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
      page: (j['page'] as num?)?.toInt() ?? 0,
      size: (j['size'] as num?)?.toInt() ?? 20,
      hasMore: j['hasMore'] == true,
    );
  }
}
