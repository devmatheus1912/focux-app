import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/money/fx_money.dart';
import '../../../core/planos/plano_cache_policy.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/offline_sync_service.dart';
import '../../subscription/models/subscription_plan.dart';
import 'plano_recurso.dart';

export 'plano_recurso.dart';

class TrialStatus {
  final bool trialUsed;
  final bool trialAtivo;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final int diasRestantes;
  final SubscriptionPlan planoAtual;
  final bool subscriptionTokenPresent;
  final int trialDaysOffer;
  final bool trialEligible;

  const TrialStatus({
    required this.trialUsed,
    required this.trialAtivo,
    this.trialStartedAt,
    this.trialEndsAt,
    required this.diasRestantes,
    required this.planoAtual,
    required this.subscriptionTokenPresent,
    this.trialDaysOffer = 30,
    this.trialEligible = false,
  });

  factory TrialStatus.fromJson(Map<String, dynamic> j) => TrialStatus(
    trialUsed: j['trialUsed'] as bool? ?? false,
    trialAtivo: j['trialAtivo'] as bool? ?? false,
    trialStartedAt: _parseDateTime(j['trialStartedAt']),
    trialEndsAt: _parseDateTime(j['trialEndsAt']),
    diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
    planoAtual: subscriptionPlanFromApi(j['planoAtual'] as String?),
    subscriptionTokenPresent: j['subscriptionTokenPresent'] as bool? ?? false,
    trialDaysOffer: (j['trialDaysOffer'] as num?)?.toInt() ?? 30,
    trialEligible: j['trialEligible'] as bool? ?? false,
  );
}

class EnterpriseUpgradePreview {
  final SubscriptionPlan planoAtual;
  final SubscriptionPlan planoDestino;
  final double valorProporcional;
  final double diferencaDiaria;
  final int diasRestantes;
  final bool cobrancaImediata;

  const EnterpriseUpgradePreview({
    required this.planoAtual,
    required this.planoDestino,
    required this.valorProporcional,
    required this.diferencaDiaria,
    required this.diasRestantes,
    required this.cobrancaImediata,
  });

  factory EnterpriseUpgradePreview.fromJson(Map<String, dynamic> j) =>
      EnterpriseUpgradePreview(
        planoAtual: subscriptionPlanFromApi(j['planoAtual'] as String?),
        planoDestino: subscriptionPlanFromApi(j['planoDestino'] as String?),
        valorProporcional: FxMoney.reais(j['valorProporcional']),
        diferencaDiaria: FxMoney.reais(j['diferencaDiaria']),
        diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
        cobrancaImediata: j['cobrancaImediata'] as bool? ?? false,
      );
}

/// Microcopy para avisos de sync/cache no paywall e gates de plano.
abstract final class PlanoFeaturesSyncCopy {
  static const offlineCache =
      'Sem conexão no momento. Mostramos o último plano salvo — toque em Atualizar.';

  static const refreshFailed =
      'Não foi possível atualizar o plano agora. Mantivemos o último acesso — toque em Atualizar.';

  static const optimisticAluno =
      'Não foi possível confirmar o plano do seu personal. Mantivemos acesso seguro enquanto sincroniza.';

  static const optimisticEnterprise =
      'Não foi possível confirmar o plano agora. Acesso liberado em modo seguro enquanto sincroniza.';

  static String forRefreshError(Object error) {
    if (_isLikelyOffline(error)) return offlineCache;
    return refreshFailed;
  }

  static bool _isLikelyOffline(Object error) {
    if (error is SocketException) return true;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }
}

