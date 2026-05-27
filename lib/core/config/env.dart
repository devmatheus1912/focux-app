/// Centralized environment configuration for the Focux app.
///
/// All `String.fromEnvironment(...)` reads happen here so we have ONE place to
/// audit per-flavor wiring. Anything that needs a base URL must import [Env]
/// instead of declaring its own `_base = '...'`.
///
/// Override per build with:
///   flutter run --dart-define=API_URL=https://staging.focux.app
///
/// Or per flavor in `flutter_launcher_icons`/CI scripts.
class Env {
  Env._();

  /// HTTP base URL for the Focux backend (no trailing slash).
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://focux-backend-production.up.railway.app',
  );

  /// Public URL used for shareable landing links.
  ///
  /// Today the canonical `focux.app` domain points to another web project, so
  /// the default uses the Railway backend HTML fallback. Override with
  /// `--dart-define=PUBLIC_WEB_URL=https://focux.app` after DNS/Vercel is wired
  /// to the Focux Personal web surface.
  static const String publicWebUrl = String.fromEnvironment(
    'PUBLIC_WEB_URL',
    defaultValue: 'https://focux-backend-production.up.railway.app',
  );

  /// WebSocket base URL. Derived from [apiUrl] but overridable via `WS_URL`.
  static const String _wsOverride = String.fromEnvironment(
    'WS_URL',
    defaultValue: '',
  );

  /// OAuth client id used by Google Sign-In (web client, used as serverClientId
  /// on Android). Public identifier, safe to ship hardcoded. Override via
  /// --dart-define=GOOGLE_WEB_CLIENT_ID=... when needed for staging.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '868715549357-kjut1ja3ab79j6pp3pquk2nha48atbcs.apps.googleusercontent.com',
  );

  /// Returns the websocket URL. If `WS_URL` is set, uses it verbatim. Otherwise
  /// converts `https://` → `wss://` and `http://` → `ws://` from [apiUrl].
  static String get wsUrl {
    if (_wsOverride.isNotEmpty) return _wsOverride;
    return apiUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
  }

  /// Whether we are running against a non-prod backend (used to gate debug
  /// affordances like staging banners and dev-only buttons).
  static bool get isProd =>
      apiUrl.contains('focux-backend.onrender.com') ||
      apiUrl.contains('up.railway.app') ||
      apiUrl.contains('api.focux.app');

  static String get _webBase {
    final base = publicWebUrl.endsWith('/')
        ? publicWebUrl.substring(0, publicWebUrl.length - 1)
        : publicWebUrl;
    return base;
  }

  /// Landing HTML pública servida pelo backend (`/p/{slug}`).
  static String landingPageUrl(String slug) => '$_webBase/p/$slug';

  /// Página de captura de leads (`/c/{slug}`).
  static String capturaPageUrl(String slug) => '$_webBase/c/$slug';

  /// Label curto para UI (host + path).
  static String landingPageLabel(String slug) {
    final uri = Uri.parse(landingPageUrl(slug));
    return '${uri.host}/p/$slug';
  }
}
