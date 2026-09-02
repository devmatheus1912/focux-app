import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../data/avaliacao_repository.dart';
import '../utils/evolucao_comparativo_display.dart';
import '../widgets/evolucao_comparativo_table.dart';

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
      final eh404 = msg.contains('404') || msg.contains('Not Found');
      if (!mounted) return;
      setState(() {
        if (eh404) {
          _semAvaliacao = true;
        } else {
          _erro = msg;
        }
        _loading = false;
      });
    }
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Comparativo',
      subtitle: evolucaoComparativoHubSubtitle(),
      tips: const [
        FxHelpTip(
          'Janela',
          'Primeira e última avaliação física do aluno. A tabela não mistura outras métricas.',
          icon: 'trend',
        ),
        FxHelpTip(
          'Delta',
          'Verde é melhora no sentido da métrica. Vermelho é piora. Cinza não mudou.',
          icon: 'target',
        ),
        FxHelpTip(
          'Chat',
          'Compartilhar envia um resumo na conversa. Confirme antes — o aluno vê a mensagem.',
          icon: 'message-circle',
        ),
      ],
    );
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
      FeedbackHelper.showSuccess(
        context,
        'Evolução compartilhada via chat.',
      );
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

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final canShare = !_loading && _comparativo != null && !_compartilhando;
    return fxScreenA11yScope(
      label: 'Evolução de ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Evolução de ${widget.alunoNome}',
          subtitle: evolucaoComparativoHubSubtitle(),
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(tooltip: 'Como comparar', onTap: _showHelp),
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s3),
              child: Center(
                child: Semantics(
                  button: true,
                  enabled: canShare,
                  label:
                      _compartilhando
                          ? 'Enviando resumo da evolução'
                          : evolucaoComparativoShareTooltip(),
                  child: ShellHeaderIconButton(
                    icon: 'message-circle',
                    tooltip: evolucaoComparativoShareTooltip(),
                    onTap: canShare ? _compartilhar : () {},
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FxPremiumEntrance(
          child: _loading
              ? const SkeletonList(count: 4)
              : _erro != null
              ? FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: _erro!,
                onRetry: _load,
                title: 'Não conseguimos carregar o comparativo',
              )
              : _semAvaliacao
              ? FxEmptyState(
                icon: 'trend',
                title: 'Nenhuma avaliação para comparar',
                subtitle:
                    'Registre ao menos duas avaliações físicas para ver a evolução.',
                action: FxEmptyAction(
                  label: 'Voltar ao Aluno 360',
                  onTap:
                      () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
                ),
              )
              : _buildConteudo(_comparativo!),
        ),
      ),
    );
  }

  Widget _buildConteudo(ComparativoEvolucao c) {
    final chrome = ShellChrome.of(context);
    return FxContentWidthLimiter(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EvolucaoComparativoTable(primeira: c.primeira, atual: c.atual),
            const SizedBox(height: TokensStrip.s3),
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: EagleTokens.good),
                const SizedBox(width: 4),
                Text(
                  'Melhora',
                  style: TextStyle(fontSize: 12, color: chrome.mute),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.circle, size: 10, color: EagleTokens.bad),
                const SizedBox(width: 4),
                Text(
                  'Piora',
                  style: TextStyle(fontSize: 12, color: chrome.mute),
                ),
                const SizedBox(width: 12),
                Icon(Icons.circle, size: 10, color: chrome.mute),
                const SizedBox(width: 4),
                Text(
                  'Sem alteração',
                  style: TextStyle(fontSize: 12, color: chrome.mute),
                ),
              ],
            ),
            const SizedBox(height: TokensStrip.s4),
            FxSettingsGroup(
              caption: evolucaoComparativoJanelaCaption(
                primeira: evolucaoComparativoFmtData(c.primeira.avaliadoEm),
                atual: evolucaoComparativoFmtData(c.atual.avaliadoEm),
              ),
              children: [
                FxSettingsTile(
                  fxIcon: 'message-circle',
                  label: evolucaoComparativoShareTileLabel(),
                  value:
                      _compartilhando
                          ? 'Enviando…'
                          : evolucaoComparativoShareTileValue(),
                  onTap: _compartilhando ? () {} : _compartilhar,
                  showDivider: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