/// Snapshot autoritativo do plano atual conforme retornado pelo backend
/// em `/api/planos/me`. Use isto para gating do app — não inferir features
/// a partir do nome do plano em string.
class PlanoFeatures {
  final SubscriptionPlan plano;
  final String? planoNomeOriginal;
  final int? limiteAlunos;
  final int? limiteLeads;
  final int? limiteIaMensal;
  final DateTime? validoAte;
  final bool fromCache;
  final DateTime? cacheSavedAt;
  final String? syncWarning;
  final bool financeiro;
  final bool agenda;
  final bool relatorios;
  final bool whiteLabel;
  final bool iaCopiloto;
  final bool migracaoFoto;
  final bool landingCompleta;
  final bool habitCoaching;
  final bool comunidadePrivada;
  final bool automacoes;
  final bool automacoesAvancadas;
  final bool comunidadeGrupos;
  final bool equipeRbac;
  final bool lojaDigital;
  final bool feedbackVideo;
  final int alunosAtivos;
  final int iaUsadaMes;
  final int? limiteMigracaoFotoMensal;
  final int migracaoFotosUsadasMes;
  final String? displayName;

  /// `recursos` do backend. Vazio em backend antigo → matriz [PlanoRecursoKeys.matrix].
  final Map<String, PlanoRecurso> recursos;

  const PlanoFeatures({
    required this.plano,
    this.planoNomeOriginal,
    this.displayName,
    this.limiteAlunos,
    this.limiteLeads,
    this.limiteIaMensal,
    this.validoAte,
    this.fromCache = false,
    this.cacheSavedAt,
    this.syncWarning,
    required this.financeiro,
    required this.agenda,
    required this.relatorios,
    required this.whiteLabel,
    required this.iaCopiloto,
    required this.migracaoFoto,
    this.landingCompleta = false,
    this.habitCoaching = false,
    this.comunidadePrivada = false,
    this.automacoes = false,
    this.automacoesAvancadas = false,
    this.comunidadeGrupos = false,
    this.equipeRbac = false,
    this.lojaDigital = false,
    this.feedbackVideo = false,
    this.alunosAtivos = 0,
    this.iaUsadaMes = 0,
    this.limiteMigracaoFotoMensal,
    this.migracaoFotosUsadasMes = 0,
    this.recursos = const {},
  });

  /// Servidor vence; sem a chave, cai na matriz de produto pelo tier.
  PlanoRecurso recurso(String key) =>
      recursos[key] ?? PlanoRecursoKeys.fallbackFor(key, plano);

  bool get migracaoFotoPermitida =>
      migracaoFoto &&
      (limiteMigracaoFotoMensal ?? 0) > 0 &&
      migracaoFotosUsadasMes < (limiteMigracaoFotoMensal ?? 0);

  int get migracaoFotosRestantes {
    final limite = limiteMigracaoFotoMensal ?? 0;
    return (limite - migracaoFotosUsadasMes).clamp(0, limite);
  }

  int get iaRestantes {
    final limite = limiteIaMensal ?? 0;
    return (limite - iaUsadaMes).clamp(0, limite);
  }

  bool get iaQuotaEsgotada =>
      iaCopiloto &&
      (limiteIaMensal ?? 0) > 0 &&
      iaUsadaMes >= (limiteIaMensal ?? 0);

  bool get iaNearLimit {
    final limite = limiteIaMensal ?? 0;
    if (limite <= 0) return false;
    return iaUsadaMes >= (limite * 0.8).ceil();
  }

