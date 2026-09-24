import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/personal_slug_store.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../auth/widgets/auth_shell.dart';
import '../providers/convite_provider.dart';

/// Universal Link / custom scheme → valida token e abre register/aluno.
class ConviteDeepLinkScreen extends ConsumerStatefulWidget {
  const ConviteDeepLinkScreen({
    super.key,
    required this.token,
    this.initialSlug,
  });

  final String token;
  final String? initialSlug;

  @override
  ConsumerState<ConviteDeepLinkScreen> createState() =>
      _ConviteDeepLinkScreenState();
}

class _ConviteDeepLinkScreenState extends ConsumerState<ConviteDeepLinkScreen> {
  String? _erro;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _validar());
  }

  Future<void> _validar() async {
    final token = widget.token.trim();
    if (token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _erro = 'Convite inválido ou incompleto.';
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final result = await ref.read(conviteRepositoryProvider).validar(token);
      if (!mounted) return;
      if (!result.valido) {
        setState(() {
          _erro =
              (result.mensagem?.trim().isNotEmpty == true)
                  ? result.mensagem!.trim()
                  : 'Este convite expirou ou já foi usado.';
          _loading = false;
        });
        return;
      }

      final slug =
          (result.personalSlug?.trim().isNotEmpty == true)
              ? result.personalSlug!.trim()
              : widget.initialSlug?.trim();
      if (slug != null && slug.isNotEmpty) {
        await PersonalSlugStore.save(slug);
      }
      final params = <String, String>{'token': token};
      if (slug != null && slug.isNotEmpty) params['p'] = slug;
      final dica = result.emailDica?.trim();
      if (dica != null && dica.isNotEmpty) params['e'] = dica;
      if (!mounted) return;
      context.go(
        Uri(path: '/register/aluno', queryParameters: params).toString(),
      );
    } catch (e) {
      if (!mounted) return;
      final status = e is DioException ? e.response?.statusCode : null;
      setState(() {
        _erro =
            status == 404
                ? 'Convite não encontrado ou expirado.'
                : friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Abrindo convite',
      child: Scaffold(
        body: AuthShell(
          child: Center(
            child:
                _loading
                    ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FxLoading(),
                        SizedBox(height: TokensStrip.s4),
                        Text('Validando convite…'),
                      ],
                    )
                    : Padding(
                      padding: const EdgeInsets.all(TokensStrip.s5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FxErrorState(
                            chromeOnDark: true,
                            primary: primary,
                            title: 'Não foi possível abrir o convite',
                            message: _erro ?? 'Tente de novo.',
                            onRetry: _validar,
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          FxLiquidPrimaryButton(
                            label: 'Criar conta sem este link',
                            onPressed: () => context.go('/register/aluno'),
                          ),
                          const SizedBox(height: TokensStrip.s2),
                          TextButton(
                            onPressed: () async {
                              final slug =
                                  widget.initialSlug?.trim().isNotEmpty == true
                                      ? widget.initialSlug!.trim()
                                      : await PersonalSlugStore.read();
                              if (!context.mounted) return;
                              final params = <String, String>{'role': 'aluno'};
                              if (slug != null && slug.isNotEmpty) {
                                params['p'] = slug;
                              }
                              context.go(
                                Uri(
                                  path: '/login',
                                  queryParameters: params,
                                ).toString(),
                              );
                            },
                            child: const Text('Já tenho conta — Entrar'),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
