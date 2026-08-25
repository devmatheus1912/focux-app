part of 'perfil_screen.dart';

class _CompletenessCard extends StatelessWidget {
  final int score;
  final bool isDark;
  final List<PerfilChecklistItem> items;
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _CompletenessCard({
    required this.score,
    required this.isDark,
    required this.items,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final mute = chrome.mute;
    final line = chrome.line;
    final missing = items.where((item) => !item.done).toList();

    return Semantics(
      container: true,
      label: 'Prontidão comercial. $score por cento.',
      child: FxSettingsGroup(
        header: 'Prontidão comercial',
        caption: '${perfilReadinessGapCopy(missing.length)} · $score%',
        children: [
          for (var i = 0; i < missing.length; i++)
            FxSettingsTile(
              icon: _checklistIcon(missing[i].label),
              label: missing[i].label,
              value: 'Pendente',
              mute: mute,
              line: line,
              showDivider: i != missing.length - 1,
              onTap: () => onChecklistAction(missing[i].action),
            ),
        ],
      ),
    );
  }
}

IconData _checklistIcon(String label) => switch (label) {
  'Foto' => Icons.photo_outlined,
  'Telefone' => Icons.phone_outlined,
  'CREF' => Icons.badge_outlined,
  'Especialidade' => Icons.fitness_center_outlined,
  'Bio' => Icons.notes_outlined,
  'Instagram' => Icons.alternate_email_rounded,
  'Paleta' => Icons.palette_outlined,
  'PIX' => Icons.qr_code_outlined,
  _ => Icons.radio_button_unchecked,
};

class _ProfessionalDataPanel extends StatelessWidget {
  final PerfilProfessionalSummary summary;
  final Color mute;
  final Color line;
  final VoidCallback onEdit;

  const _ProfessionalDataPanel({
    required this.summary,
    required this.mute,
    required this.line,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final facts = summary.facts;
    return FxSettingsGroup(
      header: 'Cadastro',
      caption: 'Toque no item para completar.',
      children: [
        for (var i = 0; i < facts.length; i++)
          FxSettingsTile(
            icon: facts[i].icon,
            label: facts[i].label,
            value: facts[i].value,
            mute: mute,
            line: line,
            showDivider: i != facts.length - 1,
            onTap: onEdit,
          ),
      ],
    );
  }
}

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

Color _parseColor(String? value, {required Color fallback}) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  final sanitized = value.trim().replaceFirst('#', '');
  if (sanitized.length != 6 && sanitized.length != 8) {
    return fallback;
  }

  final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return fallback;
  }

  return Color(parsed);
}
