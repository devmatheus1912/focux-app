import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../data/avaliacao_repository.dart';
import '../utils/evolucao_comparativo_display.dart';
import '../widgets/evolucao_comparacao_linhas.dart';

class EvolucaoComparativoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const EvolucaoComparativoScreen({
    super.key,
    required this.alunoId,
    this.alunoNome = 'Aluno',
  });
  @override
  ConsumerState<EvolucaoComparativoScreen> createState() =>
      _EvolucaoComparativoScreenState();
}

class _EvolucaoComparativoScreenState
    extends ConsumerState<EvolucaoComparativoScreen> {
  ComparativoEvolucao? _comparativo;
  bool _loading = true;
  String? _erro;
  bool _semAvaliacao = false;
  bool _compartilhando = false;
  bool _registrando = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
      _semAvaliacao = false;
    });
    try {
      final c = await AvaliacaoRepository(
        ref.read(apiClientProvider),
      ).comparativo(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _comparativo = c;
        _loading = false;
      });
    } catch (e) {
      final msg = friendlyError(e);
      if (!mounted) return;
      setState(() {
        if (evolucaoComparativoIsEmptyError(msg)) {
          _semAvaliacao = true;
          _comparativo = null;
        } else {
          _erro = msg;
        }
        _loading = false;
      });
    }
  }


  Future<void> _compartilhar() async {
    if (_compartilhando || _comparativo == null) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: evolucaoComparativoConfirmTitle(),
      message: evolucaoComparativoConfirmMessage(),
      icon: Icons.chat_bubble_outline_rounded,
      confirmLabel: evolucaoComparativoConfirmLabel(),
    );
    if (!ok || !mounted) return;
    setState(() => _compartilhando = true);
    try {
      await EvolucaoRepository(
        ref.read(apiClientProvider),
      ).compartilharEvolucao(widget.alunoId);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      FeedbackHelper.showSuccess(context, 'Evolução compartilhada via chat.');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não deu para compartilhar. Tente de novo.'),
        );
      }
    } finally {
      if (mounted) setState(() => _compartilhando = false);
    }
  }

  Future<void> _registrar() async {
    if (_registrando) return;
    HapticFeedback.selectionClick();
    final peso = TextEditingController();
    final altura = TextEditingController();
    final gordura = TextEditingController();
    final massaMagra = TextEditingController();
    final cintura = TextEditingController();
    var saved = false;
    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova avaliação',
        subtitle: 'Peso é obrigatório. O resto entra se você tiver.',
        icon: Icons.monitor_weight_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: peso,
              label: 'Peso (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: altura,
              label: 'Altura (cm)',
              icon: Icons.height_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: gordura,
              label: '% Gordura',
              icon: Icons.percent_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: massaMagra,
              label: '% Massa magra',
              icon: Icons.fitness_center_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: cintura,
              label: 'Cintura (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      final pesoKg = double.tryParse(peso.text.trim().replaceAll(',', '.'));
      if (pesoKg == null) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Informe o peso em kg.');
        }
        return;
      }
      setState(() => _registrando = true);
      await AvaliacaoRepository(ref.read(apiClientProvider)).registrar(
        widget.alunoId,
        {
          'pesoKg': pesoKg,
          if (altura.text.trim().isNotEmpty)
            'alturaCm': double.tryParse(altura.text.trim().replaceAll(',', '.')),
          if (gordura.text.trim().isNotEmpty)
            'percGordura':
                double.tryParse(gordura.text.trim().replaceAll(',', '.')),
          if (massaMagra.text.trim().isNotEmpty)
            'percMassa':
                double.tryParse(massaMagra.text.trim().replaceAll(',', '.')),
          if (cintura.text.trim().isNotEmpty)
            'cinturaCm':
                double.tryParse(cintura.text.trim().replaceAll(',', '.')),
        },
      );
      saved = true;
      await invalidateAluno360Providers(ref, widget.alunoId);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      peso.dispose();
      altura.dispose();
      gordura.dispose();
      massaMagra.dispose();
      cintura.dispose();
      if (mounted) setState(() => _registrando = false);
    }
    if (saved) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;
    final showSticky = !_loading && _erro == null;
    final empty = _semAvaliacao || _comparativo == null;
    final corpo = Column(
            children: [
              Expanded(
                child:
                    _loading
                        ? const Padding(
                          padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                          child: SkeletonList(count: 4),
                        )
                        : _erro != null
                        ? FxErrorState(
                          chromeOnDark: isDark,
                          primary: primary,
                          message: _erro!,
                          onRetry: _load,
                          title: 'Não conseguimos carregar o comparativo',
                        )
                        : FxContentWidthLimiter(child: _buildBody()),
              ),
              if (showSticky)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    child: FxLiquidPrimaryButton(
                      label:
                          empty
                              ? evolucaoComparativoStickyRegistrar()
                              : evolucaoComparativoStickyShare(),
                      loading: _compartilhando || _registrando,
                      onPressed:
                          empty
                              ? (_registrando ? null : _registrar)
                              : (_compartilhando ? null : _compartilhar),
                    ),
                  ),
                ),
            ],
          );
    return fxScreenA11yScope(
      label: 'Evolução de ${widget.alunoNome}',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: corpo,
      ),
    );
  }

  Widget _buildBody() {
    final chrome = ShellChrome.of(context);
    final c = _comparativo;
    if (c == null || _semAvaliacao) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            TokensStrip.s4,
            FxSettingsLayout.pageInset,
            32,
          ),
          children: [
            FxEmptyState(
              icon: 'trend',
              title: 'Nenhuma avaliação para comparar',
              subtitle:
                  'Registre ao menos duas avaliações físicas para ver a evolução.',
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s4,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        children: [
          Text(
            evolucaoComparativoJanelaCaption(
              primeira: evolucaoComparativoFmtData(c.primeira.avaliadoEm),
              atual: evolucaoComparativoFmtData(c.atual.avaliadoEm),
              dias: evolucaoComparativoDias(c.primeira.avaliadoEm, c.atual.avaliadoEm),
            ),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          EvolucaoComparacaoLinhas(primeira: c.primeira, atual: c.atual),
        ],
      ),
    );
  }
}
