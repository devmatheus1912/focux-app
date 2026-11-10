import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/legal/ia_consentimentos.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lgpd_consent_repository.dart';
import '../utils/lgpd_consent_display.dart';
import '../../../core/theme/fx_icons.dart';

final lgpdConsentRepositoryProvider = Provider<LgpdConsentRepository>(
  (ref) => LgpdConsentRepository(ref.read(apiClientProvider)),
);

Future<void> showPerfilLgpdConsentSheet(
  BuildContext context, {
  List<String> tipos = lgpdConsentTiposPersonal,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showFxHomeSheet<void>(
    context,
    builder: (ctx) => FxHomeSheetScaffold(
      isDark: isDark,
      leading: Icon(
        FxIcons.privacidade,
        color: Theme.of(ctx).colorScheme.primary,
        size: 22,
      ),
      title: 'Consentimentos',
      subtitle: 'Toque em um documento para ler.',
      child: PerfilLgpdConsentBody(tipos: tipos),
    ),
  );
}

Future<void> _abrirDocPadrao(String tipo) async {
  if (tipo == 'TERMOS') {
    await FocuxLegal.openTerms();
  } else {
    await FocuxLegal.openPrivacy();
  }
}

class PerfilLgpdConsentBody extends ConsumerStatefulWidget {
  const PerfilLgpdConsentBody({
    super.key,
    required this.tipos,
    this.onAbrirDoc = _abrirDocPadrao,
  });

  final List<String> tipos;
  final Future<void> Function(String tipo) onAbrirDoc;

  @override
  ConsumerState<PerfilLgpdConsentBody> createState() =>
      _PerfilLgpdConsentBodyState();
}

class _PerfilLgpdConsentBodyState extends ConsumerState<PerfilLgpdConsentBody> {
  Map<String, LgpdConsent> _aceites = const {};
  var _loading = true;
  String? _erro;
  String? _busyTipo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  LgpdConsentEstado _estado(String tipo) {
    // IA: vale o mais recente entre aceite e revogação, não a versão.
    if (lgpdConsentEhIa(tipo)) {
      return iaAceiteVigente(_aceites, tipo.toUpperCase())
          ? LgpdConsentEstado.aceito
          : LgpdConsentEstado.pendente;
    }
    return lgpdConsentEstado(
      _aceites[tipo.toUpperCase()],
      FocuxLegal.consentDocumentVersion,
    );
  }

  /// IA: permitir ou revogar, sem tela de documento.
  Future<void> _alternarIa(String tipo) async {
    if (_busyTipo != null) return;
    final permitir = _estado(tipo) != LgpdConsentEstado.aceito;
    final label = lgpdConsentTipoLabel(tipo);
    if (!permitir) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Revogar $label?',
        message: 'O assistente de IA deixa de receber esses dados a partir de agora.',
        confirmLabel: 'Revogar',
        cancelLabel: 'Manter',
        destructive: true,
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busyTipo = tipo);
    try {
      final saved = await ref
          .read(lgpdConsentRepositoryProvider)
          .registrar(
            tipo: permitir ? tipo : '$tipo${IaConsentimentos.sufixoRevogado}',
          );
      if (!mounted) return;
      setState(() {
        _aceites = {..._aceites, saved.tipo: saved};
        _busyTipo = null;
      });
      FeedbackHelper.showSuccess(
        context,
        permitir ? '$label permitido.' : '$label revogado.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyTipo = null);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final aceites =
          await ref.read(lgpdConsentRepositoryProvider).ultimosPorTipo();
      if (!mounted) return;
      setState(() {
        _aceites = aceites;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _lerEAceitar(String tipo) async {
    if (_busyTipo != null) return;
    final label = lgpdConsentTipoLabel(tipo);
    await widget.onAbrirDoc(tipo);
    if (!mounted) return;
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Aceitar $label?',
      message:
          'Registra seu aceite da versão ${FocuxLegal.consentDocumentVersion}.',
      confirmLabel: 'Aceitar',
      cancelLabel: 'Agora não',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyTipo = tipo);
    try {
      final saved = await ref
          .read(lgpdConsentRepositoryProvider)
          .registrar(tipo: tipo);
      if (!mounted) return;
      setState(() {
        _aceites = {..._aceites, saved.tipo: saved};
        _busyTipo = null;
      });
      FeedbackHelper.showSuccess(context, '$label aceito.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyTipo = null);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final ink = chrome.ink;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TokensStrip.s4),
        child: Center(child: FxLoading()),
      );
    }
    if (_erro != null) {
      return Text(_erro!, style: FocuxHubTypography.bodyMuted(color: mute));
    }

    final documentos = widget.tipos.where((t) => !lgpdConsentEhIa(t)).toList();
    final aceitos =
        documentos.where((t) => _estado(t) == LgpdConsentEstado.aceito).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lgpdConsentResumo(aceitos, documentos.length),
          style: FocuxHubTypography.bodyMuted(color: mute),
        ),
        const SizedBox(height: TokensStrip.s2),
        for (final tipo in widget.tipos)
          _ConsentRow(
            titulo: lgpdConsentTipoLabel(tipo),
            subtitulo:
                lgpdConsentEhIa(tipo)
                    ? (_estado(tipo) == LgpdConsentEstado.aceito
                        ? 'Permitido'
                        : 'Não permitido')
                    : switch (_estado(tipo)) {
                      LgpdConsentEstado.aceito => lgpdConsentAceitoLabel(
                        _aceites[tipo.toUpperCase()]!,
                      ),
                      LgpdConsentEstado.versaoAntiga => 'Nova versão disponível',
                      LgpdConsentEstado.pendente => 'Ainda não aceito',
                    },
            aceito: _estado(tipo) == LgpdConsentEstado.aceito,
            busy: _busyTipo == tipo,
            ink: ink,
            mute: mute,
            onAbrir: () => widget.onAbrirDoc(tipo),
            ia: lgpdConsentEhIa(tipo),
            onAceitar:
                _busyTipo != null
                    ? null
                    : lgpdConsentEhIa(tipo)
                    ? () => _alternarIa(tipo)
                    : () => _lerEAceitar(tipo),
          ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    required this.titulo,
    required this.subtitulo,
    required this.aceito,
    required this.busy,
    required this.ink,
    required this.mute,
    required this.onAbrir,
    required this.onAceitar,
    this.ia = false,
  });

  /// Aceite de IA: "Permitir" ou "Revogar" no lugar de "Ler e aceitar".
  final bool ia;
  final String titulo;
  final String subtitulo;
  final bool aceito;
  final bool busy;
  final Color ink;
  final Color mute;
  final VoidCallback onAbrir;
  final VoidCallback? onAceitar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onAbrir,
            borderRadius: BorderRadius.circular(TokensStrip.rInput),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.cardTitle(color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitulo,
                          style: FocuxHubTypography.bodyMuted(color: mute),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  if (busy)
                    const SizedBox(width: 22, height: 22, child: FxLoading())
                  else if (aceito)
                    const Icon(
                      FxIcons.concluidoAtivo,
                      color: EagleTokens.good,
                      size: 22,
                    )
                  else
                    Icon(FxIcons.chevronDireita, color: mute, size: 22),
                ],
              ),
            ),
          ),
          if (ia && !busy)
            aceito
                ? FxTonalButton(
                  label: 'Revogar',
                  expanded: true,
                  onPressed: onAceitar,
                )
                : FxLiquidPrimaryButton(
                  label: 'Permitir',
                  onPressed: onAceitar,
                )
          else if (!aceito && !busy)
            FxLiquidPrimaryButton(
              label: 'Ler e aceitar',
              onPressed: onAceitar,
            ),
        ],
      ),
    );
  }
}
