import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design_tokens.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final primaryColorProvider = StateProvider<Color>((ref) => EagleTokens.brand);

final logoUrlProvider = StateProvider<String?>((ref) => null);

final personalNameProvider = StateProvider<String?>((ref) => null);
