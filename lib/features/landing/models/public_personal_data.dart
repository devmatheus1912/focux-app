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
        depoimentos: (j['depoimentos'] as List<dynamic>? ?? [])
            .map((e) => PublicDepoimentoItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        fotos: (j['fotos'] as List<dynamic>? ?? []).cast<String>(),
      );

  bool get isEnterprise => plano == 'ENTERPRISE';
  bool get isPremiumOrAbove => plano == 'PREMIUM' || plano == 'ENTERPRISE';
}
