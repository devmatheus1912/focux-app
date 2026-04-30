class PublicDepoimentoItem {
  final String nomeAluno;
  final String texto;
  final int nota;
  const PublicDepoimentoItem({required this.nomeAluno, required this.texto, required this.nota});
  factory PublicDepoimentoItem.fromJson(Map<String, dynamic> j) => PublicDepoimentoItem(
    nomeAluno: j['nomeAluno'] as String? ?? '',
    texto: j['texto'] as String? ?? '',
    nota: j['nota'] as int? ?? 5,
  );
}

class PublicLandingServiceItem {
  final String titulo;
  final String descricao;
  const PublicLandingServiceItem({
    required this.titulo,
    required this.descricao,
  });

  factory PublicLandingServiceItem.fromJson(Map<String, dynamic> j) =>
      PublicLandingServiceItem(
        titulo: j['titulo'] as String? ?? '',
        descricao: j['descricao'] as String? ?? '',
      );
}

class PublicLandingPackageItem {
  final String nome;
  final String descricao;
  final String preco;
  final String cta;
  const PublicLandingPackageItem({
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.cta,
  });

  factory PublicLandingPackageItem.fromJson(Map<String, dynamic> j) =>
      PublicLandingPackageItem(
        nome: j['nome'] as String? ?? '',
        descricao: j['descricao'] as String? ?? '',
        preco: j['preco'] as String? ?? '',
        cta: j['cta'] as String? ?? 'Quero saber mais',
      );
}

class PublicLandingFaqItem {
  final String pergunta;
  final String resposta;
  const PublicLandingFaqItem({
    required this.pergunta,
    required this.resposta,
  });

  factory PublicLandingFaqItem.fromJson(Map<String, dynamic> j) =>
      PublicLandingFaqItem(
        pergunta: j['pergunta'] as String? ?? '',
        resposta: j['resposta'] as String? ?? '',
      );
}

class PublicPersonalData {
  final String nomePersonal;
  final String? slogan;
  final String? logoUrl;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? descricaoProfissional;
  final String? especialidades;
  final String? instagram;
  final String? cref;
  final int totalAlunos;
  final int anoCriacao;
  final String plano;
  final String? videoUrl;
  final String? trackingId;
  final String? heroPrompt;
  final String? heroImageUrl;
  final String? generatedHeroImageUrl;
  final String? heroImageStatus;
  final String? heroImageBrief;
  final List<PublicLandingServiceItem> servicos;
  final List<PublicLandingPackageItem> pacotes;
  final List<PublicLandingFaqItem> faq;
  final List<PublicDepoimentoItem> depoimentos;
  final List<String> fotos;

  PublicPersonalData({
    required this.nomePersonal,
    this.slogan,
    this.logoUrl,
    this.corPrimaria,
    this.corSecundaria,
    this.descricaoProfissional,
    this.especialidades,
    this.instagram,
    this.cref,
    required this.totalAlunos,
    required this.anoCriacao,
    required this.plano,
    this.videoUrl,
    this.trackingId,
    this.heroPrompt,
    this.heroImageUrl,
    this.generatedHeroImageUrl,
    this.heroImageStatus,
    this.heroImageBrief,
    this.servicos = const [],
    this.pacotes = const [],
    this.faq = const [],
    this.depoimentos = const [],
    this.fotos = const [],
  });

  factory PublicPersonalData.fromJson(Map<String, dynamic> j) => PublicPersonalData(
        nomePersonal: j['nomePersonal'] as String? ?? '',
        slogan: j['slogan'] as String?,
        logoUrl: j['logoUrl'] as String?,
        corPrimaria: j['corPrimaria'] as String?,
        corSecundaria: j['corSecundaria'] as String?,
        descricaoProfissional: j['descricaoProfissional'] as String?,
        especialidades: j['especialidades'] as String?,
        instagram: j['instagram'] as String?,
        cref: j['cref'] as String?,
        totalAlunos: j['totalAlunos'] as int? ?? 0,
        anoCriacao: j['anoCriacao'] as int? ?? DateTime.now().year,
        plano: j['plano'] as String? ?? 'PREMIUM',
        videoUrl: j['videoUrl'] as String?,
        trackingId: j['trackingId'] as String?,
        heroPrompt: j['heroPrompt'] as String?,
        heroImageUrl: j['heroImageUrl'] as String?,
        generatedHeroImageUrl: j['generatedHeroImageUrl'] as String?,
        heroImageStatus: j['heroImageStatus'] as String?,
        heroImageBrief: j['heroImageBrief'] as String?,
        servicos: (j['servicos'] as List<dynamic>? ?? [])
            .map((e) => PublicLandingServiceItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        pacotes: (j['pacotes'] as List<dynamic>? ?? [])
            .map((e) => PublicLandingPackageItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        faq: (j['faq'] as List<dynamic>? ?? [])
            .map((e) => PublicLandingFaqItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        depoimentos: (j['depoimentos'] as List<dynamic>? ?? [])
            .map((e) => PublicDepoimentoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        fotos: (j['fotos'] as List<dynamic>? ?? []).cast<String>(),
      );

  bool get isEnterprise => plano == 'ENTERPRISE';
  bool get isPremiumOrAbove => plano == 'PREMIUM' || plano == 'ENTERPRISE';
}
