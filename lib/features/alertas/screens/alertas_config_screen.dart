import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class AlertasConfigScreen extends ConsumerStatefulWidget {
  const AlertasConfigScreen({super.key});

  @override
  ConsumerState<AlertasConfigScreen> createState() =>
      _AlertasConfigScreenState();
}

class _AlertasConfigScreenState extends ConsumerState<AlertasConfigScreen> {
  bool _loading = true;
  bool _salvando = false;
  String? _erro;

  int _diasSemTreino = 7;
  int _aderenciaMinima = 50;

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
      final repo = AlertasRepository(ref.read(apiClientProvider));
      final config = await repo.getConfiguracao();
      if (mounted) {
        setState(() {
          _diasSemTreino = config.diasSemTreino;
          _aderenciaMinima = config.aderenciaMinima;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final repo = AlertasRepository(ref.read(apiClientProvider));
      await repo.atualizarConfiguracao(_diasSemTreino, _aderenciaMinima);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Configurações salvas com sucesso!',
        );
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
    final chrome = ShellChrome.of(context);

    return fxScreenA11yScope(
      label: 'Configurar Alertas',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Configurar Alertas',
          onBack: () => safePopOrGo(context, '/alertas'),
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: SkeletonList(count: 6),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                )
                : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DecoratedBox(
                        decoration: fxListCardDecoration(
                          context,
                          accent: primary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dias sem treino',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_diasSemTreino dias',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: primary,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alerta quando o aluno não treina por X dias consecutivos',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: chrome.mute,
                                ),
                              ),
                              Slider(
                                value: _diasSemTreino.toDouble(),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                label: '$_diasSemTreino dias',
                                onChanged:
                                    (v) => setState(
                                      () => _diasSemTreino = v.toInt(),
                                    ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '1 dia',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: chrome.mute,
                                    ),
                                  ),
                                  Text(
                                    '30 dias',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: chrome.mute,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      DecoratedBox(
                        decoration: fxListCardDecoration(
                          context,
                          accent: EagleTokens.warn,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.trending_down_outlined,
                                    color: EagleTokens.warn,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Aderência mínima (%)',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: EagleTokens.warn.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_aderenciaMinima%',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: EagleTokens.warn,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alerta quando a taxa de aderência cair abaixo deste valor',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: chrome.mute,
                                ),
                              ),
                              Slider(
                                value: _aderenciaMinima.toDouble(),
                                min: 10,
                                max: 90,
                                divisions: 16,
                                label: '$_aderenciaMinima%',
                                activeColor: EagleTokens.warn,
                                onChanged:
                                    (v) => setState(
                                      () => _aderenciaMinima = v.toInt(),
                                    ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '10%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: chrome.mute,
                                    ),
                                  ),
                                  Text(
                                    '90%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: chrome.mute,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      FxLiquidPrimaryButton(
                        label: 'Salvar',
                        loading: _salvando,
                        onPressed: _salvando ? null : _salvar,
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
