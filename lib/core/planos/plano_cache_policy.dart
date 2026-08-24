/// Políticas de cache para entitlements e vitrine de planos (v5.1).
class PlanoCachePolicy {
  PlanoCachePolicy._();

  /// Snapshot local usado no cold-start (stale-while-revalidate).
  static const entitlementsBootstrapMaxAge = Duration(minutes: 30);

  /// Após este limite o snapshot não entra no bootstrap (força rede).
  static const entitlementsHardExpire = Duration(hours: 4);

  /// Em erro de refresh, só reutiliza snapshot se ainda estiver dentro desta janela.
  static const entitlementsStaleOnErrorMaxAge = Duration(hours: 4);

  /// GET `/api/planos/me` no [LocalCache] do Dio.
  static const planosMeHttpCacheTtl = Duration(minutes: 30);
}
