import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/perfil/data/lgpd_consent_repository.dart';
import '../../features/perfil/widgets/perfil_lgpd_consent_sheet.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_icons.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import '../utils/friendly_error.dart';
import '../widgets/feedback_helper.dart';
import '../widgets/fx_home_sheet.dart';
import '../widgets/fx_motion.dart';
import '../widgets/fx_tonal_button.dart';

/// Aceites de IA (Apple 5.1.2(i), LGPD). O backend barra sem eles
/// (`IaConsentGuard`); aqui o app pede antes, com o texto certo.
abstract final class IaConsentimentos {
  /// Personal: o Copiloto envia dados dos alunos, sem nome, para a IA.
  static const iaTerceiros = 'IA_TERCEIROS';

  /// Aluno: o Copiloto do personal usa treinos, aderência e objetivo.
  static const iaCopiloto = 'IA_COPILOTO';

  /// Aluno: também saúde do wearable e a tendência das medidas.
  static const saudeIa = 'SAUDE_IA';

  static const sufixoRevogado = '_REVOGADO';

  static const tipos = [iaTerceiros, iaCopiloto, saudeIa];

  /// Erros do backend quando falta aceite.
  static const codigoAceitePersonal = 'IA_ACEITE_PERSONAL';
  static const codigoAceiteAluno = 'IA_ACEITE_ALUNO';

  static const textoPersonal =
      'O Copiloto envia dados de treino dos seus alunos, sem o nome deles, '
      'para Google Gemini ou Groq, que geram as sugestões. Nada é aplicado '
      'sem você revisar.';

  static const textoAluno =
      'Seu personal pode usar um assistente de IA para revisar seus treinos. '
      'Ele recebe sua frequência, a aderência à ficha e seu objetivo, sem o '
      'seu nome. Você pode mudar isso em Perfil > Privacidade.';

  static const textoSaude =
      'Seu personal vê sua prontidão e os dados do dia. O Copiloto de IA dele '
      'também pode usar esses dados e a tendência das suas medidas, sem o seu '
      'nome e sem os valores.';
}

/// O aceite de [tipo] vale se for mais recente que a revogação dele.
bool iaAceiteVigente(Map<String, LgpdConsent> aceites, String tipo) {
  final aceite = aceites[tipo];
  if (aceite == null) return false;
  final revogado = aceites['$tipo${IaConsentimentos.sufixoRevogado}'];
  if (revogado == null) return true;
  final a = DateTime.tryParse(aceite.aceitoEm);
  final r = DateTime.tryParse(revogado.aceitoEm);
  if (a == null || r == null) return false;
  return a.isAfter(r);
}

/// Já respondeu (aceitou ou recusou): não pergunta de novo sozinho.
bool iaJaRespondeu(Map<String, LgpdConsent> aceites, String tipo) =>
    aceites.containsKey(tipo) ||
    aceites.containsKey('$tipo${IaConsentimentos.sufixoRevogado}');

String iaConsentLabel(String tipo) => switch (tipo) {
  IaConsentimentos.iaTerceiros => 'Copiloto de IA',
  IaConsentimentos.iaCopiloto => 'Meus treinos no Copiloto',
  IaConsentimentos.saudeIa => 'Dados de saúde no Copiloto',
  _ => tipo,
};

/// Folha de aceite: devolve `true` em "permitir", `false` em "agora não".
Future<bool?> _perguntar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String permitir,
  required String recusar,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showFxHomeSheet<bool>(
    context,
    builder:
        (ctx) => FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(
            FxIcons.ia,
            color: Theme.of(ctx).colorScheme.primary,
            size: 22,
          ),
          title: titulo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                texto,
                style: FocuxHubTypography.body(color: ShellChrome.of(ctx).ink),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: permitir,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: TokensStrip.s2),
              FxTonalButton(
                label: recusar,
                expanded: true,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
  );
}

/// Personal: antes da primeira análise. `true` quando pode seguir.
Future<bool> garantirAceiteCopiloto(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(lgpdConsentRepositoryProvider);
  try {
    final aceites = await repo.ultimosPorTipo();
    if (iaAceiteVigente(aceites, IaConsentimentos.iaTerceiros)) return true;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return false;
  }
  if (!context.mounted) return false;
  final ok = await _perguntar(
    context,
    titulo: 'Usar o Copiloto de IA?',
    texto: IaConsentimentos.textoPersonal,
    permitir: 'Usar o Copiloto',
    recusar: 'Agora não',
  );
  if (ok != true) return false;
  try {
    await repo.registrar(tipo: IaConsentimentos.iaTerceiros);
    return true;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return false;
  }
}

/// Aluno: pergunta uma vez (na Home) o que ainda não foi respondido.
/// [compartilhaSaude]: o interruptor "Compartilhar com meu personal" ligado.
Future<void> pedirAceitesIaDoAluno(
  BuildContext context,
  LgpdConsentRepository repo, {
  required bool compartilhaSaude,
}) async {
  final Map<String, LgpdConsent> aceites;
  try {
    aceites = await repo.ultimosPorTipo();
  } catch (_) {
    return; // Pergunta na próxima abertura.
  }
  Future<void> perguntar(String tipo, String titulo, String texto) async {
    if (iaJaRespondeu(aceites, tipo) || !context.mounted) return;
    final ok = await _perguntar(
      context,
      titulo: titulo,
      texto: texto,
      permitir: 'Pode usar',
      recusar: tipo == IaConsentimentos.saudeIa ? 'Só meu personal' : 'Agora não',
    );
    if (ok == null) return;
    try {
      await repo.registrar(
        tipo: ok ? tipo : '$tipo${IaConsentimentos.sufixoRevogado}',
      );
    } catch (_) {}
  }

  await perguntar(
    IaConsentimentos.iaCopiloto,
    'Assistente de IA do seu personal',
    IaConsentimentos.textoAluno,
  );
  if (compartilhaSaude) {
    await perguntar(
      IaConsentimentos.saudeIa,
      'Saúde no assistente de IA',
      IaConsentimentos.textoSaude,
    );
  }
}
