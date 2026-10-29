/// Estilo da marca do personal no app do aluno. Três opções prontas em vez de
/// edição livre: o personal escolhe um clima e a interface se ajusta.
enum BrandStyle {
  /// Card branco com a cor da marca como acento.
  classico('CLASSICO'),

  /// Card principal sólido na cor da marca (degradê de mesma matiz), fundo
  /// tingido e acento secundário.
  cinematografico('CINEMATOGRAFICO'),

  /// Só a primária; sem preenchimento: contorno fino e a cor no destaque.
  minimalista('MINIMALISTA');

  const BrandStyle(this.api);

  /// Valor gravado no backend.
  final String api;

  static BrandStyle fromApi(String? raw) {
    final valor = raw?.trim().toUpperCase();
    for (final estilo in BrandStyle.values) {
      if (estilo.api == valor) return estilo;
    }
    return BrandStyle.classico;
  }

  /// Card principal sólido na cor da marca.
  bool get cardSolido => this == BrandStyle.cinematografico;
  bool get usaAcentoSecundario => this == BrandStyle.cinematografico;
  bool get tingeFundo => this == BrandStyle.cinematografico;
}
