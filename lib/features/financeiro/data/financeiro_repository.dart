import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

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
    paymentId: j['paymentId'] as int,
    pixCopiaECola: j['pixCopiaECola'] as String,
    qrCodeBase64: j['qrCodeBase64'] as String,
    status: j['status'] as String,
  );
}

class Mensalidade {
  final int id;
  final int alunoId;
  final String alunoNome;
  final double valor;
  final String mesReferencia;
  final String status;
  final String? pagoEm;

  Mensalidade({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.valor,
    required this.mesReferencia,
    required this.status,
    this.pagoEm,
  });

  factory Mensalidade.fromJson(Map<String, dynamic> j) => Mensalidade(
    id: j['id'] as int,
    alunoId: j['alunoId'] as int,
    alunoNome: j['alunoNome'] as String,
    valor: (j['valor'] as num).toDouble(),
    mesReferencia: j['mesReferencia'] as String,
    status: j['status'] as String,
    pagoEm: j['pagoEm'] as String?,
  );
}

class VencimentoItem {
  final int mensalidadeId;
  final String alunoNome;
  final double valor;
  final String mesReferencia;
  final String status;

  VencimentoItem({
    required this.mensalidadeId,
    required this.alunoNome,
    required this.valor,
    required this.mesReferencia,
    required this.status,
  });

  factory VencimentoItem.fromJson(Map<String, dynamic> j) => VencimentoItem(
    mensalidadeId: j['mensalidadeId'] as int,
    alunoNome: j['alunoNome'] as String,
    valor: (j['valor'] as num).toDouble(),
    mesReferencia: j['mesReferencia'] as String,
    status: j['status'] as String,
  );
}

class TopAlunoItem {
  final int alunoId;
  final String alunoNome;
  final double totalPago;

  TopAlunoItem({
    required this.alunoId,
    required this.alunoNome,
    required this.totalPago,
  });

  factory TopAlunoItem.fromJson(Map<String, dynamic> j) => TopAlunoItem(
    alunoId: j['alunoId'] as int,
    alunoNome: j['alunoNome'] as String,
    totalPago: (j['totalPago'] as num).toDouble(),
  );
}

class EvolucaoMensalItem {
  final String mes;
  final double recebido;

  EvolucaoMensalItem({required this.mes, required this.recebido});

  factory EvolucaoMensalItem.fromJson(Map<String, dynamic> j) =>
      EvolucaoMensalItem(
        mes: j['mes'] as String,
        recebido: (j['recebido'] as num).toDouble(),
      );
}

class FinanceiroDashboard {
  final double receitaMes;
  final double receitaAcumulada;
  final double ticketMedio;
  final int totalInadimplentes;
  final double previsaoReceita;
  final List<VencimentoItem> vencimentosProximos;
  final List<TopAlunoItem> topAlunos;
  final List<EvolucaoMensalItem> evolucaoMensal;
  final String? zeroCta;

  FinanceiroDashboard({
    required this.receitaMes,
    required this.receitaAcumulada,
    required this.ticketMedio,
    required this.totalInadimplentes,
    required this.previsaoReceita,
    required this.vencimentosProximos,
    required this.topAlunos,
    required this.evolucaoMensal,
    this.zeroCta,
  });

