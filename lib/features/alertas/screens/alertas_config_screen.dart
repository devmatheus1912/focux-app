import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';
import '../widgets/alertas_config_help_sheet.dart';

class AlertasConfigScreen extends ConsumerStatefulWidget {
  const AlertasConfigScreen({super.key});

  @override
  ConsumerState<AlertasConfigScreen> createState() =>
      _AlertasConfigScreenState();
}

class _AlertasConfigScreenState extends ConsumerState<AlertasConfigScreen> {
  final _openedAt = DateTime.now();
  var _loading = true;
  var _salvando = false;
  var _viewTracked = false;
  String? _erro;
  var _diasSemTreino = 7;
  var _aderenciaMinima = 60;
  var _salvoDias = 7;
  var _salvoAderencia = 60;

  bool get _dirty =>
      _diasSemTreino != _salvoDias || _aderenciaMinima != _salvoAderencia;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final config = await AlertasRepository(
        ref.read(apiClientProvider),
      ).getConfiguracao();
      if (!mounted) return;
      setState(() {
        _diasSemTreino = config.diasSemTreino;
        _aderenciaMinima = config.aderenciaMinima;
        _salvoDias = config.diasSemTreino;
        _salvoAderencia = config.aderenciaMinima;
        _loading = false;
      });
      _trackView();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _trackView() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(ProductEvents.alertasConfigViewed);
    AnalyticsService.instance.track(
      ProductEvents.alertasConfigTtv,
      props: {'ms': DateTime.now().difference(_openedAt).inMilliseconds},
    );
  }

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar alterações?',
        message: 'Os limiares novos não serão salvos.',
        confirmLabel: 'Descartar',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/alertas');
  }

  Future<void> _salvar() async {
    if (_salvando || !_dirty) return;
    setState(() => _salvando = true);
    try {
      final saved = await AlertasRepository(
        ref.read(apiClientProvider),
      ).atualizarConfiguracao(_diasSemTreino, _aderenciaMinima);
      if (!mounted) return;
      AnalyticsService.instance.track(
        ProductEvents.alertasConfigSaved,
        props: {
          'dias': saved.diasSemTreino,
          'aderencia': saved.aderenciaMinima,
        },
      );
      FeedbackHelper.showSuccess(context, 'Limiares salvos.');
      if (context.canPop()) {
        context.pop(true);
      } else {
        safePopOrGo(context, '/alertas');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return fxScreenA11yScope(
      label: 'Quando dispara',
      child: FxFormPopGuard(
        dirty: _dirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Quando dispara',
            subtitle: 'Limiares da caixa de alertas',
            onBack: _cancel,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar os limiares',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.alertasConfigHelpOpened,
                  );
                  showAlertasConfigHelpSheet(context);
                },
              ),
            ],
          ),
          bottomNavigationBar:
              !_dirty || _loading || _erro != null
                  ? null
                  : FxFormStickyBar(
                    child: FxLiquidPrimaryButton(
                      label: 'Salvar',
                      loading: _salvando,
                      loadingLabel: 'Salvando…',
                      onPressed: _salvando ? null : _salvar,
                    ),
                  ),
          body: _loading
              ? const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 6),
              )
              : _erro != null
              ? FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: _erro!,
                onRetry: _load,
              )
              : ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  8,
                  FxSettingsLayout.pageInset,
                  32,
                ),
                children: [
                  FxSettingsGroup(
                    header: 'Sem treino',
                    caption:
                        'Alerta se o último treino passou deste prazo.',
                    children: [
                      _LimiarSlider(
                        label: '$_diasSemTreino dias',
                        value: _diasSemTreino.toDouble(),
                        min: 1,
                        max: 90,
                        divisions: 89,
                        onChanged: (v) =>
                            setState(() => _diasSemTreino = v.round()),
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Aderência',
                    caption:
                        'Alerta se os check-ins concluídos dos últimos 30 dias caírem abaixo.',
                    children: [
                      _LimiarSlider(
                        label: '$_aderenciaMinima%',
                        value: _aderenciaMinima.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 18,
                        onChanged: (v) =>
                            setState(() => _aderenciaMinima = v.round()),
                      ),
                    ],
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _LimiarSlider extends StatelessWidget {
  const _LimiarSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: FxSettingsLayout.rowLabel(color: Theme.of(context).colorScheme.onSurface)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: label,
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.round()}', style: FxSettingsLayout.footer(color: mute)),
            Text('${max.round()}', style: FxSettingsLayout.footer(color: mute)),
          ],
        ),
      ],
    );
  }
}