  factory PlanoFeatures.fromJson(Map<String, dynamic> j) {
    final featuresRaw = j['features'];
    final f =
        featuresRaw is Map
            ? featuresRaw.cast<String, dynamic>()
            : const <String, dynamic>{};
    final plano = subscriptionPlanFromApi(j['plano'] as String?);
    return PlanoFeatures(
      plano: plano,
      planoNomeOriginal: j['planoNomeOriginal'] as String?,
      displayName: j['displayName'] as String?,
      limiteAlunos: (j['limiteAlunos'] as num?)?.toInt(),
      limiteLeads: (j['limiteLeads'] as num?)?.toInt(),
      limiteIaMensal: (j['limiteIaMensal'] as num?)?.toInt(),
      validoAte: _parseDateTime(j['validoAte']),
      fromCache: j['fromCache'] as bool? ?? false,
      cacheSavedAt: _parseDateTime(j['cacheSavedAt']),
      syncWarning: j['syncWarning'] as String?,
      financeiro: f['financeiro'] as bool? ?? false,
      agenda: f['agenda'] as bool? ?? false,
      relatorios: f['relatorios'] as bool? ?? false,
      whiteLabel: f['whiteLabel'] as bool? ?? false,
      iaCopiloto: f['iaCopiloto'] as bool? ?? false,
      migracaoFoto: f['migracaoFoto'] as bool? ?? false,
      landingCompleta: f['landingCompleta'] as bool? ?? false,
      habitCoaching: f['habitCoaching'] as bool? ?? false,
      comunidadePrivada: f['comunidadePrivada'] as bool? ?? false,
      automacoes: f['automacoes'] as bool? ?? false,
      automacoesAvancadas: f['automacoesAvancadas'] as bool? ?? false,
      comunidadeGrupos: f['comunidadeGrupos'] as bool? ?? false,
      equipeRbac: f['equipeRbac'] as bool? ?? false,
      lojaDigital: f['lojaDigital'] as bool? ?? false,
      feedbackVideo: f['feedbackVideo'] as bool? ?? false,
      alunosAtivos: (j['alunosAtivos'] as num?)?.toInt() ?? 0,
      iaUsadaMes: (j['iaUsadaMes'] as num?)?.toInt() ?? 0,
      limiteMigracaoFotoMensal:
          (j['limiteMigracaoFotoMensal'] as num?)?.toInt(),
      migracaoFotosUsadasMes:
          (j['migracaoFotosUsadasMes'] as num?)?.toInt() ?? 0,
      recursos: _parseRecursos(j['recursos']),
    ).normalizeForTier();
  }

  static Map<String, PlanoRecurso> _parseRecursos(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, PlanoRecurso>{};
    raw.forEach((key, value) {
      final parsed = PlanoRecurso.tryParse(value);
      if (parsed != null) out[key.toString()] = parsed;
    });
    return Map.unmodifiable(out);
  }

  /// Flags legadas derivadas de [recurso]: `recursos` do servidor vence;
  /// sem eles, vale a matriz de produto do tier.
  PlanoFeatures normalizeForTier() => _applyCanonical(_canonicalCaps());

  /// Quando `/me` está atrás da assinatura (loja/perfil), eleva flags ao tier de cobrança.
  PlanoFeatures alignedToBilling(SubscriptionPlan billing) {
    if (billing.level <= plano.level) return this;
    final limiteAlunosEff = switch (billing) {
      SubscriptionPlan.ENTERPRISE => null,
      _ => limiteAlunos,
    };
    final limiteIaEff = switch (billing) {
      SubscriptionPlan.ENTERPRISE =>
        (limiteIaMensal == null || limiteIaMensal! <= 0)
            ? 600
            : limiteIaMensal!,
      SubscriptionPlan.PRO =>
        (limiteIaMensal == null || limiteIaMensal! <= 0)
            ? 200
            : limiteIaMensal!,
      _ => limiteIaMensal ?? 0,
    };
    return PlanoFeatures(
      plano: billing,
      planoNomeOriginal: planoNomeOriginal,
      displayName: displayName,
      limiteAlunos: limiteAlunosEff,
      limiteLeads: switch (billing) {
        SubscriptionPlan.FREE => limiteLeads,
        _ => null,
      },
      limiteIaMensal: limiteIaEff,
      validoAte: validoAte,
      fromCache: fromCache,
      cacheSavedAt: cacheSavedAt,
      syncWarning: syncWarning,
      financeiro: financeiro,
      agenda: agenda,
      relatorios: relatorios,
      whiteLabel: whiteLabel,
      iaCopiloto: iaCopiloto,
      migracaoFoto: migracaoFoto,
      landingCompleta: landingCompleta,
      habitCoaching: habitCoaching,
      comunidadePrivada: comunidadePrivada,
      automacoes: automacoes,
      automacoesAvancadas: automacoesAvancadas,
      comunidadeGrupos: comunidadeGrupos,
      equipeRbac: equipeRbac,
      lojaDigital: lojaDigital,
      feedbackVideo: feedbackVideo,
      alunosAtivos: alunosAtivos,
      iaUsadaMes: iaUsadaMes,
      limiteMigracaoFotoMensal: limiteMigracaoFotoMensal,
      migracaoFotosUsadasMes: migracaoFotosUsadasMes,
    ).normalizeForTier();
  }

