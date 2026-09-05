import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';

/// Setup / status / disable MFA TOTP do Personal.
class MfaSetupScreen extends ConsumerStatefulWidget {
  const MfaSetupScreen({super.key});

  @override
  ConsumerState<MfaSetupScreen> createState() => _MfaSetupScreenState();
}

class _MfaSetupScreenState extends ConsumerState<MfaSetupScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  MfaStatus? _status;
  MfaSetupPayload? _setup;
  bool _recoverySaved = false;

  final _confirmController = TextEditingController();
  final _disablePasswordController = TextEditingController();
  final _disableCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _confirmController.dispose();
    _disablePasswordController.dispose();
    _disableCodeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await ref.read(authProvider.notifier).mfaStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mapMfaSetupError(error);
      });
    }
  }

  Future<void> _beginSetup() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _setup = null;
      _recoverySaved = false;
      _confirmController.clear();
    });
    try {
      final payload = await ref.read(authProvider.notifier).mfaSetup();
      if (!mounted) return;
      setState(() {
        _setup = payload;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapMfaSetupError(error);
      });
    }
  }

  Future<void> _confirm() async {
    if (_busy || _setup == null || !_recoverySaved) return;
    final code = _confirmController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Informe o código de 6 dígitos do autenticador.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).mfaConfirm(code);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _busy = false;
        _setup = null;
        _confirmController.clear();
      });
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MFA ativado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapMfaSetupError(error);
      });
    }
  }

  Future<void> _disable() async {
    if (_busy) return;
    final senha = _disablePasswordController.text;
    final code = _disableCodeController.text.trim();
    if (senha.isEmpty || code.isEmpty) {
      setState(() => _error = 'Informe senha e código para desativar.');
      return;
    }
    final ok = await showFxConfirmSheet(
      context,
      title: 'Desativar MFA?',
      message:
          'Sua conta ficará só com e-mail/senha (e Google/Apple). Continuar?',
      confirmLabel: 'Desativar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .mfaDisable(senha: senha, code: code);
      if (!mounted) return;
      _disablePasswordController.clear();
      _disableCodeController.clear();
      setState(() => _busy = false);
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MFA desativado.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = mapMfaSetupError(error);
      });
    }
  }

  Future<void> _copy(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copiado.')),
    );
  }

  void _pop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/perfil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mute =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    final line = Theme.of(context).dividerColor;

    return fxScreenA11yScope(
      label: 'Autenticação em duas etapas',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Autenticação em duas etapas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _pop,
          ),
        ),
        body:
            _loading
                ? const Center(child: FxLoading())
                : ListView(
                  padding: const EdgeInsets.all(FxSettingsLayout.pageInset),
                  children: [
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: const TextStyle(color: EagleTokens.bad),
                      ),
                      const SizedBox(height: TokensStrip.s3),
                    ],
                    FxSettingsGroup(
                      header: 'Status',
                      children: [
                        FxSettingsTile(
                          icon: Icons.phonelink_lock_outlined,
                          label: 'MFA TOTP',
                          value:
                              _status?.enabled == true
                                  ? 'Ativo'
                                  : 'Desativado',
                          mute: mute,
                          line: line,
                          showDivider: _status?.enabled == true,
                        ),
                        if (_status?.enabled == true)
                          FxSettingsTile(
                            icon: Icons.vpn_key_outlined,
                            label: 'Códigos de recuperação',
                            value:
                                '${_status!.recoveryCodesRemaining} restantes',
                            mute: mute,
                            line: line,
                            showDivider: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    if (_status?.enabled != true) ...[
                      if (_setup == null)
                        FxLiquidPrimaryButton(
                          label: 'Ativar autenticador',
                          loading: _busy,
                          loadingLabel: 'Gerando…',
                          onPressed: _busy ? null : _beginSetup,
                        )
                      else ...[
                        Text(
                          'Escaneie o QR no autenticador (ou digite o secret).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(12),
                            child: QrImageView(
                              data: _setup!.otpauthUri,
                              size: 200,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          _setup!.secret,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _copy(_setup!.secret, 'Secret'),
                          child: const Text('Copiar secret'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Códigos de recuperação (salve agora — só aparecem uma vez):',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ..._setup!.recoveryCodes.map(
                          (code) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: SelectableText(
                              code,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              () => _copy(
                                _setup!.recoveryCodes.join('\n'),
                                'Códigos',
                              ),
                          child: const Text('Copiar códigos'),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _recoverySaved,
                          onChanged:
                              _busy
                                  ? null
                                  : (v) => setState(
                                    () => _recoverySaved = v ?? false,
                                  ),
                          title: const Text(
                            'Guardei os códigos de recuperação em local seguro',
                          ),
                        ),
                        TextField(
                          controller: _confirmController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !_busy && _recoverySaved,
                          decoration: const InputDecoration(
                            labelText: 'Código do autenticador',
                            counterText: '',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                        const SizedBox(height: 12),
                        FxLiquidPrimaryButton(
                          label: 'Confirmar e ativar',
                          loading: _busy,
                          loadingLabel: 'Confirmando…',
                          onPressed:
                              (_busy || !_recoverySaved) ? null : _confirm,
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Para desativar, confirme com sua senha e um código do autenticador (ou recovery).',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _disablePasswordController,
                        obscureText: true,
                        enabled: !_busy,
                        decoration: const InputDecoration(labelText: 'Senha'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _disableCodeController,
                        enabled: !_busy,
                        decoration: const InputDecoration(
                          labelText: 'Código MFA ou recovery',
                        ),
                      ),
                      const SizedBox(height: 16),
                      FxLiquidPrimaryButton(
                        label: 'Desativar MFA',
                        loading: _busy,
                        loadingLabel: 'Desativando…',
                        onPressed: _busy ? null : _disable,
                      ),
                    ],
                  ],
                ),
      ),
    );
  }
}
