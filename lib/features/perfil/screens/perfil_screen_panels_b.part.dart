part of 'perfil_screen.dart';

Future<void> _showDeleteAccountDialog(
  BuildContext context, {
  required Future<void> Function() onSessionCleared,
}) async {
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final ok = await showFxFormSheet(
    context,
    title: 'Excluir conta',
    subtitle:
        'Esta ação é irreversível. Todos os seus dados pessoais serão anonimizados '
        'conforme a LGPD (Art. 18). Dados financeiros serão mantidos por 5 anos '
        'conforme legislação fiscal.\n\n'
        'Digite sua senha e EXCLUIR para confirmar.',
    icon: Icons.delete_forever_outlined,
    confirmLabel: 'Excluir definitivamente',
    destructive: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: passwordCtrl,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Senha atual'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: confirmCtrl,
          decoration: const InputDecoration(labelText: 'Digite EXCLUIR'),
        ),
      ],
    ),
  );
  final senha = passwordCtrl.text;
  final confirmacao = confirmCtrl.text.trim();
  passwordCtrl.dispose();
  confirmCtrl.dispose();
  if (!ok || !context.mounted) return;
  try {
    await ApiClient().dio.delete(
      '/api/lgpd/me/delete',
      data: {'senha': senha, 'confirmacao': confirmacao},
    );
    await onSessionCleared();
  } catch (e) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, friendlyError(e));
  }
}

String _buildSubtitle(PerfilPersonal perfil) {
  final specialty = perfil.especialidade ?? 'Personal Trainer';
  final ig = perfil.instagram?.trim();
  if (ig != null && ig.isNotEmpty) {
    return '$specialty  |  @${ig.replaceFirst('@', '')}';
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
