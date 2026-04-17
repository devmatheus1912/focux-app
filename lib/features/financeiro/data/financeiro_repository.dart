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

  Mensalidade({required this.id, required this.alunoId, required this.alunoNome,
    required this.valor, required this.mesReferencia, required this.status, this.pagoEm});

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

  VencimentoItem({required this.mensalidadeId, required this.alunoNome,
    required this.valor, required this.mesReferencia, required this.status});

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

  TopAlunoItem({required this.alunoId, required this.alunoNome, required this.totalPago});

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

  factory EvolucaoMensalItem.fromJson(Map<String, dynamic> j) => EvolucaoMensalItem(
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

  FinanceiroDashboard({
    required this.receitaMes, required this.receitaAcumulada,
    required this.ticketMedio, required this.totalInadimplentes,
    required this.previsaoReceita, required this.vencimentosProximos,
    required this.topAlunos, required this.evolucaoMensal,
  });

  factory FinanceiroDashboard.fromJson(Map<String, dynamic> j) => FinanceiroDashboard(
    receitaMes: (j['receitaMes'] as num).toDouble(),
    receitaAcumulada: (j['receitaAcumulada'] as num).toDouble(),
    ticketMedio: (j['ticketMedio'] as num).toDouble(),
    totalInadimplentes: j['totalInadimplentes'] as int,
    previsaoReceita: (j['previsaoReceita'] as num).toDouble(),
    vencimentosProximos: (j['vencimentosProximos'] as List)
        .map((e) => VencimentoItem.fromJson(e as Map<String, dynamic>)).toList(),
    topAlunos: (j['topAlunos'] as List)
        .map((e) => TopAlunoItem.fromJson(e as Map<String, dynamic>)).toList(),
    evolucaoMensal: (j['evolucaoMensal'] as List)
        .map((e) => EvolucaoMensalItem.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

class FinanceiroRepository {
  final Dio _dio;
  FinanceiroRepository(ApiClient c) : _dio = c.dio;

  Future<FinanceiroDashboard> dashboard() async {
    final r = await _dio.get('/api/financeiro/mensalidades/dashboard');
    return FinanceiroDashboard.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Mensalidade>> listar() async {
    final r = await _dio.get('/api/financeiro/mensalidades');
    return (r.data as List).map((e) => Mensalidade.fromJson(e)).toList();
  }

  Future<Mensalidade> criar(int alunoId, double valor, String mesReferencia) async {
    final r = await _dio.post('/api/financeiro/mensalidades', data: {
      'alunoId': alunoId,
      'valor': valor,
      'mesReferencia': mesReferencia,
    });
    return Mensalidade.fromJson(r.data);
  }

  Future<Mensalidade> pagar(int id) async {
    final r = await _dio.put('/api/financeiro/mensalidades/$id/pagar');
    return Mensalidade.fromJson(r.data);
  }

  Future<PixData> gerarPix(int mensalidadeId) async {
    final r = await _dio.post('/api/financeiro/mensalidades/$mensalidadeId/pix');
    return PixData.fromJson(r.data as Map<String, dynamic>);
  }
}
