part of 'perfil_screen.dart';

Future<void> _showDeleteAccountDialog(BuildContext context) {
  final auth = ProviderScope.containerOf(context).read(authProvider.notifier);
  return excluirContaFlow(
    context,
    dio: ApiClient().dio,
    papel: ExcluirContaPapel.personal,
    avisoAssinatura: true,
    // Conta já excluída no backend: sair sem pedir confirmação.
    aposExcluir: () async {
      await auth.logout();
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(context, 'Conta excluída com sucesso.');
      context.go('/login');
    },
  );
}

String _buildSubtitle(PerfilPersonal perfil) {
  final specialty = perfil.especialidade ?? 'Personal Trainer';
  final ig = perfil.instagram?.trim();
  if (ig != null && ig.isNotEmpty) {
    return '$specialty · @${ig.replaceFirst('@', '')}';
  }
  return specialty;
}

String _initials(String nome) {
  final parts = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty);
  if (parts.isEmpty) return 'FP';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
