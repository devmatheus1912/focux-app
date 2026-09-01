class CuratedBibliotecaPreview {
  const CuratedBibliotecaPreview({required this.totalCandidatos});

  final int totalCandidatos;

  factory CuratedBibliotecaPreview.fromJson(Map<String, dynamic> json) {
    return CuratedBibliotecaPreview(
      totalCandidatos: (json['totalCandidatos'] as num?)?.toInt() ?? 0,
    );
  }
}

class CuratedBibliotecaImport {
  const CuratedBibliotecaImport({required this.importados});

  final int importados;

  factory CuratedBibliotecaImport.fromJson(Map<String, dynamic> json) {
    return CuratedBibliotecaImport(
      importados: (json['importados'] as num?)?.toInt() ?? 0,
    );
  }
}
