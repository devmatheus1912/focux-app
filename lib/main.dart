import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/api/api_client.dart';
import 'core/fcm/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FcmService.init(ApiClient());
  } catch (_) {
    // Firebase não configurado (sem google-services.json / GoogleService-Info.plist)
    // O app continua funcionando normalmente sem FCM
  }

  runApp(const ProviderScope(child: FocuxApp()));
}

class FocuxApp extends ConsumerWidget {
  const FocuxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Focux',
      theme: AppTheme.buildTheme(AppTheme.defaultPrimary),
      darkTheme: AppTheme.buildDarkTheme(AppTheme.defaultPrimary),
      themeMode: themeMode,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
