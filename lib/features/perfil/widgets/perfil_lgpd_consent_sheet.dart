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
      subtitle:
          'Aceite registra a versão ${FocuxLegal.consentDocumentVersion} '
          '(LGPD). Você pode ler o documento antes de confirmar.',
      child: _PerfilLgpdConsentSheet(tipos: tipos),
    ),
  );
}

class _PerfilLgpdConsentSheet extends ConsumerStatefulWidget {
  const _PerfilLgpdConsentSheet({required this.tipos});

  final List<String> tipos;

  @override
  ConsumerState<_PerfilLgpdConsentSheet> createState() =>
      _PerfilLgpdConsentSheetState();
}

class _PerfilLgpdConsentSheetState
    extends ConsumerState<_PerfilLgpdConsentSheet> {
  LgpdConsent? _ultimo;
  final Set<String> _aceitosNaSessao = {};
  var _loading = true;
  String? _erro;
  String? _busyTipo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  bool _foiAceito(String tipo) {
    final key = tipo.toUpperCase();
    if (_aceitosNaSessao.contains(key)) return true;
    return _ultimo?.tipo.toUpperCase() == key;
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final ultimo = await ref.read(lgpdConsentRepositoryProvider).ultimo();
      if (!mounted) return;
      setState(() {
        _ultimo = ultimo;
        if (ultimo != null) {
          _aceitosNaSessao.add(ultimo.tipo.toUpperCase());
        }
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

  Future<void> _abrirDoc(String tipo) async {
    if (tipo == 'TERMOS') {
      await FocuxLegal.openTerms();
    } else if (tipo == 'PRIVACIDADE') {
      await FocuxLegal.openPrivacy();
    }
  }

  Future<void> _registrar(String tipo) async {
    if (_busyTipo != null) return;
    final label = lgpdConsentTipoLabel(tipo);
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Confirmar aceite',
      message:
          'Confirma o aceite de $label (versão '
          '${FocuxLegal.consentDocumentVersion})?',
      confirmLabel: 'Aceitar',
      cancelLabel: 'Cancelar',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyTipo = tipo);
    try {
      await _abrirDoc(tipo);
      final saved = await ref
          .read(lgpdConsentRepositoryProvider)
          .registrar(tipo: tipo);
      if (!mounted) return;
      setState(() {
        _ultimo = saved;
        _aceitosNaSessao.add(tipo.toUpperCase());
        _busyTipo = null;
      });
      FeedbackHelper.showSuccess(
        context,
        '$label aceito · v${saved.versao}',
      );
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
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: TokensStrip.s4),
            child: Center(child: FxLoading()),
          )
        else if (_erro != null)
          Text(
            _erro!,
            style: FocuxHubTypography.bodyMuted(color: mute),
          )
        else
          Text(
            lgpdConsentStatusLine(_ultimo),
            style: FocuxHubTypography.bodyMuted(color: mute),
          ),
        const SizedBox(height: TokensStrip.s3),
        for (final tipo in widget.tipos) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              lgpdConsentTipoLabel(tipo),
              style: FocuxHubTypography.cardTitle(color: ink),
            ),
            subtitle: Text(
              _foiAceito(tipo)
                  ? 'Aceito nesta conta'
                  : 'Toque para ler e confirmar o aceite',
              style: FocuxHubTypography.bodyMuted(color: mute),
            ),
            trailing: _busyTipo == tipo
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: FxLoading(),
                  )
                : _foiAceito(tipo)
                ? Icon(Icons.check_circle_rounded, color: EagleTokens.good, size: 22)
                : Icon(Icons.chevron_right, color: mute, size: 20),
            onTap: _busyTipo != null || _loading
                ? null
                : () => _registrar(tipo),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _busyTipo != null ? null : () => _abrirDoc(tipo),
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Só ler ${lgpdConsentTipoLabel(tipo).toLowerCase()}'),
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
        ],
      ],
    );
  }
}