  /// Capabilities legadas → chave de `recursos`.
  static const legacyCapabilityToRecurso = <String, String>{
    'agenda': PlanoRecursoKeys.agenda,
    'comunidadePrivada': PlanoRecursoKeys.comunidadePrivada,
    'financeiro': PlanoRecursoKeys.financeiro,
    'relatorios': PlanoRecursoKeys.relatorios,
    'whiteLabel': PlanoRecursoKeys.whiteLabel,
    'iaCopiloto': PlanoRecursoKeys.ia,
    'migracaoFoto': PlanoRecursoKeys.importacaoFoto,
    'landingCompleta': PlanoRecursoKeys.landing,
    'habitCoaching': PlanoRecursoKeys.habitos,
    'automacoes': PlanoRecursoKeys.automacoes,
    'automacoesAvancadas': PlanoRecursoKeys.automacoes,
    'comunidadeGrupos': PlanoRecursoKeys.desafios,
    'equipeRbac': PlanoRecursoKeys.equipe,
    'lojaDigital': PlanoRecursoKeys.loja,
    'feedbackVideo': PlanoRecursoKeys.feedbackVideo,
  };

  Map<String, bool> _canonicalCaps() => {
    for (final e in legacyCapabilityToRecurso.entries)
      e.key: recurso(e.value).liberado,
  };

  PlanoFeatures _applyCanonical(Map<String, bool> caps) {
    return PlanoFeatures(
      plano: plano,
      planoNomeOriginal: planoNomeOriginal,
      displayName: displayName,
      limiteAlunos: limiteAlunos,
      limiteLeads: limiteLeads,
      limiteIaMensal: limiteIaMensal,
      validoAte: validoAte,
      fromCache: fromCache,
      cacheSavedAt: cacheSavedAt,
      syncWarning: syncWarning,
      financeiro: caps['financeiro']!,
      agenda: caps['agenda']!,
      relatorios: caps['relatorios']!,
      whiteLabel: caps['whiteLabel']!,
      iaCopiloto: caps['iaCopiloto']!,
      migracaoFoto: caps['migracaoFoto']!,
      landingCompleta: caps['landingCompleta']!,
      habitCoaching: caps['habitCoaching']!,
      comunidadePrivada: caps['comunidadePrivada']!,
      automacoes: caps['automacoes']!,
      automacoesAvancadas: caps['automacoesAvancadas']!,
      comunidadeGrupos: caps['comunidadeGrupos']!,
      equipeRbac: caps['equipeRbac']!,
      lojaDigital: caps['lojaDigital']!,
      feedbackVideo: caps['feedbackVideo']!,
      alunosAtivos: alunosAtivos,
      iaUsadaMes: iaUsadaMes,
      limiteMigracaoFotoMensal: limiteMigracaoFotoMensal,
      migracaoFotosUsadasMes: migracaoFotosUsadasMes,
      recursos: recursos,
    );
  }

