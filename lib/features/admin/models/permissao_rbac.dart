class PermissaoRbac {
  const PermissaoRbac({
    required this.id,
    required this.personalId,
    required this.recurso,
    required this.nivel,
  });

  final int id;
  final int personalId;
  final String recurso;
  final String nivel;

  factory PermissaoRbac.fromJson(Map<String, dynamic> json) => PermissaoRbac(
        id: json['id'] as int,
        personalId: json['personalId'] as int,
        recurso: json['recurso'] as String,
        nivel: json['nivel'] as String,
      );

  static List<PermissaoRbac> parseList(Object? data) {
    return (data as List)
        .map((e) => PermissaoRbac.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// Recursos expostos pelo backend (`RbacCatalog` + `RbacResources`).
const permissoesRbacRecursos = [
  'ALUNOS',
  'FINANCEIRO',
  'TREINOS',
  'AGENDA',
  'CHAT',
  'RELATORIOS',
  'LEADS',
  'LOJA',
  'IA',
];

const permissoesRbacNiveis = ['READ', 'WRITE', 'ADMIN'];
