import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lgpd_consent_repository.dart';
import '../utils/lgpd_consent_display.dart';

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
        Icons.privacy_tip_outlined,
        color: Theme.of(ctx).colorScheme.primary,
        size: 22,
      ),
      title: 'Consentimentos',
      subtitle: 'Leia cada documento e confirme o aceite (LGPD).',
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

  LgpdConsentEstado _estado(String tipo) => lgpdConsentEstado(
    _aceites[tipo.toUpperCase()],
    FocuxLegal.consentDocumentVersion,
  );

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

    final aceitos =
        widget.tipos.where((t) => _estado(t) == LgpdConsentEstado.aceito).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          lgpdConsentResumo(aceitos, widget.tipos.length),
          style: FocuxHubTypography.bodyMuted(color: mute),
        ),
        const SizedBox(height: TokensStrip.s2),
        for (final tipo in widget.tipos)
          _ConsentRow(
            titulo: lgpdConsentTipoLabel(tipo),
            subtitulo: switch (_estado(tipo)) {
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
            onAceitar: _busyTipo != null ? null : () => _lerEAceitar(tipo),
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
  });

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
    final Widget trailing;
    if (busy) {
      trailing = const SizedBox(width: 22, height: 22, child: FxLoading());
    } else if (aceito) {
      trailing = const Icon(
        Icons.check_circle_rounded,
        color: EagleTokens.good,
        size: 22,
      );
    } else {
      trailing = FilledButton.tonal(
        onPressed: onAceitar,
        child: const Text('Ler e aceitar'),
      );
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onAbrir,
      title: Text(titulo, style: FocuxHubTypography.cardTitle(color: ink)),
      subtitle: Text(subtitulo, style: FocuxHubTypography.bodyMuted(color: mute)),
      trailing: trailing,
    );
  }
}
