import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class LandingServiceItem {
  final String titulo;
  final String descricao;

  const LandingServiceItem({required this.titulo, required this.descricao});

  factory LandingServiceItem.fromJson(Map<String, dynamic> json) =>
      LandingServiceItem(
        titulo: json['titulo'] as String? ?? '',
        descricao: json['descricao'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'titulo': titulo, 'descricao': descricao};
}

class LandingPackageItem {
  final String nome;
  final String descricao;
  final String preco;
  final String cta;

  const LandingPackageItem({
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.cta,
  });

  factory LandingPackageItem.fromJson(Map<String, dynamic> json) =>
      LandingPackageItem(
        nome: json['nome'] as String? ?? '',
        descricao: json['descricao'] as String? ?? '',
        preco: json['preco'] as String? ?? '',
        cta: json['cta'] as String? ?? 'Quero saber mais',
      );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'descricao': descricao,
    'preco': preco,
    'cta': cta,
  };
}

class LandingFaqItem {
  final String pergunta;
  final String resposta;

  const LandingFaqItem({required this.pergunta, required this.resposta});

  factory LandingFaqItem.fromJson(Map<String, dynamic> json) => LandingFaqItem(
    pergunta: json['pergunta'] as String? ?? '',
    resposta: json['resposta'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {'pergunta': pergunta, 'resposta': resposta};
}

class PerfilPersonal {
  final int id;
  final String nome;
  final String email;
  final String? cref;
  final String? especialidade;
  final String? logoUrl;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? slogan;
  final String? slug;
  final String? dominioCustomizado;
  final String? videoUrl;
  final String? trackingId;
  final String? heroPrompt;
  final String? heroImageUrl;
  final String? bioImageUrl;
  final String? generatedHeroImageUrl;
  final String? heroImageStatus;
  final String? heroImageBrief;
  final String? heroTitle;
  final String? heroSubtitle;
  final String? primaryCta;
  final List<String> sectionOrder;
  final List<String> hiddenSections;
  final bool? trialUsed;
  final DateTime? trialEndsAt;
  final String plano;
  final bool isAdmin;
  // Wallet
  final String? chavePix;
  final String? tipoChavePix;
  final String? banco;
  final String? agencia;
  final String? conta;
  // Identidade / bio
  final String? descricaoProfissional;
  final String? especialidades;
  final String? instagram;
  final List<LandingServiceItem> servicos;
  final List<LandingPackageItem> pacotes;
  final List<LandingFaqItem> faq;

  PerfilPersonal({
    required this.id,
    required this.nome,
    required this.email,
    this.cref,
    this.especialidade,
    this.logoUrl,
    this.corPrimaria,
    this.corSecundaria,
    this.slogan,
    this.slug,
    this.dominioCustomizado,
    this.videoUrl,
    this.trackingId,
    this.heroPrompt,
    this.heroImageUrl,
    this.bioImageUrl,
    this.generatedHeroImageUrl,
    this.heroImageStatus,
    this.heroImageBrief,
    this.heroTitle,
    this.heroSubtitle,
    this.primaryCta,
    this.sectionOrder = const [],
    this.hiddenSections = const [],
    this.trialUsed,
    this.trialEndsAt,
    required this.plano,
    this.isAdmin = false,
    this.chavePix,
    this.tipoChavePix,
    this.banco,
    this.agencia,
    this.conta,
    this.descricaoProfissional,
    this.especialidades,
    this.instagram,
    this.servicos = const [],
    this.pacotes = const [],
    this.faq = const [],
  });

  factory PerfilPersonal.fromJson(Map<String, dynamic> json) => PerfilPersonal(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String,
    cref: json['cref'] as String?,
    especialidade: json['especialidade'] as String?,
    logoUrl: json['logoUrl'] as String?,
    corPrimaria: json['corPrimaria'] as String?,
    corSecundaria: json['corSecundaria'] as String?,
    slogan: json['slogan'] as String?,
    slug: json['slug'] as String?,
    dominioCustomizado: json['dominioCustomizado'] as String?,
    videoUrl: json['videoUrl'] as String?,
    trackingId: json['trackingId'] as String?,
    heroPrompt: json['heroPrompt'] as String?,
    heroImageUrl: json['heroImageUrl'] as String?,
    bioImageUrl: json['bioImageUrl'] as String?,
    generatedHeroImageUrl: json['generatedHeroImageUrl'] as String?,
    heroImageStatus: json['heroImageStatus'] as String?,
    heroImageBrief: json['heroImageBrief'] as String?,
    heroTitle: json['heroTitle'] as String?,
    heroSubtitle: json['heroSubtitle'] as String?,
    primaryCta: json['primaryCta'] as String?,
    sectionOrder: (json['sectionOrder'] as List<dynamic>? ?? []).cast<String>(),
    hiddenSections:
        (json['hiddenSections'] as List<dynamic>? ?? []).cast<String>(),
    trialUsed: json['trialUsed'] as bool?,
    trialEndsAt:
        json['trialEndsAt'] != null
            ? DateTime.tryParse(json['trialEndsAt'].toString())
            : null,
    plano: json['plano'] as String,
    isAdmin: json['isAdmin'] as bool? ?? false,
    chavePix: json['chavePix'] as String?,
    tipoChavePix: json['tipoChavePix'] as String?,
    banco: json['banco'] as String?,
    agencia: json['agencia'] as String?,
    conta: json['conta'] as String?,
    descricaoProfissional: json['descricaoProfissional'] as String?,
    especialidades: json['especialidades'] as String?,
    instagram: json['instagram'] as String?,
    servicos:
        (json['servicos'] as List<dynamic>? ?? [])
            .map((e) => LandingServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    pacotes:
        (json['pacotes'] as List<dynamic>? ?? [])
            .map((e) => LandingPackageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
    faq:
        (json['faq'] as List<dynamic>? ?? [])
            .map((e) => LandingFaqItem.fromJson(e as Map<String, dynamic>))
            .toList(),
  );
}

class PerfilRepository {
  final Dio _dio;

  PerfilRepository(ApiClient client) : _dio = client.dio;

  Future<PerfilPersonal> buscar() async {
    final response = await _dio.get('/api/personal/perfil');
    return PerfilPersonal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PerfilPersonal> atualizar({
    String? nome,
    String? cref,
    String? especialidade,
    String? logoUrl,
    String? corPrimaria,
    String? descricaoProfissional,
    String? especialidades,
    String? instagram,
  }) async {
    final response = await _dio.put(
      '/api/personal/perfil',
      data: {
        if (nome != null) 'nome': nome,
        if (cref != null) 'cref': cref,
        if (especialidade != null) 'especialidade': especialidade,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (corPrimaria != null) 'corPrimaria': corPrimaria,
        if (descricaoProfissional != null)
          'descricaoProfissional': descricaoProfissional,
        if (especialidades != null) 'especialidades': especialidades,
        if (instagram != null) 'instagram': instagram,
      },
    );
    return PerfilPersonal.fromJson(response.data as Map<String, dynamic>);
  }

  /// Atualiza os dados de wallet (PIX, banco, agência, conta) do personal.
  Future<Map<String, dynamic>> atualizarWallet(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/api/personal/wallet', data: data);
    return response.data as Map<String, dynamic>;
  }
}
