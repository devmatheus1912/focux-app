import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_link_row.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/data/plano_recurso_textos.dart';
import '../providers/dashboard_provider.dart';

/// Primeiro nome do personal do aluno logado; nulo sem a Hoje carregada.
/// Em `build` use o padrão ([ouvir] = true); em callbacks, `ouvir: false`.
String? alunoNomeDoPersonal(WidgetRef ref, {bool ouvir = true}) {
  final home = ouvir
      ? ref.watch(alunoDashboardHomeProvider)
      : ref.read(alunoDashboardHomeProvider);
  final nome = home.value?.personalBrand.nomePersonal.trim();
  if (nome == null || nome.isEmpty) return null;
  return nome.split(' ').first;
}

/// Texto curto para ação do aluno barrada pelo plano do personal (toast).
String alunoRecursoIndisponivelTexto(String recurso, String? personal) =>
    '$recurso não está disponível. Fale com ${personal ?? 'seu personal'}.';

/// A regra única das telas do aluno: a API barrou pelo plano do personal?
/// Se sim, a carga mostra [AlunoRecursoIndisponivelConteudo] e a ação mostra
/// [alunoMensagemDeErro]; nunca o erro genérico.
bool alunoBarradoPeloPlano(Object? erro) =>
    erro != null && isPlanGateError(erro);

/// Mensagem de erro de uma ação do aluno (toast): recurso indisponível
/// quando o plano barrou, o erro amigável nos outros casos.
String alunoMensagemDeErro(
  WidgetRef ref,
  Object erro, {
  required String? capability,
  required String fallbackNome,
}) {
  if (!alunoBarradoPeloPlano(erro)) return friendlyError(erro);
  return alunoRecursoIndisponivelTexto(
    PlanoRecursoTextos.nome(capability, fallback: fallbackNome),
    alunoNomeDoPersonal(ref, ouvir: false),
  );
}

/// Aluno numa ferramenta que o plano do personal não libera (tela inteira,
/// usada pelo `FeatureGate`).
class AlunoRecursoIndisponivel extends ConsumerWidget {
  const AlunoRecursoIndisponivel({
    super.key,
    required this.capability,
    required this.fallbackNome,
  });

  final String? capability;
  final String fallbackNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurso = PlanoRecursoTextos.nome(capability, fallback: fallbackNome);
    return FxShellScaffold(
      comFundo: true,
      appBar: FxShellAppBar(
        title: recurso,
        onBack: () => safePopOr(context, () => goToRoleHome(context, ref)),
      ),
      body: SafeArea(
        child: AlunoRecursoIndisponivelConteudo(
          capability: capability,
          fallbackNome: fallbackNome,
        ),
      ),
    );
  }
}

/// O miolo do estado, para telas que já têm o próprio chrome (a API barrou
/// com a tela aberta). Nunca fala de plano, preço ou upgrade: a saída é
/// conversar com o personal. Nada se apaga quando o personal cai de plano.
class AlunoRecursoIndisponivelConteudo extends ConsumerWidget {
  const AlunoRecursoIndisponivelConteudo({
    super.key,
    required this.capability,
    required this.fallbackNome,
  });

  /// Chave do recurso ([PlanoRecursoTextos]); o nome sai de lá.
  final String? capability;
  final String fallbackNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final recurso = PlanoRecursoTextos.nome(capability, fallback: fallbackNome);
    final comQuem = alunoNomeDoPersonal(ref) ?? 'seu personal';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: chrome.line, shape: BoxShape.circle),
              child: Icon(FxIcons.cadeado, color: chrome.mute, size: 28),
            ),
            const SizedBox(height: TokensStrip.s3),
            Text(
              '$recurso não está disponível',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              'Fale com $comQuem se quiser usar.',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.body(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s1),
            Text(
              'Seus registros ficam guardados.',
              textAlign: TextAlign.center,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s4),
            FxLiquidPrimaryButton(
              label: 'Conversar com $comQuem',
              icon: FxIcons.chat,
              onPressed: () => context.go('/chat/aluno'),
            ),
            const SizedBox(height: TokensStrip.s2),
            FxLinkRow(
              label: 'Voltar',
              onTap: () => safePopOr(context, () => goToRoleHome(context, ref)),
            ),
          ],
        ),
      ),
    );
  }
}
