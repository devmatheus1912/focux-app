import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_home_texts.dart';

/// Saudação da Home do aluno. A assinatura do personal vem no
/// `AlunoPersonalCard`, abaixo do card de foco.
class AlunoHomeHeader extends StatelessWidget {
  const AlunoHomeHeader({super.key, required this.alunoNome});

  final String alunoNome;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primeiroNome = alunoPrimeiroNome(alunoNome);

    return Semantics(
      header: true,
      child: Text(
        primeiroNome.isEmpty
            ? s.alunoHomeSaudacaoSemNome
            : s.alunoHomeSaudacao(primeiroNome),
        style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
