import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:dio/dio.dart';
import 'core/api/api_client.dart';
import 'core/api/tls_certificate_pinning.dart';
import 'core/auth/session_cache_evictor.dart';
import 'core/config/env.dart';
import 'core/crash/flutter_error_reporting.dart';
import 'core/fcm/fcm_service.dart';
import 'core/fcm/plan_sync_coordinator.dart';
import 'features/subscription/providers/iap_store_health_provider.dart';
import 'core/health/home_widget_service.dart';
import 'core/widgets/fx_connectivity_banner.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand_palette.dart';
import 'core/theme/curated_brand_palettes.dart';
import 'core/theme/design_tokens.dart';
import 'core/theme/focux_system_chrome.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/utils/legacy_password_reset_redirect.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/dashboard/utils/dashboard_home_client_cache.dart';
import 'features/perfil/data/perfil_repository.dart';
import 'features/perfil/providers/perfil_provider.dart';
import 'l10n/app_localizations.dart';

void main() {
  // ── runZonedGuarded: captura TODOS os erros async nao tratados ──
  // IMPORTANT: Both ensureInitialized() and runApp() MUST be in the same zone.
  // Otherwise Flutter Web throws "Zone mismatch" which cascades into
  // layout/hit-test failures across the entire widget tree.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    LicenseRegistry.addLicense(() async* {
      final license =
          await rootBundle.loadString('assets/google_fonts/OFL.txt');
      yield LicenseEntryWithLineBreaks(<String>['google_fonts'], license);
    });
    GoogleFonts.config.allowRuntimeFetching = kDebugMode;
    debugPrint(
      '[Focux] Env.apiUrl=${Env.apiUrl} '
      'certPins=${Env.apiCertPins.length}',
    );
    try {
      TlsCertificatePinning.installGlobalOverrides();
    } catch (error, stack) {
      // Pin ausente não pode prender a splash nativa — o app ainda sobe.
      debugPrint('[Focux] TLS pinning init error: $error');
      reportUncaughtZoneError(error, stack);
    }
    await HomeWidgetService.init();

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(FocuxSystemChrome.dark);

    // ignore: unused_local_variable
    bool crashlyticsReady = false;

    try {
      if (!kIsWeb) {
        await Firebase.initializeApp();
        await FcmService.init(ApiClient());
        crashlyticsReady = true;

        FlutterError.onError = (details) {
          unawaited(reportFlutterErrorToCrashlytics(details));
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          if (isNonFatalFlutterFrameworkError(error, stack)) {
            debugPrint('[Focux] framework noise (not sent): $error');
            return true;
          }
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
    } catch (error) {
      debugPrint('[Focux] Firebase init error: $error');
      // Firebase ainda não está configurado em todos os ambientes.
      // Fallback: captura erros localmente sem Crashlytics.
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('[Focux] FlutterError: ${details.exceptionAsString()}');
        debugPrint('${details.stack}');
      };
    }

    // ── Global Red-Screen killer ──────────────────────────────────
    // Replaces Flutter's red error screen with a friendly message in release/profile.
    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) return ErrorWidget(details.exception);
      return Material(
        color: const Color(0xFF080C10),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Algo deu errado nesta tela.\nVolte e tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };

    applyLegacyPasswordResetRedirect(AppRouter.router);
    runApp(const ProviderScope(child: FocuxApp()));
  }, reportUncaughtZoneError);
}

class FocuxApp extends ConsumerStatefulWidget {
  const FocuxApp({super.key});

  @override
  ConsumerState<FocuxApp> createState() => _FocuxAppState();
}

