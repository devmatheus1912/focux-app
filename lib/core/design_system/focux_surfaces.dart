import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

part 'focux_surfaces_catalog.dart';

/// Taxonomia S1–S9 (§9) — mapa rota → tipo, espelhando `FocuxSecurity.coreSources`.
enum FocuxSurfaceType { s1, s2, s3, s4, s5, s6, s7, s8, s9 }

/// Contrato de uma rota no catálogo de superfícies.
class FocuxSurfaceSpec {
  const FocuxSurfaceSpec({
    required this.type,
    this.logicalParent,
    this.shellTab = false,
    this.hasInput = false,
    this.redirectTo,
  });

  final FocuxSurfaceType type;
  final String? logicalParent;
  final bool shellTab;
  final bool hasInput;
  final String? redirectTo;

  bool get showsBack =>
      !shellTab && logicalParent != null && logicalParent!.isNotEmpty;
}

/// Match de uma location concreta contra um padrão do catálogo.
class FocuxSurfaceMatch {
  const FocuxSurfaceMatch({
    required this.pattern,
    required this.spec,
    required this.location,
  });

  final String pattern;
  final FocuxSurfaceSpec spec;
  final String location;
}

/// Catálogo de superfícies — gate §32 / pilar 96.
abstract final class FocuxSurfaces {
  FocuxSurfaces._();

  static const String version = '1.0.0';

  static const List<String> coreSources = [
    'lib/core/design_system/focux_surfaces.dart',
    'lib/core/design_system/focux_surfaces_catalog.dart',
    'lib/core/widgets/fx_keyboard_dismiss_scope.dart',
    'lib/core/widgets/fx_form_chrome.dart',
    'lib/core/widgets/fx_execution_chrome.dart',
    'lib/core/widgets/fx_wizard_chrome.dart',
    'lib/core/widgets/fx_shell_scaffold.dart',
    'lib/core/router/safe_navigation.dart',
  ];

  static const List<String> automatedGates = [
    'test/core/design_system/surface_taxonomy_contract_test.dart',
    'test/core/design_system/focux_surfaces_test.dart',
    'test/core/widgets/fx_keyboard_dismiss_scope_test.dart',
    'test/core/widgets/fx_form_chrome_test.dart',
    'test/core/widgets/fx_execution_chrome_test.dart',
    'test/core/widgets/fx_wizard_chrome_test.dart',
  ];

  static Map<String, FocuxSurfaceSpec> get catalog => focuxSurfaceCatalog;

  static String normalize(String location) {
    final uri = Uri.tryParse(location);
    final path = uri?.path.isNotEmpty == true ? uri!.path : location;
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path.isEmpty ? '/' : path;
  }

  static FocuxSurfaceMatch? resolve(String location) {
    final path = normalize(location);
    final exact = focuxSurfaceCatalog[path];
    if (exact != null) {
      return FocuxSurfaceMatch(pattern: path, spec: exact, location: path);
    }

    FocuxSurfaceMatch? best;
    for (final entry in focuxSurfaceCatalog.entries) {
      if (!_matchesPattern(entry.key, path)) continue;
      if (best == null || entry.key.length > best.pattern.length) {
        best = FocuxSurfaceMatch(
          pattern: entry.key,
          spec: entry.value,
          location: path,
        );
      }
    }
    return best;
  }

  static FocuxSurfaceMatch? matchOf(BuildContext context) {
    try {
      return resolve(GoRouterState.of(context).uri.path);
    } catch (_) {
      return null;
    }
  }

  static String? logicalParentOf(BuildContext context) {
    final explicit = resolveParent(matchOf(context));
    return explicit;
  }

  static String? resolveParent(FocuxSurfaceMatch? match) {
    if (match == null) return null;
    final parent = match.spec.logicalParent;
    if (parent == null || parent.isEmpty) return null;
    return interpolateParent(match.pattern, match.location, parent);
  }

  static bool hasInputOf(BuildContext context) {
    return matchOf(context)?.spec.hasInput ?? false;
  }

  static String interpolateParent(
    String pattern,
    String location,
    String parentPattern,
  ) {
    final params = <String, String>{};
    final patternParts = pattern.split('/');
    final locationParts = location.split('/');
    if (patternParts.length == locationParts.length) {
      for (var i = 0; i < patternParts.length; i++) {
        final part = patternParts[i];
        if (part.startsWith(':') && part.length > 1) {
          params[part.substring(1)] = locationParts[i];
        }
      }
    }
    return parentPattern
        .split('/')
        .map((part) {
          if (part.startsWith(':') && part.length > 1) {
            return params[part.substring(1)] ?? part;
          }
          return part;
        })
        .join('/');
  }

  static bool _matchesPattern(String pattern, String path) {
    if (pattern == path) return true;
    final patternParts = pattern.split('/');
    final pathParts = path.split('/');
    if (patternParts.length != pathParts.length) return false;
    for (var i = 0; i < patternParts.length; i++) {
      final part = patternParts[i];
      if (part.startsWith(':')) continue;
      if (part != pathParts[i]) return false;
    }
    return true;
  }
}
