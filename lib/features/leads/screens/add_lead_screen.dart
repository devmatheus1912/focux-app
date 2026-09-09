import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import '../utils/lead_display.dart';

class AddLeadScreen extends ConsumerStatefulWidget {
  const AddLeadScreen({super.key});

  @override
  ConsumerState<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends ConsumerState<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _objetivo = TextEditingController();
  final _observacoes = TextEditingController();
  String? _origem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nome.addListener(_onFormChanged);
    _telefone.addListener(_onFormChanged);
    _objetivo.addListener(_onFormChanged);
    _observacoes.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nome.removeListener(_onFormChanged);
    _telefone.removeListener(_onFormChanged);
    _objetivo.removeListener(_onFormChanged);
    _observacoes.removeListener(_onFormChanged);
    _nome.dispose();
    _telefone.dispose();
    _objetivo.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Novo Lead',
      subtitle: leadNovoHubSubtitle(),
      tips: const [
        FxHelpTip(
          'Nome',
          'É o único campo obrigatório. O prospect entra no funil como Lead.',
          icon: 'users',
        ),
        FxHelpTip(
          'Plano Free',
          'O Free segura 5 leads. No Pro o CRM não tem esse teto.',
          icon: 'spark',
        ),
      ],
    );
  }

  bool get _dirty =>
      _nome.text.trim().isNotEmpty ||
      _telefone.text.trim().isNotEmpty ||
      _objetivo.text.trim().isNotEmpty ||
      _observacoes.text.trim().isNotEmpty ||
      _origem != null;

  bool get _canSubmit => _nome.text.trim().isNotEmpty && !_saving;

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar cadastro?',
        message: 'O que você preencheu não será salvo.',
        confirmLabel: 'Descartar',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/leads');
  }

  Future<void> _abrirOrigem() async {
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Origem',
      selected: _origem,
      items: [
        for (final o in leadOrigemValues)
          FxInsetPickerSheetItem(value: o, label: o),
      ],
    );
    if (!mounted || picked == null) return;
    setState(() => _origem = picked);
  }

  Future<void> _salvar() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: leadConfirmTitle(),
      message: leadConfirmMessage(_nome.text),
      icon: Icons.badge_outlined,
      confirmLabel: leadConfirmLabel(),
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    try {
      await LeadRepository(ref.read(apiClientProvider)).criar(
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim(),
        origem: _origem,
        objetivo: _objetivo.text.trim(),
        observacoes: _observacoes.text.trim(),
      );
      AnalyticsService.instance.track(
        ProductEvents.leadCreatedOrOpened,
        props: {'feature': 'leads', 'action': 'salvar'},
      );
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Lead salvo no funil.');
        safePopOrGo(context, '/leads');
      }
    } catch (e) {
      if (mounted) {
        if (e is DioException && e.response?.statusCode == 403) {
          final msg = e.response?.data?.toString() ?? '';
          FeedbackHelper.showInfo(
            context,
            msg.contains('Limite')
                ? 'Limite de 5 leads no plano Free. Assine o Pro para CRM ilimitado.'
                : 'Recurso disponível no Pro.',
          );
        } else {
          FeedbackHelper.showError(
            context,
            friendlyError(e, fallback: 'Não conseguimos salvar o lead.'),
          );
        }
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => fxScreenA11yScope(
    label: 'Novo Lead',
    child: FxFormPopGuard(
      dirty: _dirty,
      onCancel: _cancel,
      child: FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Novo Lead',
        subtitle: leadNovoHubSubtitle(),
        leadingWidth: 92,
        leading: TextButton(
          onPressed: _cancel,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Cancelar'),
        ),
        actions: [
          FxHelpIconButton(
            tooltip: 'Como cadastrar um lead',
            onTap: _showHelp,
          ),
        ],
      ),
      bottomNavigationBar: FxFormStickyBar(
        child: Semantics(
          button: true,
          enabled: _canSubmit,
          label:
              _canSubmit
                  ? (_saving ? 'Salvando lead' : leadSalvarTooltip())
                  : 'Salvar. Informe o nome para habilitar',
          child: FxLiquidPrimaryButton(
            label: 'Salvar',
            loading: _saving,
            loadingLabel: 'Salvando…',
            onPressed: _canSubmit ? _salvar : null,
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: FxContentWidthLimiter(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                24,
              ),
              children: [
                FxSettingsGroup(
                  header: 'Prospect',
                  caption: 'Nome é obrigatório. O restante ajuda no follow-up.',
                  children: [
                  AlunoInsetFormField(
                    controller: _nome,
                    label: 'Nome',
                    icon: Icons.badge_outlined,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(leadNomeMax),
                    ],
                    validator:
                        (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Informe o nome'
                                : null,
                  ),
                  AlunoInsetFormField(
                    controller: _telefone,
                    label: 'Telefone / WhatsApp',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(leadTelefoneMax),
                    ],
                  ),
                  FxSettingsTile(
                    fxIcon: 'spark',
                    label: 'Origem',
                    value: leadOrigemLabel(_origem),
                    picker: true,
                    onTap: _abrirOrigem,
                  ),
                  AlunoInsetFormField(
                    controller: _objetivo,
                    label: 'Objetivo',
                    hint: 'Ex.: emagrecer, hipertrofiar',
                    icon: Icons.flag_outlined,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(leadObjetivoMax),
                    ],
                  ),
                  AlunoInsetFormField(
                    controller: _observacoes,
                    label: 'Observações',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    showDivider: false,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(leadObservacoesMax),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ),
  ),
);
}
