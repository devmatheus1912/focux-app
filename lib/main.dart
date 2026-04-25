import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/api_client.dart';
import 'core/fcm/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/perfil/data/perfil_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      await FcmService.init(ApiClient());

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (error) {
    debugPrint('[Focux] Error: $error');
    // Firebase ainda não está configurado em todos os ambientes.
  }

  runApp(const ProviderScope(child: FocuxApp()));
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
      _loadCustomTheme();
    });
  }

  Future<void> _loadCustomTheme() async {
    try {
      final repo = PerfilRepository(ApiClient());
      final perfil = await repo.buscar();
      if (perfil.corPrimaria != null && perfil.corPrimaria!.length == 7) {
        final hex = perfil.corPrimaria!.replaceFirst('#', '0xFF');
        ref.read(primaryColorProvider.notifier).state = Color(int.parse(hex));
      }
      if (perfil.logoUrl != null && perfil.logoUrl!.isNotEmpty) {
        ref.read(logoUrlProvider.notifier).state = perfil.logoUrl;
      }
      ref.read(personalNameProvider.notifier).state = perfil.nome;
      return;
    } catch (_) {}

    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/aluno/personal-brand');
      final data = response.data as Map<String, dynamic>;
      final plano = data['plano'] as String? ?? 'FREE';
      if (plano == 'ENTERPRISE') {
        final corPrimaria = data['corPrimaria'] as String?;
        if (corPrimaria != null && corPrimaria.length == 7) {
          final hex = corPrimaria.replaceFirst('#', '0xFF');
          ref.read(primaryColorProvider.notifier).state = Color(int.parse(hex));
        }
        final logoUrl = data['logoUrl'] as String?;
        if (logoUrl != null && logoUrl.isNotEmpty) {
          ref.read(logoUrlProvider.notifier).state = logoUrl;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final primaryColor = ref.watch(primaryColorProvider);

    return MaterialApp.router(
      title: 'Focux',
      theme: AppTheme.buildTheme(primaryColor),
      darkTheme: AppTheme.buildDarkTheme(primaryColor),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
