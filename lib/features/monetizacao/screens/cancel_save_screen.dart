import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/planos/paywall/paywall_catalog.dart';
import '../../../features/planos/paywall/paywall_components.dart';
import '../../../features/subscription/store_subscription_policy.dart';
import '../data/cancel_save_repository.dart';

class CancelSaveScreen extends ConsumerStatefulWidget {
  const CancelSaveScreen({super.key});

  @override
  ConsumerState<CancelSaveScreen> createState() => _CancelSaveScreenState();
}

class _CancelSaveScreenState extends ConsumerState<CancelSaveScreen> {
  static const _motivos = <_Motivo>[
    _Motivo('MUITO_CARO', 'Está caro demais agora', Icons.attach_money_rounded),
    _Motivo(
      'NAO_USO',
      'Não estou usando o suficiente',
      Icons.timelapse_rounded,
    ),
    _Motivo(
      'FALTA_FUNCIONALIDADE',
      'Faltou uma funcionalidade que preciso',
      Icons.extension_outlined,
    ),
    _Motivo(
      'MUDANDO_FERRAMENTA',
      'Vou usar outra ferramenta',
      Icons.swap_horiz_rounded,
    ),
    _Motivo('OUTRO', 'Outro motivo', Icons.help_outline_rounded),
  ];

