import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/utils/br_phone.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../widgets/aluno_form_choices.dart';

class EditarAlunoScreen extends ConsumerStatefulWidget {
  final Aluno aluno;
  const EditarAlunoScreen({super.key, required this.aluno});

  @override
  ConsumerState<EditarAlunoScreen> createState() => _EditarAlunoScreenState();
}

class _EditarAlunoScreenState extends ConsumerState<EditarAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _objetivo;
  String? _genero;
  String? _tipoConsultoria;
  bool _salvando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.aluno.nome);
    _email = TextEditingController(text: widget.aluno.email);
    _telefone = TextEditingController(text: widget.aluno.telefone ?? '');
    _whatsapp = TextEditingController(text: widget.aluno.whatsapp ?? '');
    _objetivo = TextEditingController(text: widget.aluno.objetivo ?? '');
    _genero = widget.aluno.genero;
    _tipoConsultoria = widget.aluno.tipoConsultoria ?? 'ONLINE';
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _whatsapp.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _salvando = true;
      _error = null;
    });
    try {
      final repo = AlunoRepository(ref.read(apiClientProvider));
      await repo.atualizarAluno(widget.aluno.id, {
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone':
            _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        'whatsapp':
            _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'objetivo':
            _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
        'genero': _genero,
        'tipoConsultoria': _tipoConsultoria ?? 'ONLINE',
      });
      if (!mounted) return;
      invalidateAlunosCaches(ref);
      await invalidateAluno360Providers(ref, widget.aluno.id);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      FeedbackHelper.showSuccess(context, 'Aluno atualizado!');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = friendlyError(
                e,
                fallback: 'Erro ao salvar. Tente novamente.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);

    return fxScreenA11yScope(
      label: 'Editar Aluno',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Editar Aluno',
          subtitle: 'ALUNO',
          onBack: () => safePopOrGo(context, '/alunos/${widget.aluno.id}'),
        ),
        bottomNavigationBar: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: (isDark ? EagleTokens.darkCard : TokensStrip.cardBg)
                  .withValues(alpha: 0.96),
              border: Border(top: BorderSide(color: chrome.line)),
            ),
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              12,
              TokensStrip.s4,
              12,
            ),
            child: SafeArea(
              top: false,
              child: Semantics(
                button: true,
                enabled: !_salvando,
                label:
                    _salvando
                        ? 'Salvando alterações do aluno'
                        : 'Salvar alterações do aluno',
                child: FxLiquidPrimaryButton(
                  label: 'Salvar alterações',
                  loadingLabel: 'Salvando…',
                  loading: _salvando,
                  onPressed: _salvando ? null : _salvar,
                ),
              ),
            ),
          ),
        ),
        body: FxPremiumEntrance(
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s4,
                8,
                TokensStrip.s4,
                24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListenableBuilder(
                      listenable: Listenable.merge([_nome, _objetivo]),
                      builder: (context, _) {
                        final displayName =
                            _nome.text.trim().isEmpty
                                ? widget.aluno.nome
                                : _nome.text.trim();
                        final objetivoPreview =
                            _objetivo.text.trim().isNotEmpty
                                ? _objetivo.text.trim()
                                : (widget.aluno.objetivo ?? '').trim();
                        return Semantics(
                          label: 'Aluno $displayName',
                          child: Center(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: Text(
                                    fxInitials(displayName),
                                    style: FocuxHubTypography.pageTitle(
                                      context,
                                      color: primary,
                                    ).copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  displayName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: FocuxHubTypography.body(
                                    color: chrome.ink,
                                  ).copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: FocuxHubTypography.metricEm,
                                  ),
                                ),
                                if (objetivoPreview.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      objetivoPreview,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: FocuxHubTypography.bodyMuted(
                                        color: chrome.mute,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    FxSettingsGroup(
                      header: 'Informações básicas',
                      caption:
                          'Contato e identificação usados no atendimento e no Copiloto.',
                      accent: primary,
                      children: [
                        Semantics(
                          label: 'Nome completo obrigatório',
                          child: _EditField(
                            controller: _nome,
                            label: 'Nome completo',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Informe o nome'
                                        : null,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Semantics(
                          label: 'E-mail obrigatório',
                          child: _EditField(
                            controller: _email,
                            label: 'E-mail',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o e-mail';
                              }
                              if (!v.contains('@')) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Semantics(
                          label: 'Telefone opcional',
                          child: _EditField(
                            controller: _telefone,
                            label: 'Telefone',
                            icon: Icons.phone_outlined,
                            hint: 'DDD + número',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Semantics(
                          label: 'WhatsApp opcional',
                          child: _EditField(
                            controller: _whatsapp,
                            label: 'WhatsApp',
                            icon: Icons.chat_bubble_outline_rounded,
                            hint: 'DDD + número',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [BrPhone.formatter()],
                            validator: BrPhone.validateOptional,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      header: 'Perfil do aluno',
                      caption:
                          'Objetivo, gênero e consultoria alimentam prescrição e Copiloto.',
                      accent: primary,
                      children: [
                        Semantics(
                          label: 'Objetivo do aluno',
                          child: _EditField(
                            controller: _objetivo,
                            label: 'Objetivo',
                            icon: Icons.flag_outlined,
                            hint: 'Ex.: Hipertrofia, emagrecimento',
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                          ),
                        ),
                        AlunoChoiceSection(
                          label: 'Gênero',
                          isDark: isDark,
                          showDividerAbove: true,
                          child: AlunoSegmentedChoice(
                            isDark: isDark,
                            options: const [
                              (value: 'MASCULINO', label: 'Masculino'),
                              (value: 'FEMININO', label: 'Feminino'),
                              (value: 'OUTRO', label: 'Outro'),
                            ],
                            selected: _genero,
                            onSelect:
                                (value) => setState(
                                  () => _genero = _genero == value ? null : value,
                                ),
                          ),
                        ),
                        AlunoChoiceSection(
                          label: 'Consultoria',
                          isDark: isDark,
                          showDividerAbove: true,
                          child: AlunoSegmentedChoice(
                            isDark: isDark,
                            options: const [
                              (value: 'ONLINE', label: 'Online'),
                              (value: 'PRESENCIAL', label: 'Presencial'),
                              (value: 'HIBRIDO', label: 'Híbrido'),
                            ],
                            selected: _tipoConsultoria,
                            onSelect:
                                (value) => setState(
                                  () =>
                                      _tipoConsultoria =
                                          _tipoConsultoria == value
                                              ? null
                                              : value,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: TokensStrip.s3),
                      Semantics(
                        liveRegion: true,
                        label: _error!,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: EagleTokens.bad,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: FxInputDeco.build(
        context,
        label,
        icon: icon,
        hint: hint,
        iconColor: BrandPalette.softened(primary),
        iconSize: FxSettingsLayout.iconSize,
      ),
    );
  }
}
