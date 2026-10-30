import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Integra com o app Saúde (iOS) e o Health Connect (Android).
///
/// Lê: passos, FC (média e em repouso), HRV, energia ativa e sono.
/// Data is cached locally and optionally sent to the backend.
class HealthService {
  HealthService._();

  static final Health _health = Health();
  static const _prefKey = 'health_authorized';

  /// Tipos já pedidos ao sistema. Mudou a lista (ex.: FC em repouso e HRV
  /// entraram depois), pede de novo uma vez: o iPhone só pergunta os novos.
  static const _tiposKey = 'health_tipos_pedidos';

  static String get _assinatura => assinaturaDosTipos(_types.map((t) => t.name));

  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.RESTING_HEART_RATE,
    // O mesmo conceito tem tipos diferentes por plataforma.
    if (defaultTargetPlatform == TargetPlatform.iOS)
      HealthDataType.HEART_RATE_VARIABILITY_SDNN
    else
      HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
  ];

  static final _permissions = _types.map((_) => HealthDataAccess.READ).toList();

  static Future<void>? _configured;

  static Future<void> _ensureConfigured() =>
      _configured ??= _health.configure().catchError((Object e) {
        _configured = null;
        throw e;
      });

  /// Request authorization to read health data.
  /// Returns true if access was granted.
  static Future<bool> requestAuthorization() async {
    try {
      await _ensureConfigured();
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _permissions,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, granted);
      await prefs.setString(_tiposKey, _assinatura);
      return granted;
    } catch (e) {
      if (kDebugMode) debugPrint('[HealthService] Auth error: $e');
      return false;
    }
  }

  /// Já conectado, mas a lista de tipos mudou desde o último pedido: pede de novo.
  static Future<void> pedirTiposNovosSeMudou() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_prefKey) ?? false)) return;
    if (!precisaPedirDeNovo(prefs.getString(_tiposKey), _assinatura)) return;
    await requestAuthorization();
  }

  /// Check if we already have authorization.
  static Future<bool> isAuthorized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Fetch steps for today.
  static Future<int> getTodaySteps() async {
    try {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      await _ensureConfigured();
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      return steps ?? 0;
    } catch (e) {
      if (kDebugMode) debugPrint('[HealthService] Steps error: $e');
      return 0;
    }
  }

  /// Fetch health data for a given period.
  static Future<List<HealthDataPoint>> getHealthData({
    required DateTime start,
    required DateTime end,
    List<HealthDataType>? types,
  }) async {
    try {
      await _ensureConfigured();
      final data = await _health.getHealthDataFromTypes(
        types: types ?? _types,
        startTime: start,
        endTime: end,
      );
      return _health.removeDuplicates(data);
    } catch (e) {
      if (kDebugMode) debugPrint('[HealthService] Fetch error: $e');
      return [];
    }
  }

  /// Início da janela do sono: ontem às 18h. A noite que termina hoje começa
  /// antes da meia-noite; ler só "desde 00:00" perdia a primeira parte.
  static DateTime inicioDaJanelaDeSono(DateTime agora) =>
      DateTime(agora.year, agora.month, agora.day).subtract(
        const Duration(hours: 6),
      );

  /// Resumo do dia: passos, FC média e em repouso, HRV, energia ativa e o sono
  /// da última noite.
  static Future<HealthSummary> getTodaySummary() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final dia = await getHealthData(start: midnight, end: now);
    final noite = await getHealthData(
      start: inicioDaJanelaDeSono(now),
      end: now,
      types: [HealthDataType.SLEEP_ASLEEP],
    );
    final steps = await getTodaySteps();

    double calories = 0;
    double avgHeartRate = 0;
    int hrCount = 0;
    double restingTotal = 0;
    int restingCount = 0;
    double hrvTotal = 0;
    int hrvCount = 0;
    final fontes = <String>{};

    for (final point in dia) {
      final raw = point.value;
      if (raw is! NumericHealthValue) continue;
      final value = raw.numericValue.toDouble();
      switch (point.type) {
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += value;
          fontes.add(point.sourceName);
          break;
        case HealthDataType.HEART_RATE:
          avgHeartRate += value;
          hrCount++;
          fontes.add(point.sourceName);
          break;
        case HealthDataType.RESTING_HEART_RATE:
          restingTotal += value;
          restingCount++;
          break;
        case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
        case HealthDataType.HEART_RATE_VARIABILITY_RMSSD:
          hrvTotal += value;
          hrvCount++;
          break;
        default:
          break;
      }
    }

    // Sono: soma só as sessões que terminam hoje (a noite passada).
    final sleepMinutes = minutosDeSonoDaNoite(noite, hoje: midnight);
    for (final p in noite) {
      fontes.add(p.sourceName);
    }

    return HealthSummary(
      steps: steps,
      caloriesBurned: calories,
      avgHeartRate: hrCount > 0 ? (avgHeartRate / hrCount) : 0,
      sleepHours: sleepMinutes / 60,
      restingHeartRate: restingCount > 0 ? (restingTotal / restingCount) : 0,
      hrv: hrvCount > 0 ? (hrvTotal / hrvCount) : 0,
      fonte: fontes.where((f) => f.trim().isNotEmpty).join(', '),
    );
  }

  /// Minutos dormidos na noite que termina em [hoje]: só os trechos que
  /// terminam a partir da meia-noite de hoje e sem contar o mesmo intervalo
  /// duas vezes (relógio e iPhone gravam o mesmo sono).
  @visibleForTesting
  static double minutosDeSonoDaNoite(
    List<HealthDataPoint> pontos, {
    required DateTime hoje,
  }) {
    final trechos = <(DateTime, DateTime)>[];
    for (final p in pontos) {
      if (p.type != HealthDataType.SLEEP_ASLEEP) continue;
      if (p.dateTo.isBefore(hoje)) continue;
      trechos.add((p.dateFrom, p.dateTo));
    }
    return minutosUnidos(trechos);
  }

  /// Soma dos minutos de uma lista de intervalos, unindo os que se sobrepõem.
  @visibleForTesting
  static double minutosUnidos(List<(DateTime, DateTime)> intervalos) {
    if (intervalos.isEmpty) return 0;
    final ordenados = [...intervalos]..sort((a, b) => a.$1.compareTo(b.$1));
    var total = 0.0;
    var inicio = ordenados.first.$1;
    var fim = ordenados.first.$2;
    for (final t in ordenados.skip(1)) {
      if (t.$1.isAfter(fim)) {
        total += fim.difference(inicio).inSeconds / 60;
        inicio = t.$1;
        fim = t.$2;
      } else if (t.$2.isAfter(fim)) {
        fim = t.$2;
      }
    }
    total += fim.difference(inicio).inSeconds / 60;
    return total;
  }

  /// Revoke access and clear stored preference.
  static Future<void> revokeAccess() async {
    try {
      await _ensureConfigured();
      await _health.revokePermissions();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    await prefs.remove(_tiposKey);
  }
}

/// Lista de tipos em ordem estável, para comparar entre versões do app.
String assinaturaDosTipos(Iterable<String> tipos) => (tipos.toList()..sort()).join(',');

/// Pede de novo quando nunca guardou a lista ou quando ela mudou.
bool precisaPedirDeNovo(String? guardada, String atual) => guardada != atual;

/// Resumo das leituras do dia (e da última noite).
class HealthSummary {
  final int steps;
  final double caloriesBurned;
  final double avgHeartRate;
  final double sleepHours;

  /// FC em repouso e HRV do dia; zero = o aparelho não mediu.
  final double restingHeartRate;
  final double hrv;

  /// De onde vieram os dados ("Apple Watch", "iPhone"...); só para a tela.
  final String fonte;

  const HealthSummary({
    required this.steps,
    required this.caloriesBurned,
    required this.avgHeartRate,
    required this.sleepHours,
    this.restingHeartRate = 0,
    this.hrv = 0,
    this.fonte = '',
  });
}
