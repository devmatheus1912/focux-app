import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import 'core/api/api_client.dart';
import 'core/api/tls_certificate_pinning.dart';
import 'core/auth/session_cache_evictor.dart';
import 'core/crash/flutter_error_reporting.dart';
import 'core/fcm/fcm_service.dart';
import 'core/fcm/plan_sync_coordinator.dart';
import 'features/subscription/providers/iap_store_health_provider.dart';
import 'core/health/home_widget_service.dart';
import 'core/widgets/fx_connectivity_banner.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'core/theme/focux_system_chrome.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/perfil/data/perfil_repository.dart';
import 'l10n/app_localizations.dart';

void main() {
  // ── runZonedGuarded: captura TODOS os erros async nao tratados ──
  // IMPORTANT: Both ensureInitialized() and runApp() MUST be in the same zone.
  // Otherwise Flutter Web throws "Zone mismatch" which cascades into
  // layout/hit-test failures across the entire widget tree.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      TlsCertificatePinning.installGlobalOverrides();
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
            FirebaseCrashlytics.instance.recordError(
              error,
              stack,
              fatal: !isNonFatalFlutterFrameworkError(error),
            );
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

      runApp(const ProviderScope(child: FocuxApp()));
    },
    reportUncaughtZoneError,
  );
}

class FocuxApp extends ConsumerStatefulWidget {
  const FocuxApp({super.key});

  @override
  ConsumerState<FocuxApp> createState() => _FocuxAppState();
}

class _FocuxAppState extends ConsumerState<FocuxApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PlanSyncCoordinator.bind(ProviderScope.containerOf(context));
      _loadCustomTheme();
      if (!kIsWeb) {
        ref.read(iapStoreHealthProvider);
      }
    });
  }

  @override
  void dispose() {
    PlanSyncCoordinator.unbind();
    super.dispose();
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
      final dio = ApiClient().dio;
      final r = await dio.get(
        '/api/personal/perfil',
        options: Options(extra: {'fxNoRetry': true, 'fxNoInvalidate': true}),
      );
      final perfil = PerfilPersonal.fromJson(r.data as Map<String, dynamic>);
      if (!mounted) return;
      ref.read(primaryColorProvider.notifier).state = _safePrimaryColor(
        perfil.corPrimaria,
      );
      if (perfil.logoUrl != null && perfil.logoUrl!.isNotEmpty) {
        ref.read(logoUrlProvider.notifier).state = perfil.logoUrl;
      }
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
      final dio = ApiClient().dio;
      // Mark as no-retry and no-invalidation to avoid clearing the aluno session
      // when this best-effort theme fetch returns 401/403 (expected for aluno role)
      final response = await dio.get(
        '/api/aluno/personal-brand',
        options: Options(extra: {'fxNoRetry': true, 'fxNoInvalidate': true}),
      );
      final data = response.data as Map<String, dynamic>;
      if (!mounted) return;
      final corPrimaria = data['corPrimaria'] as String?;
      ref.read(primaryColorProvider.notifier).state = _safePrimaryColor(
        corPrimaria,
      );
      final logoUrl = data['logoUrl'] as String?;
      if (logoUrl != null && logoUrl.isNotEmpty) {
        ref.read(logoUrlProvider.notifier).state = logoUrl;
      }
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
    ref.read(logoUrlProvider.notifier).state = null;
    ref.read(personalNameProvider.notifier).state = null;
    ref.read(hideFocuxBrandingProvider.notifier).state = false;
    ref.read(appDisplayNameProvider.notifier).state = null;
  }

  Color _safePrimaryColor(String? raw) {
    if (raw == null || raw.length != 7 || !raw.startsWith('#')) {
      return EagleTokens.brand;
    }
    final parsed = int.tryParse(raw.replaceFirst('#', '0xFF'));
    if (parsed == null) return EagleTokens.brand;
    final color = Color(parsed);
    final hsl = HSLColor.fromColor(color);
    if (hsl.lightness > 0.86 || hsl.saturation < 0.12) {
      return EagleTokens.brand;
    }
    return color;
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
      theme: AppTheme.buildTheme(primaryColor),
      darkTheme: AppTheme.buildDarkTheme(primaryColor),
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
