/// Membro do tenant (equipe / RBAC) — parse na borda API.
class TenantMembro {
  const TenantMembro({
    required this.id,
    required this.userEmail,
    required this.role,
    required this.status,
    this.tenantId,
    this.userId,
  });

  final int id;
  final int? tenantId;
  final int? userId;
  final String userEmail;
  final String role;
  final String status;

  factory TenantMembro.fromJson(Map<String, dynamic> json) => TenantMembro(
    id: json['id'] as int,
    tenantId: json['tenantId'] as int?,
    userId: json['userId'] as int?,
    userEmail: (json['userEmail'] ?? '').toString(),
    role: (json['role'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
  );
}

