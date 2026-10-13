import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Atribuição de mídia paga: repassa poucos eventos-chave ao Firebase (GA4 /
/// Google Ads) e ao Meta. Nada de PII: só método de cadastro e plano.
///
/// Meta registra sozinho instalação, teste e assinatura (auto-log do SDK);
/// mandar `StartTrial`/`Subscribe` daqui duplicaria a conversão.
class AdAttribution {
  AdAttribution._();

  static bool _trackingAsked = false;

  static bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  static FirebaseAnalytics? get _firebase =>
      _isMobile && Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null;

  static final FacebookAppEvents _meta = FacebookAppEvents();

  static Future<void> forward(String event, Map<String, Object?>? props) async {
    if (!_isMobile) return;
    try {
      switch (event) {
        case ProductEvents.signupSuccess:
          final method = '${props?['method'] ?? 'email'}';
          if (props?['role'] != 'personal' || method.contains('mfa_pending')) {
            return;
          }
          await _firebase?.logSignUp(signUpMethod: method);
          await _meta.logCompletedRegistration(registrationMethod: method);
        case ProductEvents.trialStarted:
          await _firebase?.logEvent(name: 'start_trial', parameters: _plan(props));
        case ProductEvents.checkoutCompleted:
          await _firebase?.logEvent(
            name: 'checkout_completed',
            parameters: _plan(props),
          );
        case ProductEvents.alunoCreated:
        case ProductEvents.treinoCreated:
          await _firebase?.logEvent(name: event);
          await _meta.logEvent(name: event);
        case ProductEvents.referralLinkShared:
          await _firebase?.logShare(
            contentType: 'referral',
            itemId: 'referral_link',
            method: 'link',
          );
          await _meta.logEvent(name: 'referral_link_shared');
        case ProductEvents.homeViewed:
          unawaited(_requestTrackingOnce());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AdAttribution] $event failed: $e');
    }
  }

  static Map<String, Object>? _plan(Map<String, Object?>? props) {
    final plan = props?['plan_id'] ?? props?['plan'];
    return plan == null ? null : {'plan': '$plan'};
  }

  /// ATT só para o personal (painel dele), uma vez. O sistema não repete o
  /// prompt depois da primeira resposta.
  static Future<void> _requestTrackingOnce() async {
    if (_trackingAsked || defaultTargetPlatform != TargetPlatform.iOS) return;
    _trackingAsked = true;
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status != TrackingStatus.notDetermined) return;
    // O prompt é ignorado se aparecer antes da tela estar ativa.
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
}
