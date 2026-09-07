/// Envelope BFF `GET /api/personal/ferramentas/catalogo`.
class FerramentasCatalogo {
  const FerramentasCatalogo({
    required this.version,
    required this.hubs,
    this.plano,
    this.atalhosHome = const [],
  });

  final int version;
  final String? plano;
  final List<CatalogoEntrada> atalhosHome;
  final List<CatalogoHub> hubs;

  factory FerramentasCatalogo.fromJson(Map<String, dynamic> json) {
    final hubsRaw = json['hubs'];
    final atalhosRaw = json['atalhosHome'];
    return FerramentasCatalogo(
      version: (json['version'] as num?)?.toInt() ?? 0,
      plano: json['plano'] as String?,
      atalhosHome:
          atalhosRaw is List
              ? atalhosRaw
                  .whereType<Map>()
                  .map(
                    (e) => CatalogoEntrada.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList(growable: false)
              : const [],
      hubs:
          hubsRaw is List
              ? hubsRaw
                  .whereType<Map>()
                  .map((e) => CatalogoHub.fromJson(Map<String, dynamic>.from(e)))
                  .toList(growable: false)
              : const [],
    );
  }

  /// Todas as entradas navegáveis (itens + abas + atalhos), para busca/legacy.
  Iterable<CatalogoEntrada> get todasEntradas sync* {
    for (final atalho in atalhosHome) {
      yield atalho;
      yield* atalho.abas;
    }
    for (final hub in hubs) {
      for (final item in hub.itens) {
        yield item;
        yield* item.abas;
      }
    }
  }

  CatalogoEntrada? findByLegacyId(String legacyId) {
    final needle = legacyId.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final e in todasEntradas) {
      if (e.id.toLowerCase() == needle) return e;
      if (e.legacyIds.any((id) => id.toLowerCase() == needle)) return e;
    }
    return null;
  }

  /// Item-pai (com abas) que contém o legacy/id, ou a própria folha.
  CatalogoEntrada? resolveNavTarget(String legacyOrId) {
    final needle = legacyOrId.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final hub in hubs) {
      for (final item in hub.itens) {
        if (_matches(item, needle)) return item;
        for (final aba in item.abas) {
          if (_matches(aba, needle)) {
            return item.abas.isNotEmpty ? item : aba;
          }
        }
      }
    }
    return findByLegacyId(legacyOrId);
  }

  CatalogoHub? hubForEntrada(CatalogoEntrada entrada) {
    for (final hub in hubs) {
      for (final item in hub.itens) {
        if (identical(item, entrada) || item.id == entrada.id) return hub;
        if (item.abas.any((a) => a.id == entrada.id)) return hub;
      }
    }
    return null;
  }

  static bool _matches(CatalogoEntrada e, String needle) {
    if (e.id.toLowerCase() == needle) return true;
    return e.legacyIds.any((id) => id.toLowerCase() == needle);
  }
}

class CatalogoHub {
  const CatalogoHub({
    required this.id,
    required this.titulo,
    required this.itens,
    this.subtitulo,
    this.papel,
  });

  final String id;
  final String titulo;
  final String? subtitulo;
  final String? papel;
  final List<CatalogoEntrada> itens;

  factory CatalogoHub.fromJson(Map<String, dynamic> json) {
    final itensRaw = json['itens'] ?? json['items'];
    return CatalogoHub(
      id: (json['id'] as String?)?.trim() ?? '',
      titulo: (json['titulo'] as String?)?.trim() ?? '',
      subtitulo: (json['subtitulo'] as String?)?.trim(),
      papel: (json['papel'] as String?)?.trim(),
      itens:
          itensRaw is List
              ? itensRaw
                  .whereType<Map>()
                  .map(
                    (e) => CatalogoEntrada.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList(growable: false)
              : const [],
    );
  }
}

/// Item do hub, atalho da home ou aba — mesmo shape do BFF.
class CatalogoEntrada {
  const CatalogoEntrada({
    required this.id,
    required this.titulo,
    this.subtitulo,
    this.rotaApp,
    this.featureGate,
    this.unlocked = true,
    this.upgradePlano,
    this.papel,
    this.legacyIds = const [],
    this.abas = const [],
    this.destaqueHome = false,
  });

  final String id;
  final String titulo;
  final String? subtitulo;
  final String? rotaApp;
  final String? featureGate;
  final bool unlocked;
  final String? upgradePlano;
  final String? papel;
  final List<String> legacyIds;
  final List<CatalogoEntrada> abas;
  final bool destaqueHome;

  bool get isHubComAbas => abas.isNotEmpty;

  factory CatalogoEntrada.fromJson(Map<String, dynamic> json) {
    final legacyRaw = json['legacyIds'];
    final abasRaw = json['abas'];
    return CatalogoEntrada(
      id: (json['id'] as String?)?.trim() ?? '',
      titulo: (json['titulo'] as String?)?.trim() ?? '',
      subtitulo: (json['subtitulo'] as String?)?.trim(),
      rotaApp: (json['rotaApp'] as String?)?.trim(),
      featureGate: (json['featureGate'] as String?)?.trim(),
      unlocked: json['unlocked'] != false,
      upgradePlano: (json['upgradePlano'] as String?)?.trim(),
      papel: (json['papel'] as String?)?.trim(),
      legacyIds:
          legacyRaw is List
              ? legacyRaw
                  .map((e) => '$e'.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(growable: false)
              : const [],
      abas:
          abasRaw is List
              ? abasRaw
                  .whereType<Map>()
                  .map(
                    (e) => CatalogoEntrada.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList(growable: false)
              : const [],
      destaqueHome: json['destaqueHome'] == true,
    );
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (titulo.toLowerCase().contains(q)) return true;
    if ((subtitulo ?? '').toLowerCase().contains(q)) return true;
    if (id.toLowerCase().contains(q)) return true;
    if (legacyIds.any((id) => id.toLowerCase().contains(q))) return true;
    if (abas.any((a) => a.matchesQuery(q))) return true;
    return false;
  }
}

/// Papéis do BFF — essenciais/úteis acima; studio/avançado/conta abaixo.
enum CatalogoPapelTier { primario, secundario }

CatalogoPapelTier catalogoPapelTier(String? papel) {
  switch ((papel ?? '').trim().toLowerCase()) {
    case 'studio':
    case 'avancado':
    case 'avançado':
    case 'conta':
      return CatalogoPapelTier.secundario;
    default:
      return CatalogoPapelTier.primario;
  }
}
