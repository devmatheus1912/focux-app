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
  ///
  /// Prefer the brand API host. Railway continua válido via `--dart-define=API_URL=...`.
  /// Pins TLS de **ambos** os hosts entram em [apiCertPins] para o release não
  /// quebrar se o binário e o secret divergirem de host.
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.focuxpersonal.com',
  );

  /// SHA-256 pins (`sha256/<base64>` ou só base64), separados por vírgula.
  /// Ex.: `--dart-define=API_CERT_PINS=sha256/abc...,sha256/def...`
  static const String _apiCertPinsRaw = String.fromEnvironment(
    'API_CERT_PINS',
    defaultValue: '',
  );

  /// Leaf pins atuais (2026-09-18) — Railway + api.focuxpersonal.com.
  /// Sempre unidos ao dart-define para o app falar com qualquer um dos hosts.
  static const List<String> _builtinApiCertPins = [
    // focux-backend-production.up.railway.app
    'sha256/56ZylJhguSmnkPgt0hUNGj/AjFqCOm0Px/OmO5WdBRE=',
    // api.focuxpersonal.com
    'sha256/BWjzG+rPlj+2cnDnbI+4LLj9z1hOazfNYvbzUZMkazA=',
  ];

  static List<String> get apiCertPins {
    final fromDefine =
        _apiCertPinsRaw.isEmpty
            ? const <String>[]
            : _apiCertPinsRaw
                .split(',')
                .map((p) => p.trim())
                .where((p) => p.isNotEmpty)
                .toList();
    if (fromDefine.isEmpty) return List<String>.from(_builtinApiCertPins);
    final merged = <String>{
      ...fromDefine.map((p) => p.trim()),
      ..._builtinApiCertPins,
    };
    return merged.where((p) => p.isNotEmpty).toList();
  }

  /// Em release store: falha sem pins. Preferir `true` nos scripts build-*.sh.
  static const bool requireApiCertPins = bool.fromEnvironment(
    'REQUIRE_API_CERT_PINS',
    defaultValue: true,
  );

  /// Public URL used for shareable landing links (`/p/{slug}`, `/c/{slug}`).
  ///
  /// Canonical brand host is [publicWebDisplayHost] (`focuxpersonal.com`).
  /// Vercel rewrites `/p` and `/c` to the Railway HTML fallback when needed.
  static const String publicWebUrl = String.fromEnvironment(
    'PUBLIC_WEB_URL',
    defaultValue: 'https://focuxpersonal.com',
  );

  /// WebSocket base URL. Derived from [apiUrl] but overridable via `WS_URL`.
  static const String _wsOverride = String.fromEnvironment(
    'WS_URL',
    defaultValue: '',
  );

  /// OAuth client id used by Google Sign-In (web client, used as serverClientId
  /// on Android/iOS). Public identifier, safe to ship hardcoded. Override via
  /// --dart-define=GOOGLE_WEB_CLIENT_ID=... when needed for staging.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '868715549357-kjut1ja3ab79j6pp3pquk2nha48atbcs.apps.googleusercontent.com',
  );

  /// Optional iOS OAuth **iOS-type** client id (Google Cloud → Credentials).
  /// Prefer leaving empty so native reads `GIDClientID` / GoogleService-Info.plist.
  /// Never put the Web client here as Dart `clientId` without a matching
  /// REVERSED_CLIENT_ID URL scheme — that aborts GIDSignIn (SIGABRT).
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// iOS client id for `GoogleSignIn(clientId:)` — null uses Info.plist / plist.
  static String? get googleIosClientIdOrNull {
    final id = googleIosClientId.trim();
    return id.isEmpty ? null : id;
  }

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
      apiUrl.contains('api.focux.app') ||
      apiUrl.contains('api.focuxpersonal.com');

  static String get _webBase {
    final base = publicWebUrl.endsWith('/')
        ? publicWebUrl.substring(0, publicWebUrl.length - 1)
        : publicWebUrl;
    return base;
  }

  /// Landing HTML pública — sempre host de marca (nunca Railway na URL compartilhada).
  static String landingPageUrl(String slug) =>
      'https://$publicWebDisplayHost/p/$slug';

  /// Link de acesso do aluno com slug.
  /// Usa `/p/{slug}` (App Link já registrado); no app redireciona para login.
  static String alunoLoginUrl(String slug) => landingPageUrl(slug.trim());

  /// Página de captura de leads (`/c/{slug}`).
  static String capturaPageUrl(String slug) =>
      'https://$publicWebDisplayHost/c/$slug';

  static const String _brandWebHost = 'focuxpersonal.com';

  /// Host amigável para exibir links públicos (marca quando infra é Railway etc.).
  static String get publicWebDisplayHost {
    final host = Uri.parse(_webBase).host.toLowerCase();
    if (host.contains('railway.app') ||
        host.contains('onrender.com') ||
        host.contains('vercel.app') ||
        host == 'localhost' ||
        host.startsWith('127.0.0.1') ||
        host == 'focux.app' ||
        host == 'www.focux.app') {
      return _brandWebHost;
    }
    return host;
  }

  /// URL legível na UI — copiar continua usando [landingPageUrl].
  static String landingPageDisplayLabel(String slug) =>
      '$publicWebDisplayHost/p/$slug';

  /// Label curto do formulário de captura na UI.
  static String capturaPageDisplayLabel(String slug) =>
      '$publicWebDisplayHost/c/$slug';
}
