import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../router/app_router.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_icons.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import '../widgets/fx_confirm_sheet.dart';
import '../widgets/fx_motion.dart';
import '../widgets/fx_tonal_button.dart';
import 'app_versao.dart';

/// Versões que o servidor pede para a plataforma deste aparelho.
class VersaoDaLoja {
  const VersaoDaLoja({this.minima, this.recomendada, this.lojaUrl});

  final String? minima;
  final String? recomendada;
  final String? lojaUrl;

  factory VersaoDaLoja.fromJson(Map<String, dynamic> j) => VersaoDaLoja(
    minima: j['minima'] as String?,
    recomendada: j['recomendada'] as String?,
    lojaUrl: j['lojaUrl'] as String?,
  );
}

/// Na abertura e ao voltar do segundo plano (no máximo a cada 6 h) confere a
/// versão: abaixo da mínima, tela de bloqueio; abaixo da recomendada, folha
/// "Nova versão disponível" uma vez por versão. Sem rede ou com o servidor
/// fora, não bloqueia nada.
class AtualizacaoScope extends ConsumerStatefulWidget {
  const AtualizacaoScope({super.key, required this.child});

  final Widget child;

  static const intervalo = Duration(hours: 6);
  static const chaveDispensada = 'versao_recomendada_dispensada';

  /// Toque no push "Nova versão do Focux": confere agora, sem esperar 6 h.
  static void verificarAgora() =>
      _AtualizacaoScopeState._ativo?._verificar(forcar: true);

  @override
  ConsumerState<AtualizacaoScope> createState() => _AtualizacaoScopeState();
}

class _AtualizacaoScopeState extends ConsumerState<AtualizacaoScope>
    with WidgetsBindingObserver {
  static _AtualizacaoScopeState? _ativo;

  DateTime? _ultima;
  VersaoDaLoja? _loja;
  bool _bloqueado = false;
  bool _folhaAberta = false;

  @override
  void initState() {
    super.initState();
    _ativo = this;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificar());
  }

  @override
  void dispose() {
    if (_ativo == this) _ativo = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _verificar();
  }

  Future<void> _verificar({bool forcar = false}) async {
    if (kIsWeb || AppInfo.versao == null || AppInfo.plataforma == null) return;
    final agora = DateTime.now();
    final ultima = _ultima;
    if (!forcar &&
        !_bloqueado &&
        ultima != null &&
        agora.difference(ultima) < AtualizacaoScope.intervalo) {
      return;
    }
    _ultima = agora;
    VersaoDaLoja loja;
    try {
      final r = await ref
          .read(apiClientProvider)
          .dio
          .get(
            '/api/public/app/versao',
            queryParameters: {'plataforma': AppInfo.plataforma},
          );
      loja = VersaoDaLoja.fromJson(r.data as Map<String, dynamic>);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final decisao = decidirAtualizacao(
      atual: AppInfo.versao!,
      minima: loja.minima,
      recomendada: loja.recomendada,
    );
    setState(() {
      _loja = loja;
      _bloqueado = decisao == AtualizacaoNecessaria.obrigatoria;
    });
    if (decisao == AtualizacaoNecessaria.recomendada) {
      await _oferecer(loja, forcar: forcar);
    }
  }

  Future<void> _oferecer(VersaoDaLoja loja, {required bool forcar}) async {
    final recomendada = loja.recomendada;
    if (recomendada == null || _folhaAberta) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!forcar &&
          prefs.getString(AtualizacaoScope.chaveDispensada) == recomendada) {
        return;
      }
      final ctx = AppRouter.router.routerDelegate.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      _folhaAberta = true;
      final atualizar = await showFxConfirmSheetOuFechar(
        ctx,
        title: 'Nova versão disponível',
        message:
            'A versão $recomendada do Focux já está na loja, com correções e novidades.',
        icon: FxIcons.atualizar,
        confirmLabel: 'Atualizar',
        cancelLabel: 'Agora não',
      );
      _folhaAberta = false;
      // "Agora não" ou fechar: a folha volta só na próxima versão.
      await prefs.setString(AtualizacaoScope.chaveDispensada, recomendada);
      if (atualizar == true) await _atualizar(imediata: false);
    } catch (_) {
      _folhaAberta = false;
    }
  }

  /// Android: atualização dentro do app (Play); senão, abre a loja.
  Future<void> _atualizar({required bool imediata}) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (imediata) {
            await InAppUpdate.performImmediateUpdate();
          } else {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
          }
          return;
        }
      } catch (_) {
        // Sem Play (instalação de fora, emulador): cai na loja.
      }
    }
    final url = _loja?.lojaUrl;
    if (url == null) return;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_bloqueado) return widget.child;
    return _TelaAtualizar(
      versao: _loja?.minima,
      onAtualizar: () => _atualizar(imediata: true),
      onSair:
          ref.read(authProvider) == AuthStatus.authenticated
              ? () => ref.read(authProvider.notifier).logout()
              : null,
    );
  }
}

/// Abaixo da mínima: só atualizar (e sair da conta, que continua à mão).
class _TelaAtualizar extends StatelessWidget {
  const _TelaAtualizar({
    required this.versao,
    required this.onAtualizar,
    this.onSair,
  });

  final String? versao;
  final VoidCallback onAtualizar;
  final VoidCallback? onSair;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(FxIcons.atualizar, size: 40, color: primary),
              const SizedBox(height: TokensStrip.s4),
              Text(
                'Atualize o Focux para continuar',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                versao == null
                    ? 'Esta versão não funciona mais. A nova está na loja.'
                    : 'Esta versão não funciona mais. Instale a $versao ou mais nova na loja.',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const Spacer(),
              FxLiquidPrimaryButton(
                label: 'Atualizar agora',
                onPressed: onAtualizar,
              ),
              if (onSair != null) ...[
                const SizedBox(height: TokensStrip.s2),
                FxTonalButton(
                  label: 'Sair da conta',
                  expanded: true,
                  onPressed: onSair,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
