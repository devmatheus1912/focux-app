import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/api/api_etag_store.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_dashboard_home_client_cache.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simula BFF com ETag: 200 na 1ª, 304 se If-None-Match casar.
class _EtagHomeAdapter implements HttpClientAdapter {
  _EtagHomeAdapter({required this.path, required this.body});

  final String path;
  final Map<String, dynamic> body;
  final List<String?> ifNoneMatch = [];
  final List<int> statusCodes = [];
  var _etag = '"home-v1"';

  void bumpEtag() => _etag = '"home-v2"';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final inm = options.headers['If-None-Match'] as String?;
    ifNoneMatch.add(inm);
    if (inm == _etag) {
      statusCodes.add(304);
      return ResponseBody.fromString(
        '',
        304,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
          'etag': [_etag],
        },
      );
    }
    statusCodes.add(200);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        'etag': [_etag],
        'cache-control': ['private, max-age=60'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _minimalAlunoHomeJson() => {
  'aluno': {'id': 1, 'nome': 'Ana', 'email': 'a@t.com', 'status': 'ATIVO'},
  'personalBrand': {},
  'treinos': [],
  'historicoResumo': [
    {
      'id': 7,
      'treinoId': 2,
      'treinoNome': 'Resumo',
      'status': 'CONCLUIDO',
      'iniciadoEm': '2026-09-18T10:00:00Z',
      'concluidoEm': '2026-09-18T11:00:00Z',
    },
  ],
  'historico': [],
  'medidas': [],
  'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
  'notificacoesNaoLidas': 0,
  'coachMensagens': [],
};

Map<String, dynamic> _minimalPersonalHomeJson() => {
  'personal': {
    'totalAlunos': 1,
    'alunosAtivos': 1,
    'planoAtual': 'PRO',
    'limiteAlunos': 50,
    'nomePersonal': 'Matheus',
  },
  'commandCenter': {
    'agendaHoje': [],
    'alunosEmRisco': [],
    'alunosScore': [],
    'cobrancasPendentes': [],
    'autonomiaGargalos': [],
    'modoOperacao': [],
    'filaAcoes': [],
  },
  'financeiro': {
    'receitaMes': '0',
    'receitaAcumulada': '0',
    'ticketMedio': '0',
    'totalInadimplentes': 0,
    'previsaoReceita': '0',
    'vencimentosProximos': [],
    'topAlunos': [],
    'evolucaoMensal': [],
  },
  'pulse': {
    'checkinsHoje': 2,
    'mensagensNaoLidas': 1,
    'coachPendentes': 3,
    'checkinsTrend': [0, 0, 1, 0, 2, 0, 1],
  },
  'dayFocus': {
    'kind': 'ESTAVEL',
    'coversRetention': false,
    'riskDominante': false,
    'headline': 'Dia estável',
    'detail': '',
    'semanticLabel': 'Foco',
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiEtagStore.clear();
    AlunoDashboardHomeClientCache.clear();
    DashboardHomeClientCache.clear();
  });

  tearDown(() {
    ApiEtagStore.clear();
    AlunoDashboardHomeClientCache.clear();
    DashboardHomeClientCache.clear();
  });

  test('ApiEtagStore keyFor normaliza path sem query', () {
    expect(
      ApiEtagStore.keyFor(method: 'get', path: '/api/dashboard/aluno/home?x=1'),
      'GET /api/dashboard/aluno/home',
    );
  });

  test('GET aluno/home: If-None-Match → 304 → repository null (cache hit)', () async {
    final adapter = _EtagHomeAdapter(
      path: '/api/dashboard/aluno/home',
      body: _minimalAlunoHomeJson(),
    );
    final client = ApiClient()..dio.httpClientAdapter = adapter;
    final repo = DashboardRepository(client);

    final first = await repo.getAlunoHome();
    expect(first, isNotNull);
    expect(first!.historico, hasLength(1));
    expect(first.historico.first.treinoNome, 'Resumo');
    expect(adapter.statusCodes, [200]);
    expect(adapter.ifNoneMatch.first, isNull);

    final stored = ApiEtagStore.get(
      ApiEtagStore.keyFor(method: 'GET', path: '/api/dashboard/aluno/home'),
    );
    expect(stored, '"home-v1"');

    final second = await repo.getAlunoHome();
    expect(second, isNull); // 304
    expect(adapter.statusCodes, [200, 304]);
    expect(adapter.ifNoneMatch[1], '"home-v1"');
  });

  test('GET home personal: pulse.coachPendentes + 304', () async {
    final adapter = _EtagHomeAdapter(
      path: '/api/dashboard/home',
      body: _minimalPersonalHomeJson(),
    );
    final client = ApiClient()..dio.httpClientAdapter = adapter;
    final repo = DashboardRepository(client);

    final first = await repo.getHome();
    expect(first, isNotNull);
    expect(first!.pulse?.coachPendentes, 3);
    expect(first.pulse?.mensagensNaoLidas, 1);

    final second = await repo.getHome();
    expect(second, isNull);
    expect(adapter.statusCodes.last, 304);
  });
}
