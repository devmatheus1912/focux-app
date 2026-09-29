import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Assinaturas digitais no app móvel devem passar pela loja (guideline 3.1.1).
bool get subscriptionUsesNativeStore =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Onde a assinatura é cobrada neste aparelho.
String subscriptionChannelLabel({TargetPlatform? platform, bool isWeb = kIsWeb}) {
  if (isWeb) return 'checkout web';
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.iOS => 'App Store',
    TargetPlatform.android => 'Google Play',
    _ => 'checkout web',
  };
}

Future<bool> openNativeSubscriptionManagement() async {
  if (!subscriptionUsesNativeStore) return false;

  final uri =
      defaultTargetPlatform == TargetPlatform.iOS
          ? Uri.parse('https://apps.apple.com/account/subscriptions')
          : Uri.parse('https://play.google.com/store/account/subscriptions');

  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
