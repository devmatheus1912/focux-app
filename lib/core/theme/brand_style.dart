/// Estilo da marca do personal no app do aluno. Três opções prontas em vez de
/// edição livre: o personal escolhe um clima e a interface se ajusta.
enum BrandStyle {
  /// Como sempre foi: cor primária como acento.
  classico('CLASSICO'),

  /// Card principal em tom sólido da marca, fundo tingido e acento secundário.
  cinematografico('CINEMATOGRAFICO'),

  /// Só a primária; superfícies neutras e sem gradiente.
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

  bool get usaGradiente => this == BrandStyle.cinematografico;
  bool get usaAcentoSecundario => this == BrandStyle.cinematografico;
  bool get tingeFundo => this == BrandStyle.cinematografico;
}
