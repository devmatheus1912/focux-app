/// Curated Rive assets (CC BY community + Rive CDN).
/// Sources documented in tool/download_rive_assets.dart
abstract final class FxRiveAssets {
  /// Avinash_Narayanan — Success confetti (widely used in production apps).
  static const confettiSuccess = 'assets/animations/confetti_success.riv';

  /// sergeyz — compact confetti burst for overlays.
  static const confettiBurst = 'assets/animations/confetti_burst.riv';

  /// Rive CDN — micro heart pulse for recovery / wearables.
  static const heartPulse = 'assets/animations/cdn_heart.riv';

  /// Community sparkle pack — badge unlock shimmer.
  static const starSparkle = 'assets/animations/star_sparkle.riv';

  /// Network fallbacks when bundling fails (same files on Rive CDN).
  static const confettiSuccessUrl =
      'https://public.rive.app/community/runtime-files/7184-13803-success-confetti-animation.riv';
  static const confettiBurstUrl =
      'https://public.rive.app/community/runtime-files/15318-28910-confetti-animation.riv';
}
