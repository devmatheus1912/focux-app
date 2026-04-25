import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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

  const TrialStatus({
    required this.trialUsed,
    required this.trialAtivo,
    this.trialStartedAt,
    this.trialEndsAt,
    required this.diasRestantes,
    required this.planoAtual,
    required this.subscriptionTokenPresent,
  });

  factory TrialStatus.fromJson(Map<String, dynamic> j) => TrialStatus(
        trialUsed: j['trialUsed'] as bool? ?? false,
        trialAtivo: j['trialAtivo'] as bool? ?? false,
        trialStartedAt: _parseDateTime(j['trialStartedAt']),
        trialEndsAt: _parseDateTime(j['trialEndsAt']),
        diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
        planoAtual: subscriptionPlanFromApi(j['planoAtual'] as String?),
        subscriptionTokenPresent:
            j['subscriptionTokenPresent'] as bool? ?? false,
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
  }) =>
      EnterpriseActivationPayload(
        subscriptionToken: subscriptionToken,
        platform: platform,
        productId: productId,
        transactionId: transactionId,
        billingCycleEndsAt: billingCycleEndsAt,
      );
}

class PlanosRepository {
  final Dio _dio;

  PlanosRepository(ApiClient client) : _dio = client.dio;

  Future<TrialStatus> getTrialStatus() async {
    final r = await _dio.get('/api/personal/trial/status');
    return TrialStatus.fromJson(r.data as Map<String, dynamic>);
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
