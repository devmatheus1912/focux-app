import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
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

class FocuxApp extends StatelessWidget {
  const FocuxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Focux',
      theme: AppTheme.buildTheme(AppTheme.defaultPrimary),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
