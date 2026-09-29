import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/store_subscription_policy.dart';

void main() {
  test('canal de cobrança segue a loja da plataforma', () {
    expect(
      subscriptionChannelLabel(platform: TargetPlatform.iOS, isWeb: false),
      'App Store',
    );
    expect(
      subscriptionChannelLabel(platform: TargetPlatform.android, isWeb: false),
      'Google Play',
    );
    expect(
      subscriptionChannelLabel(platform: TargetPlatform.windows, isWeb: false),
      'checkout web',
    );
    expect(
      subscriptionChannelLabel(platform: TargetPlatform.iOS, isWeb: true),
      'checkout web',
    );
  });

  test('sem parâmetro usa a plataforma atual', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      expect(subscriptionChannelLabel(), 'App Store');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
