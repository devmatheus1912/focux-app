import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

const _origens = ['Instagram', 'Indicação', 'WhatsApp', 'Google', 'Outro'];

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

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
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
                ? 'Limite de 5 leads no plano Free. Assine Premium para CRM ilimitado.'
                : 'Recurso disponível no Premium.',
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
        subtitle: 'Cadastre um prospect no CRM',
        onBack: () => safePopOrGo(context, '/leads'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nome,
                decoration: FxInputDeco.build(
                  context,
                  'Nome *',
                  icon: Icons.person_rounded,
                ),
                validator:
                    (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefone,
                decoration: FxInputDeco.build(
                  context,
                  'Telefone / WhatsApp',
                  icon: Icons.phone_rounded,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _origem,
                decoration: FxInputDeco.build(
                  context,
                  'Origem',
                  icon: Icons.source_rounded,
                ),
                items:
                    _origens
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                onChanged: (v) => setState(() => _origem = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objetivo,
                decoration: FxInputDeco.build(
                  context,
                  'Objetivo',
                  icon: Icons.flag_rounded,
                  hint: 'ex: emagrecer, hipertrofiar',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacoes,
                decoration: FxInputDeco.build(
                  context,
                  'Observações',
                  icon: Icons.notes_rounded,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: TokensStrip.s5),
              FxLiquidPrimaryButton(
                loading: _saving,
                icon: Icons.save_rounded,
                label: _saving ? 'Salvando...' : 'Salvar Lead',
                onPressed: _saving ? null : _salvar,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
