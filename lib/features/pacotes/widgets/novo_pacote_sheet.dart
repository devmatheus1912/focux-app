import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/pacote_repository.dart';
import '../utils/pacote_display.dart';

/// Abre bottom sheet premium; retorna true se pacote foi criado.
Future<bool> showNovoPacoteSheet(
  BuildContext context, {
  required PacoteRepository repo,
}) async {
  final created = await showFxHomeSheet<bool>(
    context,
    builder: (ctx) => _NovoPacoteSheet(repo: repo),
  );
  return created ?? false;
}

class _NovoPacoteSheet extends StatefulWidget {
  const _NovoPacoteSheet({required this.repo});

  final PacoteRepository repo;

  @override
  State<_NovoPacoteSheet> createState() => _NovoPacoteSheetState();
}

class _NovoPacoteSheetState extends State<_NovoPacoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  int _duracao = 1;
  bool _treino = true;
  bool _nutri = false;
  bool _consultoria = false;
  bool _destaque = false;
  bool _enviando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirDuracao() async {
    final picked = await showFxInsetPickerSheet<int>(
      context,
      title: 'Duração',
      selected: _duracao,
      items: [
        for (final meses in pacoteDuracaoMesesValues)
          FxInsetPickerSheetItem(
            value: meses,
            label: pacoteDuracaoLabel(meses),
          ),
      ],
    );
    if (picked == null) return;
    setState(() => _duracao = picked);
  }

  Future<void> _submit() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: pacoteCriarConfirmTitle(),
      message: pacoteCriarConfirmMessage(),
      icon: Icons.add_card_outlined,
      confirmLabel: pacoteCriarConfirmLabel(),
    );
    if (!ok || !mounted) return;

    setState(() => _enviando = true);
    try {
      await widget.repo.criar(
        titulo: _tituloCtrl.text.trim(),
        descricao: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        valor: double.parse(_valorCtrl.text.trim().replaceAll(',', '.')),
        duracaoMeses: _duracao,
        incluiTreino: _treino,
        incluiNutri: _nutri,
        incluiConsultoria: _consultoria,
        destaque: _destaque,
      );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  0,
                ),
                child: FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Novo plano',
                  subtitle:
                      'Quem abrir seu link verá este plano na sua página de vendas.',
                  leading: FxIcon(name: 'coin', color: primary, size: 18),
                  trailing: IconButton(
                    tooltip: 'Fechar',
                    onPressed:
                        _enviando ? null : () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        FxHomeSheetChrome.touchTarget,
                        FxHomeSheetChrome.touchTarget,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 22),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  MediaQuery.of(context).viewInsets.bottom + TokensStrip.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              FxSettingsGroup(
                children: [
                  AlunoInsetFormField(
                    controller: _tituloCtrl,
                    label: 'Título',
                    icon: Icons.title_outlined,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(pacoteTituloMax),
                    ],
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Informe um título'
                                : null,
                  ),
                  AlunoInsetFormField(
                    controller: _descCtrl,
                    label: 'Descrição',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(pacoteDescricaoMax),
                    ],
                  ),
                  AlunoInsetFormField(
                    controller: _valorCtrl,
                    label: 'Valor que o cliente paga (R\$)',
                    icon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Informe o valor';
                      }
                      final valor =
                          double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;
                      if (valor <= 0) return 'Valor deve ser maior que zero';
                      return null;
                    },
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
              FxSettingsGroup(
                header: 'Plano',
                children: [
                  FxSettingsTile(
                    fxIcon: 'calendar',
                    label: 'Duração',
                    value: pacoteDuracaoLabel(_duracao),
                    picker: true,
                    onTap: _enviando ? null : _abrirDuracao,
                  ),
                  FxSettingsTile(
                    fxIcon: 'target',
                    label: 'Treino',
                    value: pacoteIncluiValue(_treino),
                    accessory: Switch.adaptive(
                      value: _treino,
                      onChanged:
                          _enviando
                              ? null
                              : (v) => setState(() => _treino = v),
                    ),
                  ),
                  FxSettingsTile(
                    fxIcon: 'spark',
                    label: 'Nutrição',
                    value: pacoteIncluiValue(_nutri),
                    accessory: Switch.adaptive(
                      value: _nutri,
                      onChanged:
                          _enviando
                              ? null
                              : (v) => setState(() => _nutri = v),
                    ),
                  ),
                  FxSettingsTile(
                    fxIcon: 'message-circle',
                    label: 'Consultoria',
                    value: pacoteIncluiValue(_consultoria),
                    showDivider: false,
                    accessory: Switch.adaptive(
                      value: _consultoria,
                      onChanged:
                          _enviando
                              ? null
                              : (v) => setState(() => _consultoria = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
              FxSettingsGroup(
                children: [
                  FxSettingsTile(
                    fxIcon: 'star',
                    label: 'Mostrar em destaque',
                    value: pacoteIncluiValue(_destaque),
                    showDivider: false,
                    accessory: Switch.adaptive(
                      value: _destaque,
                      onChanged:
                          _enviando
                              ? null
                              : (v) => setState(() => _destaque = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
              FxLiquidPrimaryButton(
                label: pacoteCriarTileLabel(),
                loading: _enviando,
                loadingLabel: 'Criando…',
                onPressed: _enviando ? null : _submit,
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

