import 'package:flutter/material.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

/// Casca de teste do kit da ficha: tema claro/escuro, escala de texto e largura.
Widget kitHost(
  Widget child, {
  bool dark = false,
  double textScale = 1,
  double width = 390,
}) {
  GoogleFonts.config.allowRuntimeFetching = false;
  final brilho = dark ? Brightness.dark : Brightness.light;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: brilho,
      colorScheme: ColorScheme.fromSeed(
        seedColor: EagleTokens.brandAccent,
        brightness: brilho,
      ),
      useMaterial3: true,
    ),
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
}
