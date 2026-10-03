import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Assinaturas digitais no app móvel devem passar pela loja (guideline 3.1.1).
bool get subscriptionUsesNativeStore =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Onde a assinatura é cobrada neste aparelho.
String subscriptionChannelLabel({
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return 'checkout web';
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.iOS => 'App Store',
    TargetPlatform.android => 'Google Play',
    _ => 'checkout web',
  };
}

enum ChannelPreposition { artigo, de, em, por }

/// Canal com artigo/contração: "a App Store", "pelo Google Play", "no checkout web".
String subscriptionChannelWith(
  ChannelPreposition prep, {
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  final label = subscriptionChannelLabel(platform: platform, isWeb: isWeb);
  final feminino = label == 'App Store';
  final prefixo = switch (prep) {
    ChannelPreposition.artigo => feminino ? 'a' : 'o',
    ChannelPreposition.de => feminino ? 'da' : 'do',
    ChannelPreposition.em => feminino ? 'na' : 'no',
    ChannelPreposition.por => feminino ? 'pela' : 'pelo',
  };
  return '$prefixo $label';
}

/// Onde o usuário cancela: "em Ajustes > Assinaturas", "no Google Play…".
String subscriptionCancelWhere({
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb) return 'na área de cobrança';
  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.iOS => 'em Ajustes > Assinaturas',
    TargetPlatform.android => 'no Google Play, em Pagamentos e assinaturas',
    _ => 'na área de cobrança',
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
