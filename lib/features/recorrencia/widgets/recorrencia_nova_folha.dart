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
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../financeiro/utils/pix_qr_display.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';
import '../utils/recorrencia_sugestao.dart';

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
        FeedbackHelper.showWarn(
          context,
          'Cadastre um aluno primeiro.',
        );
      }
      return false;
    }
  }
  if (!context.mounted) return false;

  final criou = await showFxHomeSheet<bool>(
    context,
    builder: (ctx) => _NovaRecorrenciaSheet(
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

  Future<void> _escolherAluno() async {
    final escolhido = await showFxHomeSheet<Aluno>(
      context,
      builder: (_) => _AlunoBuscaSheet(alunos: widget.alunos),
    );
    if (escolhido == null || !mounted) return;
    setState(() {
      _alunoId = escolhido.id;
      _alunoNome = escolhido.nome;
    });
    await _sugerirValor(escolhido.id);
  }

  Future<void> _escolherDia() async {
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: S.of(context).recorrenciaDia,
      selected: _dia,
      items: [
        for (var d = 1; d <= recorrenciaDiaMaximo; d++)
          FxInsetPickerSheetItem(value: d, label: recorrenciaDiaLabel(d)),
      ],
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
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
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
              leading: Icon(Icons.repeat_rounded, color: primary, size: 18),
            ),
            const SizedBox(height: TokensStrip.s3),
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  fxIcon: 'users',
                  label: s.recorrenciaAluno,
                  value: _alunoNome ?? s.recorrenciaSelecionar,
                  picker: !fixo,
                  onTap: fixo ? null : _escolherAluno,
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
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
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
                  style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
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

/// Lista de alunos com busca por nome ou e-mail.
class _AlunoBuscaSheet extends StatefulWidget {
  const _AlunoBuscaSheet({required this.alunos});

  final List<Aluno> alunos;

  @override
  State<_AlunoBuscaSheet> createState() => _AlunoBuscaSheetState();
}

class _AlunoBuscaSheetState extends State<_AlunoBuscaSheet> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtrados = filterAlunoPickerAlunos(widget.alunos, _query);
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            const SizedBox(height: TokensStrip.s3),
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: FxInputDeco.build(context, s.recorrenciaBuscarAluno),
            ),
            const SizedBox(height: TokensStrip.s2),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtrados.length,
                itemBuilder: (_, i) {
                  final a = filtrados[i];
                  return FxSatelliteListTile(
                    title: a.nome,
                    titleCase: false,
                    onTap: () => Navigator.of(context).pop(a),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
