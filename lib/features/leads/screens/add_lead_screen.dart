import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
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
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _objetivo.dispose();
    _observacoes.dispose();
    super.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    try {
      await LeadRepository(ref.read(apiClientProvider)).criar(
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim(),
        origem: _origem,
        objetivo: _objetivo.text.trim(),
        observacoes: _observacoes.text.trim(),
      );
      if (mounted) safePopOrGo(context, '/leads');
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
    child: FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Novo Lead',
        subtitle: leadNovoHubSubtitle(),
        onBack: () => safePopOrGo(context, '/leads'),
      ),
      body: FxContentWidthLimiter(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              32,
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
                  ),
                  AlunoInsetFormField(
                    controller: _observacoes,
                    label: 'Observações',
                    icon: Icons.notes_outlined,
                    maxLines: 3,
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
              Semantics(
                button: true,
                label: _saving ? 'Salvando lead' : 'Salvar lead',
                child: FxLiquidPrimaryButton(
                  loading: _saving,
                  icon: Icons.check_rounded,
                  label: _saving ? 'Salvando...' : 'Salvar lead',
                  onPressed: _saving ? null : _salvar,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
