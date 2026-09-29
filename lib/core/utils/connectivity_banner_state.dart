/// O que o banner global de conexão mostra, em ordem de prioridade.
enum ConnectivityBannerKind {
  hidden,
  offline,
  offlinePending,
  dropped,
  unstable,
  syncing,
}

ConnectivityBannerKind resolveConnectivityBanner({
  required bool offline,
  required bool circuitOpen,
  required int pending,
  required int dropped,
}) {
  if (offline) {
    return pending > 0
        ? ConnectivityBannerKind.offlinePending
        : ConnectivityBannerKind.offline;
  }
  if (dropped > 0) return ConnectivityBannerKind.dropped;
  if (circuitOpen) return ConnectivityBannerKind.unstable;
  if (pending > 0) return ConnectivityBannerKind.syncing;
  return ConnectivityBannerKind.hidden;
}
