import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../subscription/models/subscription_plan.dart';

class TrialStartPayload {
  final String? subscriptionToken;
  final String? platform;
  final String? productId;
  final String? transactionId;

  const TrialStartPayload({
    this.subscriptionToken,
    this.platform,
    this.productId,
    this.transactionId,
  });

  Map<String, dynamic> toJson() => {
    if (_hasValue(subscriptionToken)) 'subscriptionToken': subscriptionToken,
    if (_hasValue(platform)) 'platform': platform,
    if (_hasValue(productId)) 'productId': productId,
    if (_hasValue(transactionId)) 'transactionId': transactionId,
  };
}

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
    this.trialDaysOffer = 14,
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
    trialDaysOffer: (j['trialDaysOffer'] as num?)?.toInt() ?? 14,
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
        valorProporcional: (j['valorProporcional'] as num?)?.toDouble() ?? 0,
        diferencaDiaria: (j['diferencaDiaria'] as num?)?.toDouble() ?? 0,
        diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
        cobrancaImediata: j['cobrancaImediata'] as bool? ?? false,
      );
}

class EnterpriseActivationPayload {
  final String subscriptionToken;
  final String platform;
  final String productId;
  final String? transactionId;
  final DateTime billingCycleEndsAt;

  const EnterpriseActivationPayload({
    required this.subscriptionToken,
    required this.platform,
    required this.productId,
    this.transactionId,
    required this.billingCycleEndsAt,
  });

  Map<String, dynamic> toJson() => {
    'subscriptionToken': subscriptionToken,
    'platform': platform,
    'productId': productId,
    if (_hasValue(transactionId)) 'transactionId': transactionId,
    'billingCycleEndsAt': billingCycleEndsAt.toIso8601String(),
  };
}

class EnterpriseActivationResult {
  final SubscriptionPlan planoAnterior;
  final SubscriptionPlan planoAtual;
  final double valorProporcionalCobrado;
  final int diasRestantesCobrados;
  final DateTime? planoValidoAte;
  final bool trialAtivo;

  const EnterpriseActivationResult({
    required this.planoAnterior,
    required this.planoAtual,
    required this.valorProporcionalCobrado,
    required this.diasRestantesCobrados,
    this.planoValidoAte,
    required this.trialAtivo,
  });

  factory EnterpriseActivationResult.fromJson(Map<String, dynamic> j) =>
      EnterpriseActivationResult(
        planoAnterior: subscriptionPlanFromApi(j['planoAnterior'] as String?),
        planoAtual: subscriptionPlanFromApi(j['planoAtual'] as String?),
        valorProporcionalCobrado:
            (j['valorProporcionalCobrado'] as num?)?.toDouble() ?? 0,
        diasRestantesCobrados:
            (j['diasRestantesCobrados'] as num?)?.toInt() ?? 0,
        planoValidoAte: _parseDateTime(j['planoValidoAte']),
        trialAtivo: j['trialAtivo'] as bool? ?? false,
      );
}

class SubscriptionMetadata {
  final String platform;
  final String productId;
  final String subscriptionToken;
  final String transactionId;

  const SubscriptionMetadata({
    required this.platform,
    required this.productId,
    required this.subscriptionToken,
    required this.transactionId,
  });

  TrialStartPayload toTrialPayload() => TrialStartPayload(
    subscriptionToken: subscriptionToken,
    platform: platform,
    productId: productId,
    transactionId: transactionId,
  );

  EnterpriseActivationPayload toEnterpriseActivationPayload({
    required DateTime billingCycleEndsAt,
  }) => EnterpriseActivationPayload(
    subscriptionToken: subscriptionToken,
    platform: platform,
    productId: productId,
    transactionId: transactionId,
    billingCycleEndsAt: billingCycleEndsAt,
  );
}

/// Snapshot autoritativo do plano atual conforme retornado pelo backend
/// em `/api/planos/me`. Use isto para gating do app — não inferir features
/// a partir do nome do plano em string.
class PlanoFeatures {
  final SubscriptionPlan plano;
  final String? planoNomeOriginal;
  final int? limiteAlunos;
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
  final int alunosAtivos;
  final int iaUsadaMes;
  final int? limiteMigracaoFotoMensal;
  final int migracaoFotosUsadasMes;
  final String? displayName;