class _FocuxAppState extends ConsumerState<FocuxApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bindAnalyticsFunnelPoster(ref.read(apiClientProvider));
      PlanSyncCoordinator.bind(ProviderScope.containerOf(context));
      _loadCustomTheme();
      if (!kIsWeb) {
        ref.read(iapStoreHealthProvider);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PlanSyncCoordinator.unbind();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final pausedAt = _pausedAt;
    _pausedAt = null;
    final away = pausedAt == null
        ? Duration.zero
        : DateTime.now().difference(pausedAt);
    _onAppResumed(away);
  }

  void _onAppResumed(Duration away) {
    if (!mounted) return;
    final client = ref.read(apiClientProvider);
    client.resetAfterAppResume(away);
    // Warm-up de JWT: away ≥ 1 min ou access perto do exp — antes do soft reload.
    unawaited(_warmSessionThenSoftReload(client, away));
  }

  Future<void> _warmSessionThenSoftReload(
    ApiClient client,
    Duration away,
  ) async {
    if (!mounted) return;
    if (ref.read(authProvider) != AuthStatus.authenticated) return;

    final force = away >= const Duration(minutes: 1);
    await client.warmSession(force: force);
    if (!mounted) return;
    if (ref.read(authProvider) != AuthStatus.authenticated) return;

    // Soft reload só após pausa ≥ 2 min — evita stampede em switches rápidos.
    if (away < const Duration(minutes: 2)) return;
    if (away > DashboardHomeClientCache.ttl) {
      DashboardHomeClientCache.clear();
    }
    ref.invalidate(dashboardHomeProvider);
    ref.invalidate(perfilProvider);
    unawaited(_loadCustomTheme());
  }

  Future<void> _loadCustomTheme() async {
    final token = (await SecureStorage.getToken())?.trim();
    if (token == null || token.isEmpty) return;

    final role = await SecureStorage.getRole();
    if (role == 'ALUNO') {
      await _loadAlunoTheme();
      return;
    }

    try {
      // Use direct dio.get with no-invalidation flags to avoid clearing
      // the aluno session when /api/personal/perfil returns 401 (expected)
      final dio = ref.read(apiClientProvider).dio;
      final r = await dio.get(
        '/api/personal/perfil',
        options: Options(extra: {'fxNoRetry': true, 'fxNoInvalidate': true}),
      );
      final perfil = PerfilPersonal.fromJson(r.data as Map<String, dynamic>);
      if (!mounted) return;
      final primary = _safePrimaryColor(perfil.corPrimaria);
      ref.read(primaryColorProvider.notifier).state = primary;
      ref.read(secondaryColorProvider.notifier).state = _safeSecondaryColor(
        primary,
        perfil.corSecundaria,
      );
      if (perfil.logoUrl != null && perfil.logoUrl!.isNotEmpty) {
        ref.read(logoUrlProvider.notifier).state = perfil.logoUrl;
      }
      final slogan = perfil.slogan?.trim();
      ref.read(sloganProvider.notifier).state =
          (slogan != null && slogan.isNotEmpty) ? slogan : null;
      ref.read(personalNameProvider.notifier).state = perfil.nome;
      return;
    } catch (error) {
      debugPrint('[Focux] personal theme load failed: $error');
    }

    if (role == 'PERSONAL') return;
    await _loadAlunoTheme();
  }

  Future<void> _loadAlunoTheme() async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      // Mark as no-retry and no-invalidation to avoid clearing the aluno session
      // when this best-effort theme fetch returns 401/403 (expected for aluno role)
      final response = await dio.get(
        '/api/aluno/personal-brand',
        options: Options(extra: {'fxNoRetry': true, 'fxNoInvalidate': true}),
      );
      final data = response.data as Map<String, dynamic>;
      if (!mounted) return;
      final corPrimaria = data['corPrimaria'] as String?;
      final primary = _safePrimaryColor(corPrimaria);
      ref.read(primaryColorProvider.notifier).state = primary;
      ref.read(secondaryColorProvider.notifier).state = _safeSecondaryColor(
        primary,
        data['corSecundaria'] as String?,
      );
      final logoUrl = data['logoUrl'] as String?;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        ref.read(logoUrlProvider.notifier).state = logoUrl;
      }
      final slogan = (data['slogan'] as String?)?.trim();
      ref.read(sloganProvider.notifier).state =
          (slogan != null && slogan.isNotEmpty) ? slogan : null;
      final nomePersonal = data['nomePersonal'] as String?;
      if (nomePersonal != null && nomePersonal.isNotEmpty) {
        ref.read(personalNameProvider.notifier).state = nomePersonal;
      }
      ref.read(hideFocuxBrandingProvider.notifier).state =
          data['hideFocuxBranding'] as bool? ?? false;
      ref.read(appDisplayNameProvider.notifier).state =
          data['appDisplayName'] as String?;
    } catch (error) {
      debugPrint('[Focux] aluno theme load failed: $error');
    }
  }

  void _resetCustomTheme() {
    ref.read(primaryColorProvider.notifier).state = EagleTokens.brand;
    ref.read(secondaryColorProvider.notifier).state =
        BrandPalette.defaultSecondary;
    ref.read(logoUrlProvider.notifier).state = null;
    ref.read(sloganProvider.notifier).state = null;
    ref.read(personalNameProvider.notifier).state = null;
    ref.read(hideFocuxBrandingProvider.notifier).state = false;
    ref.read(appDisplayNameProvider.notifier).state = null;
  }

  Color _safePrimaryColor(String? raw) {
    // Cyan legado no BE (#13C2C2) vira azul petróleo — senão só o login muda.
    return CuratedBrandPalette.safePrimary(
      BrandPalette.resolveStoredPrimary(raw),
    );
  }

  Color _safeSecondaryColor(Color primary, String? raw) {
    return CuratedBrandPalette.safeSecondaryFor(
      primary,
      BrandPalette.resolveStoredSecondary(raw),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthStatus>(authProvider, (previous, next) {
      if (next == AuthStatus.authenticated &&
          previous != AuthStatus.authenticated) {
        invalidateSessionUserCaches(ref);
        _loadCustomTheme();
      } else if (next == AuthStatus.unauthenticated &&
          previous == AuthStatus.authenticated) {
        invalidateSessionUserCaches(ref);
        _resetCustomTheme();
      }
    });

    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final secondaryColor = ref.watch(secondaryColorProvider);
    final hideFocux = ref.watch(hideFocuxBrandingProvider);
    final appDisplayName = ref.watch(appDisplayNameProvider);
    final personalName = ref.watch(personalNameProvider);
    final appTitle =
        hideFocux
            ? ((appDisplayName != null && appDisplayName.trim().isNotEmpty)
                ? appDisplayName.trim()
                : (personalName ?? 'Meu Personal'))
            : 'Focux';

    return MaterialApp.router(
      title: appTitle,
      theme: AppTheme.buildTheme(primaryColor, secondary: secondaryColor),
      darkTheme: AppTheme.buildDarkTheme(
        primaryColor,
        secondary: secondaryColor,
      ),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      // Acessibilidade: respeita escala do sistema, mas evita explosões
      // de layout em escalas absurdas (>1.6) — mantém WCAG AA sem
      // quebrar telas densas como dashboard/treinos.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final width = mq.size.width;
        final isPhone =
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS);
        final maxScale = isPhone && width <= 390 ? 1.05 : 1.25;
        final scaler = mq.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: maxScale,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: scaler),
          child: FxConnectivityBanner(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