  Map<String, dynamic> toJson() => {
    'plano': plano.name,
    if (planoNomeOriginal != null) 'planoNomeOriginal': planoNomeOriginal,
    if (limiteAlunos != null) 'limiteAlunos': limiteAlunos,
    if (limiteLeads != null) 'limiteLeads': limiteLeads,
    if (limiteIaMensal != null) 'limiteIaMensal': limiteIaMensal,
    if (limiteMigracaoFotoMensal != null)
      'limiteMigracaoFotoMensal': limiteMigracaoFotoMensal,
    'migracaoFotosUsadasMes': migracaoFotosUsadasMes,
    if (validoAte != null) 'validoAte': validoAte!.toIso8601String(),
    'fromCache': fromCache,
    if (cacheSavedAt != null) 'cacheSavedAt': cacheSavedAt!.toIso8601String(),
    if (syncWarning != null) 'syncWarning': syncWarning,
    'features': {
      'financeiro': financeiro,
      'agenda': agenda,
      'relatorios': relatorios,
      'whiteLabel': whiteLabel,
      'iaCopiloto': iaCopiloto,
      'migracaoFoto': migracaoFoto,
      'landingCompleta': landingCompleta,
      'habitCoaching': habitCoaching,
      'comunidadePrivada': comunidadePrivada,
      'automacoes': automacoes,
      'automacoesAvancadas': automacoesAvancadas,
      'comunidadeGrupos': comunidadeGrupos,
      'equipeRbac': equipeRbac,
      'lojaDigital': lojaDigital,
      'feedbackVideo': feedbackVideo,
    },
    if (recursos.isNotEmpty)
      'recursos': {for (final e in recursos.entries) e.key: e.value.toJson()},
  };

  PlanoFeatures copyWithOperationalState({
    bool? fromCache,
    DateTime? cacheSavedAt,
    String? syncWarning,
  }) {
    return PlanoFeatures(
      plano: plano,
      planoNomeOriginal: planoNomeOriginal,
      limiteAlunos: limiteAlunos,
      limiteLeads: limiteLeads,
      limiteIaMensal: limiteIaMensal,
      validoAte: validoAte,
      fromCache: fromCache ?? this.fromCache,
      cacheSavedAt: cacheSavedAt ?? this.cacheSavedAt,
      syncWarning: syncWarning,
      financeiro: financeiro,
      agenda: agenda,
      relatorios: relatorios,
      whiteLabel: whiteLabel,
      iaCopiloto: iaCopiloto,
      migracaoFoto: migracaoFoto,
      landingCompleta: landingCompleta,
      habitCoaching: habitCoaching,
      comunidadePrivada: comunidadePrivada,
      automacoes: automacoes,
      automacoesAvancadas: automacoesAvancadas,
      comunidadeGrupos: comunidadeGrupos,
      equipeRbac: equipeRbac,
      lojaDigital: lojaDigital,
      feedbackVideo: feedbackVideo,
      alunosAtivos: alunosAtivos,
      iaUsadaMes: iaUsadaMes,
      limiteMigracaoFotoMensal: limiteMigracaoFotoMensal,
      migracaoFotosUsadasMes: migracaoFotosUsadasMes,
      recursos: recursos,
    );
  }

  static const free = PlanoFeatures(
    plano: SubscriptionPlan.FREE,
    limiteAlunos: 3,
    financeiro: false,
    agenda: true,
    relatorios: false,
    whiteLabel: false,
    iaCopiloto: false,
    migracaoFoto: false,
    limiteMigracaoFotoMensal: 0,
  );

  /// Fallback do aluno quando o plano do personal não confirma: Free.
  static const optimisticAluno = PlanoFeatures(
    plano: SubscriptionPlan.FREE,
    fromCache: true,
    syncWarning: PlanoFeaturesSyncCopy.optimisticAluno,
    financeiro: false,
    agenda: true,
    relatorios: false,
    whiteLabel: false,
    iaCopiloto: false,
    migracaoFoto: false,
    habitCoaching: false,
    comunidadePrivada: false,
    automacoes: false,
    automacoesAvancadas: false,
    comunidadeGrupos: false,
    equipeRbac: false,
    lojaDigital: false,
    feedbackVideo: false,
  );

