import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/api/api_client.dart';
import 'core/fcm/fcm_service.dart';

import 'features/perfil/data/perfil_repository.dart';

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
    } catch (e) {
      // Ignora erro se não logado
    }
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
