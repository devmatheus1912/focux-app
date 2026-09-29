import '../../auth/providers/auth_provider.dart';

/// Só o personal compra assinatura; aluno e sessão deslogada não ouvem a loja.
bool iapShouldListenForPurchases({
  required AuthStatus status,
  required UserRole? role,
}) => status == AuthStatus.authenticated && role == UserRole.personal;
