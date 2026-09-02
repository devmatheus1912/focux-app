import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../utils/editar_aluno_display.dart';
import '../widgets/aluno_form_choices.dart';
import '../widgets/aluno_inset_form_field.dart';
import '../widgets/editar_aluno_help_sheet.dart';

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
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: editarAlunoConfirmTitle(addAlunoFirstName(_nome.text)),
      message: editarAlunoConfirmMessage(),
      icon: Icons.badge_outlined,
      confirmLabel: editarAlunoConfirmLabel(),
    );
    if (!ok || !mounted) return;
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
      context.pop(true);
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
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Editar Aluno',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Editar Aluno',
          subtitle: editarAlunoHubSubtitle(),
          onBack: () => safePopOrGo(context, '/alunos/${widget.aluno.id}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como editar',
              onTap: () {
                AnalyticsService.instance.track(ProductEvents.alunosHelpOpened);
                showEditarAlunoHelpSheet(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s3),
              child: Center(
                child: Semantics(
                  button: true,
                  enabled: !_salvando,
                  label:
                      _salvando
                          ? 'Salvando alterações do aluno'
                          : 'Salvar alterações do aluno',
                  child: ShellHeaderIconButton(
                    icon: 'circle-check',
                    tooltip: editarAlunoSalvarTooltip(),
                    onTap: _salvando ? () {} : _salvar,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FxPremiumEntrance(
          child: SafeArea(
            bottom: false,
            child: FxContentWidthLimiter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  8,
                  FxSettingsLayout.pageInset,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FxSettingsGroup(
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: TokensStrip.s3,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 28,
                                        backgroundColor: primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        child: Text(
                                          fxInitials(displayName),
                                          style: FocuxHubTypography.cardTitle(
                                            color: primary,
                                          ).copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: TokensStrip.s3),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: FxSettingsLayout.rowLabel(
                                                color: chrome.ink,
                                              ),
                                            ),
                                            if (objetivoPreview.isNotEmpty)
                                              Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                      top: 2,
                                                    ),
                                                child: Text(
                                                  objetivoPreview,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      FxSettingsLayout.subhead(
                                                        color: chrome.mute,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            thickness: FxSettingsLayout.dividerThickness,
                            color: chrome.line,
                          ),
                          AlunoInsetFormField(
                            controller: _nome,
                            label: 'Nome completo',
                            hint: 'Nome do aluno',
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                addAlunoNomeMax,
                              ),
                            ],
                            validator:
                                (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Informe o nome'
                                        : null,
                          ),
                          AlunoInsetFormField(
                            controller: _email,
                            label: 'E-mail',
                            hint: 'aluno@email.com',
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                addAlunoEmailMax,
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o e-mail';
                              }
                              if (!addAlunoEmailValido(v)) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                          AlunoInsetFormField(
                            controller: _telefone,
                            label: 'Telefone',
                            hint: 'DDD + número',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                editarAlunoTelefoneMax,
                              ),
                            ],
                          ),
                          AlunoInsetFormField(
                            controller: _whatsapp,
                            label: 'WhatsApp',
                            hint: 'DDD + número',
                            icon: Icons.chat_bubble_outline_rounded,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [BrPhone.formatter()],
                            validator: BrPhone.validateOptional,
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'Perfil do aluno',
                        caption:
                            'Objetivo, gênero e consultoria alimentam prescrição e Copiloto.',
                        children: [
                          AlunoInsetFormField(
                            controller: _objetivo,
                            label: 'Objetivo',
                            hint: 'Ex.: Hipertrofia, emagrecimento',
                            icon: Icons.flag_outlined,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            showDivider: true,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(
                                addAlunoObjetivoMax,
                              ),
                            ],
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
                                    () =>
                                        _genero =
                                            _genero == value ? null : value,
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
                          child: FxErrorState(
                            chromeOnDark: isDark,
                            primary: primary,
                            message: _error!,
                            onRetry: _salvar,
                            title: 'Não foi possível salvar',
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
      ),
    );
  }
}