  factory FinanceiroDashboard.fromJson(Map<String, dynamic> j) =>
      FinanceiroDashboard(
        receitaMes: (j['receitaMes'] as num).toDouble(),
        receitaAcumulada: (j['receitaAcumulada'] as num).toDouble(),
        ticketMedio: (j['ticketMedio'] as num).toDouble(),
        totalInadimplentes: j['totalInadimplentes'] as int,
        previsaoReceita: (j['previsaoReceita'] as num).toDouble(),
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
  final double totalRecebido;
  final double totalPrevisto;
  final int inadimplentes;
  final double ticketMedio;
  final double acumuladoAnual;

  ResumoMensal({
    required this.totalRecebido,
    required this.totalPrevisto,
    required this.inadimplentes,
    required this.ticketMedio,
    required this.acumuladoAnual,
  });

  factory ResumoMensal.fromJson(Map<String, dynamic> j) => ResumoMensal(
    totalRecebido: (j['totalRecebido'] as num? ?? 0).toDouble(),
    totalPrevisto: (j['totalPrevisto'] as num? ?? 0).toDouble(),
    inadimplentes:
        (j['inadimplentes'] as num? ?? j['totalInadimplentes'] as num? ?? 0)
            .toInt(),
    ticketMedio: (j['ticketMedio'] as num? ?? 0).toDouble(),
    acumuladoAnual: (j['acumuladoAnual'] as num? ?? 0).toDouble(),
  );
}

class FinanceiroRepository {
  final Dio _dio;
  FinanceiroRepository(ApiClient c) : _dio = c.dio;

  Future<List<Mensalidade>> listarPorAluno(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/historico-mensalidades');
    return (r.data as List).map((e) => Mensalidade.fromJson(e)).toList();
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

  Future<void> atualizarAtrasos() async {
    await _dio.patch('/api/financeiro/mensalidades/atualizar-atrasos');
  }

  Future<FinanceiroDashboard> dashboard() async {
    final r = await _dio.get('/api/financeiro/mensalidades/dashboard');
    return FinanceiroDashboard.fromJson(r.data as Map<String, dynamic>);
  }

  /// BFF first paint — dashboard + mensalidades + resumo do mês corrente.
  Future<FinanceiroHomeBundle> getHome() async {
    final r = await _dio.get('/api/financeiro/home');
    return FinanceiroHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Mensalidade>> listar() async {
    final r = await _dio.get('/api/financeiro/mensalidades');
    return (r.data as List).map((e) => Mensalidade.fromJson(e)).toList();
  }

  Future<Mensalidade> criar(
    int alunoId,
    double valor,
    String mesReferencia,
  ) async {
    final r = await _dio.post(
      '/api/financeiro/mensalidades',
      data: {
        'alunoId': alunoId,
        'valor': valor,
        'mesReferencia': mesReferencia,
      },
    );
    return Mensalidade.fromJson(r.data);
  }

  Future<Mensalidade> pagar(int id) async {
    final r = await _dio.put('/api/financeiro/mensalidades/$id/pagar');
    return Mensalidade.fromJson(r.data);
  }

  Future<PixData> gerarPix(int mensalidadeId) async {
    final r = await _dio.post(
      '/api/financeiro/mensalidades/$mensalidadeId/pix',
    );
    return PixData.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Mensalidade> editarMensalidade(
    int id, {
    double? valor,
    String? mesReferencia,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (valor != null) body['valor'] = valor;
    if (mesReferencia != null) body['mesReferencia'] = mesReferencia;
    if (status != null) body['status'] = status;
    final r = await _dio.put('/api/financeiro/mensalidades/$id', data: body);
    return Mensalidade.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Mensalidade>> listarPorNome(String nome) async {
    final r = await _dio.get(
      '/api/financeiro/mensalidades',
      queryParameters: {'nomeAluno': nome},
    );
    return (r.data as List).map((e) => Mensalidade.fromJson(e)).toList();
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

  Future<List<Mensalidade>> minhasMensalidades() async {
    final r = await _dio.get('/api/financeiro/mensalidades/aluno/minhas');
    return (r.data as List).map((e) => Mensalidade.fromJson(e)).toList();
  }
}

/// BFF `GET /api/financeiro/home`.
class FinanceiroHomeBundle {
  final FinanceiroDashboard dashboard;
  final List<Mensalidade> mensalidades;
  final ResumoMensal resumoMesAtual;
  final DateTime fetchedAt;

  FinanceiroHomeBundle({
    required this.dashboard,
    required this.mensalidades,
    required this.resumoMesAtual,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory FinanceiroHomeBundle.fromJson(Map<String, dynamic> j) {
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
    );
  }
}
