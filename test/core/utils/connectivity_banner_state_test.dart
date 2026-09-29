import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/connectivity_banner_state.dart';

ConnectivityBannerKind _kind({
  bool offline = false,
  bool circuitOpen = false,
  int pending = 0,
  int dropped = 0,
}) => resolveConnectivityBanner(
  offline: offline,
  circuitOpen: circuitOpen,
  pending: pending,
  dropped: dropped,
);

void main() {
  test('tudo em dia: banner escondido', () {
    expect(_kind(), ConnectivityBannerKind.hidden);
  });

  test('offline com fila mostra a contagem pendente', () {
    expect(_kind(offline: true), ConnectivityBannerKind.offline);
    expect(
      _kind(offline: true, pending: 2),
      ConnectivityBannerKind.offlinePending,
    );
  });

  test('descarte pede ciência antes de instabilidade e sincronia', () {
    expect(
      _kind(dropped: 1, circuitOpen: true, pending: 3),
      ConnectivityBannerKind.dropped,
    );
    expect(
      _kind(circuitOpen: true, pending: 3),
      ConnectivityBannerKind.unstable,
    );
    expect(_kind(pending: 3), ConnectivityBannerKind.syncing);
  });
}
