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

  test('canal com regência certa por gênero da loja', () {
    String android(ChannelPreposition p) => subscriptionChannelWith(
      p,
      platform: TargetPlatform.android,
      isWeb: false,
    );
    String ios(ChannelPreposition p) =>
        subscriptionChannelWith(p, platform: TargetPlatform.iOS, isWeb: false);

    expect(android(ChannelPreposition.por), 'pelo Google Play');
    expect(android(ChannelPreposition.de), 'do Google Play');
    expect(android(ChannelPreposition.em), 'no Google Play');
    expect(android(ChannelPreposition.artigo), 'o Google Play');
    expect(ios(ChannelPreposition.por), 'pela App Store');
    expect(ios(ChannelPreposition.de), 'da App Store');
    expect(ios(ChannelPreposition.em), 'na App Store');
    expect(ios(ChannelPreposition.artigo), 'a App Store');
    expect(
      subscriptionChannelWith(ChannelPreposition.por, isWeb: true),
      'pelo checkout web',
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