  String? _motivoSelecionado;
  CancelSaveOferta? _oferta;
  bool _carregandoOferta = false;
  String? _erroOferta;
  bool _enviando = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    unawaited(AnalyticsService.instance.track(ProductEvents.cancelSaveOpened));
  }

  Future<void> _selecionarMotivo(String motivo) async {
    HapticFeedback.selectionClick();
    setState(() {
      _motivoSelecionado = motivo;
      _carregandoOferta = true;
      _oferta = null;
      _erroOferta = null;
    });
    try {
      final oferta = await ref
          .read(cancelSaveRepositoryProvider)
          .oferta(motivo);
      if (!mounted) return;
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.cancelSaveMotivoSelected,
          props: {'motivo': motivo, 'oferta': oferta.tipo},
        ),
      );
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.cancelSaveOfertaLoaded,
          props: {
            'motivo': motivo,
            'oferta': oferta.tipo,
            'billingChannel': oferta.billingChannel,
          },
        ),
      );
      setState(() {
        _oferta = oferta;
        _carregandoOferta = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoOferta = false;
        _erroOferta = friendlyError(
          e,
          fallback:
              'Não foi possível carregar a alternativa agora. Tente de novo.',
        );
      });
    }
  }

  Future<void> _responder(bool aceitar) async {
    if (_motivoSelecionado == null || _oferta == null) return;
    HapticFeedback.lightImpact();
    setState(() => _enviando = true);
    try {
      final resposta = await ref
          .read(cancelSaveRepositoryProvider)
          .responder(
            motivo: _motivoSelecionado!,
            ofertaApresentada: _oferta!.tipo,
            aceitar: aceitar,
            feedback: _feedback,
          );
      if (!mounted) return;

      unawaited(
        AnalyticsService.instance.track(
          aceitar
              ? ProductEvents.cancelSaveOfertaAccepted
              : ProductEvents.cancelSaveOfertaDeclined,
          props: {
            'motivo': _motivoSelecionado,
            'oferta': _oferta!.tipo,
            'billingApplied': resposta.billingApplied,
            'requiresStoreAction': resposta.requiresStoreAction,
          },
        ),
      );

      if (aceitar &&
          (resposta.requiresStoreAction || _oferta!.requiresStoreAction) &&
          subscriptionUsesNativeStore) {
        await openNativeSubscriptionManagement();
      }

      if (!mounted) return;
      _showResultado(resposta);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(
          e,
          fallback:
              'Não foi possível concluir agora. Tente novamente em instantes.',
        ),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _showResultado(CancelSaveResposta r) async {
    await showFxNoticeSheet(
      context,
      title: r.aceita ? 'Oferta registrada' : 'Cancelamento registrado',
      message: r.mensagem,
      icon: r.aceita ? Icons.celebration_rounded : Icons.exit_to_app_rounded,
      actionLabel: 'Continuar',
    );
    if (!mounted) return;
    if (r.aceita) {
      context.go('/assinatura');
    } else {
      context.go('/dashboard/personal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = theme.colorScheme.primary;
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );

    return fxScreenA11yScope(
      label: 'Antes de cancelar a assinatura',
      child: FxKeyboardPopScope(
        child: FxShellScaffold(
          useMesh: true,
          appBar: const FxShellAppBar(
            title: 'Antes de cancelar…',
            fallbackLocation: '/assinatura',
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              TokensStrip.s5,
              TokensStrip.s2,
              TokensStrip.s5,
              TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            children: [
              Text(
                'Que pena que você quer ir embora.',
                style: TokensStrip.h2(color: ink),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                'Selecione um motivo — mostramos uma alternativa personalizada aqui embaixo.',
                style: TokensStrip.bodyMuted(
                  color: secondary,
                ).copyWith(fontSize: TokensStrip.fontBodySm, height: 1.45),
              ),
              const SizedBox(height: TokensStrip.s5),
              for (final m in _motivos) ...[
                _MotivoTile(
                  motivo: m,
                  selected: _motivoSelecionado == m.codigo,
                  ink: ink,
                  mute: mute,
                  primary: primary,
                  isDark: isDark,
                  onTap: () => _selecionarMotivo(m.codigo),
                ),
                const SizedBox(height: TokensStrip.s2),
              ],
              const SizedBox(height: TokensStrip.s2),
              AnimatedSwitcher(
                duration:
                    TokensStrip.prefersReducedMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child:
                    _carregandoOferta
                        ? const Padding(
                          key: ValueKey('loading'),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SkeletonList(count: 3),
                        )
                        : _erroOferta != null
                        ? Padding(
                          key: const ValueKey('error'),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: FxErrorState(
                            chromeOnDark: isDark,
                            primary: primary,
                            message: _erroOferta!,
                            title: 'Alternativa indisponível',
                            onRetry:
                                () => _selecionarMotivo(_motivoSelecionado!),
                          ),
                        )
                        : _oferta != null
                        ? _OfertaCard(
                          key: ValueKey(_oferta!.tipo),
                          oferta: _oferta!,
                          enviando: _enviando,
                          ink: ink,
                          mute: mute,
                          primary: primary,
                          isDark: isDark,
                          onAceitar: () => _responder(true),
                          onRecusar: () => _responder(false),
                          onFeedback: (txt) => _feedback = txt,
                        )
                        : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivoTile extends StatelessWidget {
  const _MotivoTile({
    required this.motivo,
    required this.selected,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final _Motivo motivo;
  final bool selected;
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: motivo.label,
      child: Material(
        color: TokensStrip.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected
                        ? primary
                        : TokensStrip.borderDefault.withValues(
                          alpha: isDark ? 0.5 : 1,
                        ),
                width: selected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  motivo.icone,
                  size: 22,
                  color: selected ? primary : secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    motivo.label,
                    style: TokensStrip.body(color: ink).copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfertaCard extends StatelessWidget {
  const _OfertaCard({
    super.key,
    required this.oferta,
    required this.onAceitar,
    required this.onRecusar,
    required this.onFeedback,
    required this.enviando,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.isDark,
  });

  final CancelSaveOferta oferta;
  final VoidCallback onAceitar;
  final VoidCallback onRecusar;
  final ValueChanged<String> onFeedback;
  final bool enviando;
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return PaywallInsetPanel(
      accent: primary,
      isDark: isDark,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_offer_outlined,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      oferta.titulo,
                      style: TokensStrip.body(color: ink).copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        height: 1.25,
                      ),
                    ),
                    if (oferta.requiresStoreAction) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Conclusão na ${subscriptionChannelLabel()}',
                        style: TokensStrip.bodyMuted(
                          color: secondary,
                        ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            oferta.descricao,
            style: TokensStrip.bodyMuted(
              color: secondary,
            ).copyWith(fontSize: 14, height: 1.45),
          ),
          const SizedBox(height: 16),
          TextField(
            maxLines: 3,
            maxLength: 2000,
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            decoration: FxInputDeco.build(
              context,
              'Feedback (opcional)',
              hint: 'Conte o que faltou ou o que podemos melhorar',
            ).copyWith(
              counterStyle: TokensStrip.bodyMuted(
                color: secondary,
              ).copyWith(fontSize: 11),
            ),
            onChanged: onFeedback,
          ),
          const SizedBox(height: 16),
          FxLiquidPrimaryButton(
            label: oferta.ctaLabel,
            icon: Icons.check_rounded,
            loading: enviando,
            loadingLabel: 'Salvando…',
            onPressed: enviando ? null : onAceitar,
          ),
          const SizedBox(height: 10),
          FxConversionTextLink(
            text: '',
            actionText: 'Cancelar mesmo assim',
            onTap: enviando ? null : onRecusar,
            actionColor: primary,
          ),
        ],
      ),
    );
  }
}

class _Motivo {
  const _Motivo(this.codigo, this.label, this.icone);
  final String codigo;
  final String label;
  final IconData icone;
}
