import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final primaryColorProvider = StateProvider<Color>((ref) => const Color(0xFF0288D1));