  static const optimisticEnterprise = PlanoFeatures(
    plano: SubscriptionPlan.ENTERPRISE,
    fromCache: true,
    syncWarning: PlanoFeaturesSyncCopy.optimisticEnterprise,
    limiteAlunos: null,
    limiteIaMensal: 600,
    financeiro: true,
    agenda: true,
    relatorios: true,
    whiteLabel: true,
    iaCopiloto: true,
    migracaoFoto: true,
    landingCompleta: true,
    habitCoaching: true,
    comunidadePrivada: true,
    automacoes: true,
    automacoesAvancadas: true,
    comunidadeGrupos: true,
    equipeRbac: true,
    lojaDigital: true,
    feedbackVideo: true,
    limiteMigracaoFotoMensal: 80,
  );
}

class PlanosRepository {
  final Dio _dio;
  static const _cacheKey = 'focux_plano_features_cache_v2';

  PlanosRepository(ApiClient client) : _dio = client.dio;

  Future<TrialStatus> getTrialStatus() async {
    final r = await _dio.get('/api/personal/trial/status');
    return TrialStatus.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PlanoFeatures> getPlanoFeaturesFresh({bool forAluno = false}) async {
    final path = forAluno ? '/api/planos/contexto-aluno' : '/api/planos/me';
    final r = await _dio.get(path);
    final features = PlanoFeatures.fromJson(
      r.data as Map<String, dynamic>,
    ).copyWithOperationalState(fromCache: false, syncWarning: null);
    await _savePlanoFeaturesCache(features);
    return features;
  }

  /// Reconcilia plano no servidor (IAP/validade) e retorna `/me` atualizado.
  Future<PlanoFeatures> reconcilePlanoFeatures() async {
    await _dio.post('/api/planos/reconcile');
    return await getPlanoFeaturesFresh();
  }

  Future<PlanoFeatures?> loadCachedPlanoFeatures() async {
    return _loadPlanoFeaturesCache();
  }

  Future<void> clearPlanoFeaturesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await LocalCache.invalidate('/api/planos/me');
  }

  static bool isEntitlementsCacheFresh(DateTime? savedAt) {
    if (savedAt == null) return false;
    final age = DateTime.now().difference(savedAt);
    return age <= PlanoCachePolicy.entitlementsBootstrapMaxAge;
  }

  static bool canUseStaleEntitlementsOnError(DateTime? savedAt) {
    if (savedAt == null) return true;
    final age = DateTime.now().difference(savedAt);
    return age <= PlanoCachePolicy.entitlementsStaleOnErrorMaxAge;
  }

  Future<void> _savePlanoFeaturesCache(PlanoFeatures features) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'data': features.copyWithOperationalState(fromCache: false).toJson(),
      }),
    );
  }

  Future<PlanoFeatures?> _loadPlanoFeaturesCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final isWrapped = decoded.containsKey('data');
      final savedAt = isWrapped ? _parseDateTime(decoded['savedAt']) : null;
      if (savedAt != null) {
        final age = DateTime.now().difference(savedAt);
        if (age > PlanoCachePolicy.entitlementsHardExpire) {
          await prefs.remove(_cacheKey);
          return null;
        }
      }
      final data =
          isWrapped
              ? Map<String, dynamic>.from(decoded['data'] as Map)
              : decoded;
      return PlanoFeatures.fromJson(data).copyWithOperationalState(
        fromCache: true,
        cacheSavedAt: savedAt,
        syncWarning: 'Usando plano salvo enquanto a verificacao atualiza.',
      );
    } catch (_) {
      await prefs.remove(_cacheKey);
      return null;
    }
  }

  Future<EnterpriseUpgradePreview> previewEnterpriseUpgrade() async {
    final r = await _dio.get('/api/personal/trial/enterprise/preview');
    return EnterpriseUpgradePreview.fromJson(r.data as Map<String, dynamic>);
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
