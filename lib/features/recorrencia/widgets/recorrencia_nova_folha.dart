import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../financeiro/utils/pix_qr_display.dart';
import '../../financeiro/widgets/financeiro_aluno_etapa.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';
import '../utils/recorrencia_sugestao.dart';
import '../../financeiro/widgets/dia_vencimento_grade.dart';

/// Folha curta de "Nova recorrência", usada pela lista e pelo perfil 360.
/// Com [alunoId] a pessoa já vem escolhida. Devolve `true` se criou.
Future<bool> showRecorrenciaNovaFolha(
  BuildContext context,
  WidgetRef ref, {
  int? alunoId,
  String? alunoNome,
}) async {
  HapticFeedback.selectionClick();
  List<Aluno> alunos = const [];
  if (alunoId == null) {
    try {
      final home = await ref.read(alunosHomeProvider.future);
      alunos = filterAlunoPickerAlunos(home.alunos, '');
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
      return false;
    }
    if (alunos.isEmpty) {
      if (context.mounted) {
        FeedbackHelper.showWarn(context, 'Cadastre um aluno primeiro.');
      }
      return false;
    }
  }
  if (!context.mounted) return false;

  final criou = await showFxHomeSheet<bool>(
    context,
    builder:
        (ctx) => _NovaRecorrenciaSheet(
          ref: ref,
          alunos: alunos,
          alunoId: alunoId,
          alunoNome: alunoNome,
        ),
  );
  return criou ?? false;
}

class _NovaRecorrenciaSheet extends StatefulWidget {
  const _NovaRecorrenciaSheet({
    required this.ref,
    required this.alunos,
    this.alunoId,
    this.alunoNome,
  });

  final WidgetRef ref;
  final List<Aluno> alunos;
  final int? alunoId;
  final String? alunoNome;

  @override
  State<_NovaRecorrenciaSheet> createState() => _NovaRecorrenciaSheetState();
}

class _NovaRecorrenciaSheetState extends State<_NovaRecorrenciaSheet> {
  final _valorCtrl = TextEditingController();
  late int? _alunoId = widget.alunoId;
  late String? _alunoNome = widget.alunoNome;
  late int _dia = recorrenciaDiaPadrao(DateTime.now());
  var _salvando = false;

  /// A busca de aluno troca o conteúdo da própria folha, sem abrir outra por cima.
  var _escolhendoAluno = false;

  @override
  void initState() {
    super.initState();
    _valorCtrl.addListener(() => setState(() {}));
    final id = _alunoId;
    if (id != null) _sugerirValor(id);
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  /// Sugere o valor da última mensalidade; nunca sobrescreve o que foi digitado.
  Future<void> _sugerirValor(int alunoId) async {
    try {
      final page = await FinanceiroRepository(
        widget.ref.read(apiClientProvider),
      ).listarPagina(alunoId: alunoId, size: 1);
      final sugerido = recorrenciaValorSugerido(
        page.mensalidades.isEmpty ? null : page.mensalidades.first.valor,
      );
      if (!mounted || sugerido == null || _valorCtrl.text.trim().isNotEmpty) {
        return;
      }
      _valorCtrl.text = sugerido.wire;
    } catch (_) {}
  }

  void _escolherAluno(Aluno escolhido) {
    setState(() {
      _alunoId = escolhido.id;
      _alunoNome = escolhido.nome;
      _escolhendoAluno = false;
    });
    _sugerirValor(escolhido.id);
  }

  Future<void> _escolherDia() async {
    final picked = await showDiaVencimentoSheet(
      context,
      titulo: S.of(context).recorrenciaDia,
      selecionado: _dia,
      maximo: recorrenciaDiaMaximo,
    );
    if (picked != null && mounted) setState(() => _dia = picked);
  }

  Future<void> _criar() async {
    final s = S.of(context);
    final id = _alunoId;
    if (id == null) {
      FeedbackHelper.showError(context, s.recorrenciaErroAluno);
      return;
    }
    final valor = recorrenciaLerValor(_valorCtrl.text);
    if (valor == null) {
      FeedbackHelper.showError(context, s.recorrenciaErroValor);
      return;
    }
    setState(() => _salvando = true);
    try {
      await RecorrenciaRepository(
        widget.ref.read(apiClientProvider),
      ).criar(alunoId: id, valor: valor, diaVencimento: _dia);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      FeedbackHelper.showError(context, friendlyError(e));
      if (ApiError.from(e)?.codigo == pixChaveAusenteCodigo) {
        Navigator.of(context).pop(false);
        context.push('/perfil/wallet');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final valor = recorrenciaLerValor(_valorCtrl.text);
    final fixo = widget.alunoId != null;
    // O FxHomeSheetSurface já reserva o espaço do teclado: não somar de novo.
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child:
          _escolhendoAluno
              ? FinanceiroAlunoEtapa(
                alunos: widget.alunos,
                selecionadoId: _alunoId,
                onVoltar: () => setState(() => _escolhendoAluno = false),
                onPick: _escolherAluno,
              )
              : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FxHomeSheetHandle(isDark: isDark),
                    const SizedBox(height: TokensStrip.s4),
                    FxHomeSheetHeader(
                      isDark: isDark,
                      title: s.recorrenciaNova,
                      subtitle: s.recorrenciaNovaSub,
                      leading: Icon(
                        Icons.repeat_rounded,
                        color: primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    FxSettingsGroup(
                      children: [
                        FxSettingsTile(
                          fxIcon: 'users',
                          label: s.recorrenciaAluno,
                          value: _alunoNome ?? s.recorrenciaSelecionar,
                          picker: !fixo,
                          onTap:
                              fixo
                                  ? null
                                  : () =>
                                      setState(() => _escolhendoAluno = true),
                        ),
                        AlunoInsetFormField(
                          controller: _valorCtrl,
                          label: s.recorrenciaValor,
                          hint: 'R\$ 0,00',
                          icon: Icons.payments_outlined,
                          rotuloVisivel: true,
                          obrigatorio: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]'),
                            ),
                          ],
                        ),
                        FxSettingsTile(
                          fxIcon: 'calendar',
                          label: s.recorrenciaDia,
                          value: recorrenciaDiaLabel(_dia),
                          picker: true,
                          showDivider: false,
                          onTap: _escolherDia,
                        ),
                      ],
                    ),
                    if (valor != null) ...[
                      const SizedBox(height: TokensStrip.s2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          recorrenciaResumo(s, dia: _dia, valor: valor),
                          style: FocuxHubTypography.cardSubtitle(
                            color: chrome.mute,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: TokensStrip.s3),
                    FxLiquidPrimaryButton(
                      label: s.recorrenciaCriar,
                      loading: _salvando,
                      loadingLabel: s.recorrenciaCriando,
                      onPressed: _salvando ? null : _criar,
                    ),
                    const SizedBox(height: TokensStrip.s2),
                  ],
                ),
              ),
    );
  }
}