  const PlanoFeatures({
    required this.plano,
    this.planoNomeOriginal,
    this.displayName,
    this.limiteAlunos,
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
    this.alunosAtivos = 0,
    this.iaUsadaMes = 0,
    this.limiteMigracaoFotoMensal,
    this.migracaoFotosUsadasMes = 0,
  });

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
    final f = (j['features'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PlanoFeatures(
      plano: subscriptionPlanFromApi(j['plano'] as String?),
      planoNomeOriginal: j['planoNomeOriginal'] as String?,
      displayName: j['displayName'] as String?,
      limiteAlunos: (j['limiteAlunos'] as num?)?.toInt(),
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
      alunosAtivos: (j['alunosAtivos'] as num?)?.toInt() ?? 0,
      iaUsadaMes: (j['iaUsadaMes'] as num?)?.toInt() ?? 0,
      limiteMigracaoFotoMensal: (j['limiteMigracaoFotoMensal'] as num?)?.toInt(),
      migracaoFotosUsadasMes: (j['migracaoFotosUsadasMes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'plano': plano.name,
    if (planoNomeOriginal != null) 'planoNomeOriginal': planoNomeOriginal,
    if (limiteAlunos != null) 'limiteAlunos': limiteAlunos,
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
    },
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
      alunosAtivos: alunosAtivos,
      iaUsadaMes: iaUsadaMes,
      limiteMigracaoFotoMensal: limiteMigracaoFotoMensal,
      migracaoFotosUsadasMes: migracaoFotosUsadasMes,
    );
  }

  static const free = PlanoFeatures(
    plano: SubscriptionPlan.FREE,
    limiteAlunos: 5,
    financeiro: false,
    agenda: true,
    relatorios: false,
    whiteLabel: false,
    iaCopiloto: false,
    migracaoFoto: false,
    limiteMigracaoFotoMensal: 0,
  );

  static const optimisticEnterprise = PlanoFeatures(
    plano: SubscriptionPlan.ENTERPRISE,
    fromCache: true,
    syncWarning:
        'Nao foi possivel confirmar o plano agora. Acesso liberado em modo seguro enquanto sincroniza.',
    limiteAlunos: null,
    limiteIaMensal: 400,
    financeiro: true,
    agenda: true,
    relatorios: true,
    whiteLabel: true,
    iaCopiloto: true,
    migracaoFoto: true,
    limiteMigracaoFotoMensal: 50,
  );
}

class PlanosRepository {
  final Dio _dio;
  static const _cacheKey = 'focux_plano_features_cache_v1';

  PlanosRepository(ApiClient client) : _dio = client.dio;

  Future<TrialStatus> getTrialStatus() async {
    final r = await _dio.get('/api/personal/trial/status');
    return TrialStatus.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PlanoFeatures> getPlanoFeatures() async {
    try {
      return getPlanoFeaturesFresh();
    } catch (_) {
      final cached = await loadCachedPlanoFeatures();
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<PlanoFeatures> getPlanoFeaturesFresh() async {
    final r = await _dio.get('/api/planos/me');
    final features = PlanoFeatures.fromJson(
      r.data as Map<String, dynamic>,
    ).copyWithOperationalState(fromCache: false, syncWarning: null);
    await _savePlanoFeaturesCache(features);
    return features;
  }

  Future<PlanoFeatures?> loadCachedPlanoFeatures() async {
    return _loadPlanoFeaturesCache();
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

  Future<TrialStatus> startTrial({TrialStartPayload? payload}) async {
    final hasPayload = payload != null && payload.toJson().isNotEmpty;
    final r = await _dio.post(
      '/api/personal/trial/start',
      data: hasPayload ? payload.toJson() : null,
    );
    return TrialStatus.fromJson(r.data as Map<String, dynamic>);
  }

  Future<EnterpriseUpgradePreview> previewEnterpriseUpgrade() async {
    final r = await _dio.get('/api/personal/trial/enterprise/preview');
    return EnterpriseUpgradePreview.fromJson(r.data as Map<String, dynamic>);
  }

  Future<EnterpriseActivationResult> activateEnterprise(
    EnterpriseActivationPayload payload,
  ) async {
    final r = await _dio.post(
      '/api/personal/trial/enterprise/activate',
      data: payload.toJson(),
    );
    return EnterpriseActivationResult.fromJson(r.data as Map<String, dynamic>);
  }

  /// Restore purchases — re-syncs subscription state from backend.
  Future<PlanoFeatures> syncSubscription() async {
    return getPlanoFeaturesFresh();
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

String inferPlatformName() {
  if (kIsWeb) return 'WEB';
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'IOS';
    case TargetPlatform.android:
      return 'ANDROID';
    case TargetPlatform.macOS:
      return 'MACOS';
    case TargetPlatform.windows:
      return 'WINDOWS';
    case TargetPlatform.linux:
      return 'LINUX';
    case TargetPlatform.fuchsia:
      return 'FUCHSIA';
  }
}

SubscriptionMetadata buildLocalSubscriptionMetadata({
  required String productId,
  String prefix = 'trial',
}) {
  final now = DateTime.now();
  return SubscriptionMetadata(
    platform: inferPlatformName(),
    productId: productId,
    subscriptionToken: '$prefix-${now.millisecondsSinceEpoch}',
    transactionId: '$prefix-${now.microsecondsSinceEpoch}',
  );
}
