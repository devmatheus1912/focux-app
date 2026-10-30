import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/semana_da_fila.dart';
import '../data/checkin_repository.dart';
import '../providers/checkin_provider.dart';
import '../utils/treinos_hub_texts.dart';
import '../utils/treinos_hub_view.dart';

/// Sem nenhum treino: pedir a ficha ao personal.
class TreinosHubVazio extends StatelessWidget {
  const TreinosHubVazio({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return FxEmptyState(
      icon: 'dumbbell',
      title: s.treinosHubVazioTitulo,
      subtitle: s.treinosHubVazioSubtitulo,
      action: FxEmptyAction(
        label: s.treinosHubVazioCta,
        onTap: () => openAlunoRoute(context, '/chat/aluno'),
      ),
    );
  }
}

class TreinosAjudaBotao extends StatelessWidget {
  const TreinosAjudaBotao({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return FxHelpIconButton(
      tooltip: s.treinosAjudaTooltip,
      onTap: () => showFxHelpSheet(
        context,
        title: s.treinosAjudaTitulo,
        subtitle: s.treinosAjudaSubtitulo,
        tips: [
          FxHelpTip(s.treinosAjudaFichaTitulo, s.treinosAjudaFicha),
          FxHelpTip(s.treinosAjudaSemanaTitulo, s.treinosAjudaSemana),
          FxHelpTip(s.treinosAjudaUltimosTitulo, s.treinosAjudaUltimos),
        ],
      ),
    );
  }
}

/// Treinos do plano que não têm dia na semana.
List<ExecucaoTreino> treinosForaDaSemana(List<ExecucaoTreino> plano, RotinaFila rotina) {
  if (!rotina.temTreino) return plano;
  final naSemana = {
    for (final dia in semanaDaFila(rotina))
      for (final sessao in dia.sessoes) sessao.treinoId,
  };
  return [for (final t in plano) if (!naSemana.contains(t.treinoId)) t];
}

/// Descarta a sessão que ficou aberta, com confirmação. Verdadeiro se descartou.
Future<bool> descartarSessaoAberta(
  BuildContext context,
  WidgetRef ref,
  ExecucaoTreino aberta, {
  ExecucaoTreino? depois,
}) async {
  final s = S.of(context);
  final ok = await showFxConfirmSheet(
    context,
    title: depois == null
        ? s.treinosDescartarTitulo(aberta.treinoNome)
        : s.treinosDescartarEComecar(aberta.treinoNome, depois.treinoNome),
    message: s.treinosDescartarTexto,
    confirmLabel: s.treinosDescartar,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    await ref.read(checkinRepositoryProvider).descartar(aberta.id!);
    return true;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return false;
  }
}

/// O que vai dentro da linha de hoje. Sessão antiga aberta: o botão do dia
/// pergunta antes de descartar. Descanso e concluído: botão discreto.
Widget? acaoDeHoje(
  S s,
  TreinosHubView view,
  DateTime now, {
  required String? proximoNome,
  required (int, int)? ordem,
  required VoidCallback aoFazer,
  required VoidCallback? aoAbrir,
  required void Function(ExecucaoTreino aberta, ExecucaoTreino hoje) aoComecarDescartando,
}) {
  final aberta = view.sessaoAntiga;
  if (aberta != null) {
    final hoje = view.treinoDeHoje;
    if (hoje == null || hoje.treinoId == aberta.treinoId) return null;
    return _BotaoDeHoje(
      detalhe: s.treinosExercicios(hoje.totalExercicios),
      rotulo: s.treinosComecar,
      principal: true,
      onPressed: () => aoComecarDescartando(aberta, hoje),
    );
  }
  final destaque = view.destaque;
  if (destaque == null) return null;
  final texto = treinosDestaqueTexto(
    s,
    destaque,
    hoje: now,
    proximoNome: proximoNome,
    ordem: ordem?.$1,
    ordemTotal: ordem?.$2,
    proximoEhDescanso: destaque.proximoEhDescanso,
  );
  final principal =
      destaque.tipo == TreinosDestaqueTipo.proximo ||
      destaque.tipo == TreinosDestaqueTipo.emAndamento;
  // Treino de hoje feito: o botão já diz qual é o próximo.
  final maisUm =
      destaque.tipo == TreinosDestaqueTipo.concluidoHoje &&
      !destaque.proximoEhDescanso &&
      proximoNome != null &&
      proximoNome.trim().isNotEmpty;
  return _BotaoDeHoje(
    detalhe: maisUm
        ? null
        : destaque.tipo == TreinosDestaqueTipo.emAndamento
        ? '${texto.titulo} · ${texto.detalhe}'
        : texto.detalhe,
    rotulo: maisUm
        ? s.treinosFazerMaisUmNome(proximoNome.trim())
        : texto.cta ?? s.treinosHojeVerboVer,
    principal: principal,
    onPressed: texto.cta != null ? aoFazer : (aoAbrir ?? () {}),
  );
}

class _BotaoDeHoje extends StatelessWidget {
  const _BotaoDeHoje({
    required this.detalhe,
    required this.rotulo,
    required this.principal,
    required this.onPressed,
  });

  final String? detalhe;
  final String rotulo;
  final bool principal;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (detalhe case final texto?) ...[
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              texto,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
        if (principal)
          FxLiquidPrimaryButton(label: rotulo, onPressed: onPressed)
        else
          Align(
            alignment: Alignment.centerLeft,
            child: FxTonalButton(label: rotulo, compact: true, onPressed: onPressed),
          ),
      ],
    );
  }
}
