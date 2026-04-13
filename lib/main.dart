import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
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
