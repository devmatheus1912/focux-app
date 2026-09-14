// Modelos do landing studio v2.

/// Respostas cruas da entrevista (~10 min).
class LandingEntrevista {
  const LandingEntrevista({
    this.nomeMarca = '',
    this.nicho = '',
    this.promessa = '',
    this.antiPersona = '',
    this.prova = '',
    this.ofertaNome = '',
    this.ofertaInclui = '',
    this.ofertaPreco = '',
    this.cta = '',
    this.duvidas = const [],
    this.whatsapp = '',
    this.instagram = '',
  });

  final String nomeMarca;
  final String nicho;
  final String promessa;
  final String antiPersona;
  final String prova;
  final String ofertaNome;
  final String ofertaInclui;
  final String ofertaPreco;
  final String cta;
  final List<String> duvidas;
  final String whatsapp;
  final String instagram;

  factory LandingEntrevista.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LandingEntrevista();
    final rawDuvidas = json['duvidas'];
    final duvidas = <String>[];
    if (rawDuvidas is List) {
      for (final item in rawDuvidas) {
        final text = item?.toString().trim() ?? '';
        if (text.isNotEmpty) duvidas.add(text);
      }
    }
    return LandingEntrevista(
      nomeMarca: (json['nomeMarca'] as String?)?.trim() ?? '',
      nicho: (json['nicho'] as String?)?.trim() ?? '',
      promessa: (json['promessa'] as String?)?.trim() ?? '',
      antiPersona: (json['antiPersona'] as String?)?.trim() ?? '',
      prova: (json['prova'] as String?)?.trim() ?? '',
      ofertaNome: (json['ofertaNome'] as String?)?.trim() ?? '',
      ofertaInclui: (json['ofertaInclui'] as String?)?.trim() ?? '',
      ofertaPreco: (json['ofertaPreco'] as String?)?.trim() ?? '',
      cta: (json['cta'] as String?)?.trim() ?? '',
      duvidas: duvidas,
      whatsapp: (json['whatsapp'] as String?)?.trim() ?? '',
      instagram: (json['instagram'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nomeMarca': nomeMarca.trim(),
    'nicho': nicho.trim(),
    'promessa': promessa.trim(),
    'antiPersona': antiPersona.trim(),
    'prova': prova.trim(),
    'ofertaNome': ofertaNome.trim(),
    'ofertaInclui': ofertaInclui.trim(),
    'ofertaPreco': ofertaPreco.trim(),
    'cta': cta.trim(),
    'duvidas':
        duvidas.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    'whatsapp': whatsapp.trim(),
    'instagram': instagram.trim(),
  };

  bool get isReadyToGenerate =>
      nomeMarca.trim().isNotEmpty &&
      nicho.trim().isNotEmpty &&
      promessa.trim().isNotEmpty &&
      ofertaNome.trim().isNotEmpty &&
      cta.trim().isNotEmpty;
}

class LandingMetodoPasso {
  const LandingMetodoPasso({this.titulo = '', this.descricao = ''});

  final String titulo;
  final String descricao;

  factory LandingMetodoPasso.fromJson(Map<String, dynamic> json) =>
      LandingMetodoPasso(
        titulo: (json['titulo'] as String?)?.trim() ?? '',
        descricao: (json['descricao'] as String?)?.trim() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'titulo': titulo.trim(),
    'descricao': descricao.trim(),
  };
}

class LandingStudioServico {
  const LandingStudioServico({this.titulo = '', this.descricao = ''});

  final String titulo;
  final String descricao;

  factory LandingStudioServico.fromJson(Map<String, dynamic> json) =>
      LandingStudioServico(
        titulo: (json['titulo'] as String?)?.trim() ?? '',
        descricao: (json['descricao'] as String?)?.trim() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'titulo': titulo.trim(),
    'descricao': descricao.trim(),
  };
}

class LandingStudioFaq {
  const LandingStudioFaq({this.pergunta = '', this.resposta = ''});

  final String pergunta;
  final String resposta;

  factory LandingStudioFaq.fromJson(Map<String, dynamic> json) =>
      LandingStudioFaq(
        pergunta: (json['pergunta'] as String?)?.trim() ?? '',
        resposta: (json['resposta'] as String?)?.trim() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'pergunta': pergunta.trim(),
    'resposta': resposta.trim(),
  };
}

/// Copy gerado pelo backend (LLM + fallback).
class LandingGerado {
  const LandingGerado({
    this.heroTitle = '',
    this.heroSubtitle = '',
    this.primaryCta = '',
    this.bio = '',
    this.metodo = const [],
    this.servicos = const [],
    this.faq = const [],
    this.fechamento = '',
    this.needsProof = false,
  });

  final String heroTitle;
  final String heroSubtitle;
  final String primaryCta;
  final String bio;
  final List<LandingMetodoPasso> metodo;
  final List<LandingStudioServico> servicos;
  final List<LandingStudioFaq> faq;
  final String fechamento;
  final bool needsProof;

  factory LandingGerado.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LandingGerado();
    return LandingGerado(
      heroTitle: (json['heroTitle'] as String?)?.trim() ?? '',
      heroSubtitle: (json['heroSubtitle'] as String?)?.trim() ?? '',
      primaryCta: (json['primaryCta'] as String?)?.trim() ?? '',
      bio: (json['bio'] as String?)?.trim() ?? '',
      metodo:
          (json['metodo'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (e) => LandingMetodoPasso.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
      servicos:
          (json['servicos'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (e) => LandingStudioServico.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
      faq:
          (json['faq'] as List<dynamic>? ?? [])
              .whereType<Map>()
              .map(
                (e) =>
                    LandingStudioFaq.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
      fechamento: (json['fechamento'] as String?)?.trim() ?? '',
      needsProof: json['needsProof'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'heroTitle': heroTitle.trim(),
    'heroSubtitle': heroSubtitle.trim(),
    'primaryCta': primaryCta.trim(),
    'bio': bio.trim(),
    'metodo': metodo.map((e) => e.toJson()).toList(),
    'servicos': servicos.map((e) => e.toJson()).toList(),
    'faq': faq.map((e) => e.toJson()).toList(),
    'fechamento': fechamento.trim(),
    'needsProof': needsProof,
  };

  bool get hasPublishableCopy =>
      heroTitle.trim().isNotEmpty && primaryCta.trim().isNotEmpty;
}

class LandingMidia {
  const LandingMidia({
    this.heroImageUrl,
    this.bioImageUrl,
    this.accentColor,
  });

  final String? heroImageUrl;
  final String? bioImageUrl;
  final String? accentColor;

  factory LandingMidia.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LandingMidia();
    return LandingMidia(
      heroImageUrl: (json['heroImageUrl'] as String?)?.trim(),
      bioImageUrl: (json['bioImageUrl'] as String?)?.trim(),
      accentColor: (json['accentColor'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (heroImageUrl != null) 'heroImageUrl': heroImageUrl,
    if (bioImageUrl != null) 'bioImageUrl': bioImageUrl,
    if (accentColor != null) 'accentColor': accentColor,
  };
}

class LandingStudioState {
  const LandingStudioState({
    this.entrevista = const LandingEntrevista(),
    this.gerado = const LandingGerado(),
    this.midia = const LandingMidia(),
    this.publicUrl,
    this.slug,
    this.publicado = false,
    this.needsProof = false,
    this.podePublicar = false,
  });

  final LandingEntrevista entrevista;
  final LandingGerado gerado;
  final LandingMidia midia;

  /// URL canônica (`https://focuxpersonal.com/p/{slug}`).
  final String? publicUrl;
  final String? slug;
  final bool publicado;
  final bool needsProof;
  final bool podePublicar;

  factory LandingStudioState.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) return Map<String, dynamic>.from(value);
      return null;
    }

    final gerado = LandingGerado.fromJson(asMap(json['gerado']));
    final publicUrl =
        (json['publicUrl'] as String?)?.trim().isNotEmpty == true
            ? (json['publicUrl'] as String).trim()
            : (json['url'] as String?)?.trim();
    final needsProof =
        json['needsProof'] as bool? ?? gerado.needsProof;
    final podePublicar =
        json['podePublicar'] as bool? ?? gerado.hasPublishableCopy;

    // BE `LandingEstadoResponse` envia mídia flat no root; saveMidia
    // histórico pode envelopar em `midia`. Aceita os dois.
    final nestedMidia = asMap(json['midia']);
    final midia = LandingMidia.fromJson(
      nestedMidia ??
          {
            if (json['heroImageUrl'] != null)
              'heroImageUrl': json['heroImageUrl'],
            if (json['bioImageUrl'] != null) 'bioImageUrl': json['bioImageUrl'],
            if (json['accentColor'] != null) 'accentColor': json['accentColor'],
          },
    );

    return LandingStudioState(
      entrevista: LandingEntrevista.fromJson(asMap(json['entrevista'])),
      gerado: gerado,
      midia: midia,
      publicUrl: publicUrl,
      slug: (json['slug'] as String?)?.trim(),
      publicado: json['publicado'] as bool? ?? false,
      needsProof: needsProof,
      podePublicar: podePublicar,
    );
  }
}

