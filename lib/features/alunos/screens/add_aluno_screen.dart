import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_error.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../providers/alunos_provider.dart';
import '../utils/add_aluno_display.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../widgets/add_aluno_help_sheet.dart';
import '../widgets/add_aluno_senha_sheet.dart';
import '../widgets/aluno_form_choices.dart';
import '../widgets/aluno_inset_form_field.dart';

part 'add_aluno_screen_widgets.part.dart';

class AddAlunoScreen extends ConsumerStatefulWidget {
  const AddAlunoScreen({super.key, this.initialEmail, this.initialNome});

  final String? initialEmail;
  final String? initialNome;

  @override
  ConsumerState<AddAlunoScreen> createState() => _AddAlunoScreenState();
}

class _AddAlunoScreenState extends ConsumerState<AddAlunoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String? _genero;
  String? _tipoConsultoria;
  bool _objetivoLivre = false;
  bool _loading = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  bool _entryStarted = false;

  bool get _canSubmit {
    return _nomeCtrl.text.trim().isNotEmpty &&
        addAlunoEmailValido(_emailCtrl.text) &&
        !_loading;
  }

  String get _firstName => addAlunoFirstName(_nomeCtrl.text);

  bool get _dirty =>
      _nomeCtrl.text.trim().isNotEmpty ||
      _emailCtrl.text.trim().isNotEmpty ||
      _objetivoCtrl.text.trim().isNotEmpty ||
      _whatsappCtrl.text.trim().isNotEmpty ||
      _genero != null ||
      _tipoConsultoria != null ||
      _objetivoLivre;

  Future<void> _cancel() async {
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar cadastro?',
        message: 'O que você preencheu não será salvo.',
        confirmLabel: 'Descartar',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/alunos');
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _nomeCtrl.addListener(_refreshSubmitState);
    _emailCtrl.addListener(_refreshSubmitState);
    _objetivoCtrl.addListener(_refreshSubmitState);
    _whatsappCtrl.addListener(_refreshSubmitState);

    final email = widget.initialEmail?.trim();
    if (email != null && email.isNotEmpty) {
      _emailCtrl.text = email;
    }
    final nome = widget.initialNome?.trim();
    if (nome != null && nome.isNotEmpty) {
      _nomeCtrl.text = nome;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    if (TokensStrip.prefersReducedMotion(context)) {
      _entryCtrl.value = 1.0;
    } else {
      _entryCtrl.forward();
    }
  }

  void _refreshSubmitState() {
    if (mounted) setState(() {});
  }

  void _selectObjetivoPreset(String objetivo) {
    HapticFeedback.selectionClick();
    setState(() {
      _objetivoLivre = false;
      _objetivoCtrl.text =
          _objetivoCtrl.text.trim() == objetivo ? '' : objetivo;
    });
  }

  void _toggleObjetivoLivre() {
    HapticFeedback.selectionClick();
    setState(() {
      final next = !_objetivoLivre;
      _objetivoLivre = next;
      if (next) {
        if (addAlunoObjetivosRapidos.contains(_objetivoCtrl.text.trim())) {
          _objetivoCtrl.clear();
        }
      } else {
        _objetivoCtrl.clear();
      }
    });
  }

  @override
  void dispose() {
    _nomeCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _emailCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _objetivoCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _whatsappCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: addAlunoConfirmTitle(_firstName),
      message: addAlunoConfirmMessage(
        hasWhatsapp: _whatsappCtrl.text.trim().isNotEmpty,
      ),
      icon: Icons.badge_outlined,
      confirmLabel: addAlunoConfirmLabel(),
    );
    if (!ok || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final objetivo = _objetivoCtrl.text.trim();
      final whatsapp = BrPhone.normalizeOrNull(_whatsappCtrl.text);
      final novoAluno = await ref
          .read(alunoRepositoryProvider)
          .criar(
            nome: _nomeCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            objetivo: objetivo.isEmpty ? null : objetivo,
            whatsapp: whatsapp,
            genero: _genero,
            tipoConsultoria: _tipoConsultoria,
          );

      if (!mounted) return;
      invalidateAlunosCaches(ref);
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.alunoCreated,
          props: {'has_whatsapp': whatsapp != null},
        ),
      );
      if (novoAluno.senhaProvisoria != null) {
        await showAddAlunoSenhaSheet(
          context: context,
          aluno: novoAluno,
          onDone: () {
            if (mounted) context.pop(true);
          },
        );
      } else {
        HapticFeedback.heavyImpact();
        context.pop(true);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      final surfaced = await UpgradePromptSheet.showFromError(
        context,
        e,
        fallbackFeatureName: 'Mais vagas de alunos',
        fallbackCapability: 'alunos',
        source: 'add_aluno',
      );
      if (surfaced) return;
      // `erro` do contrato, sem despejar `detalhes` (chaves internas como
      // feature/limite) na cara do usuário.
      final api = ApiError.from(e);
      var errorMsg =
          api?.mensagem ??
          friendlyError(
            e,
            fallback: 'Não foi possível cadastrar o aluno. Revise os dados.',
          );
      if (api?.requestId != null) {
        errorMsg = '$errorMsg\n\nRef: ${api!.requestId}';
      }
      if (mounted) setState(() => _error = errorMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Novo aluno',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Novo aluno',
          subtitle: addAlunoHubSubtitle(),
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
              tooltip: 'Como cadastrar',
              onTap: () {
                AnalyticsService.instance.track(ProductEvents.alunosHelpOpened);
                showAddAlunoHelpSheet(context);
              },
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s3,
            ),
            child: Semantics(
              button: true,
              enabled: _canSubmit && !_loading,
              label:
                  _canSubmit
                      ? (_loading
                          ? 'Cadastrando aluno'
                          : 'Cadastrar $_firstName. O convite será preparado após o cadastro.')
                      : 'Cadastrar. Complete nome e e-mail para habilitar',
              child: FxLiquidPrimaryButton(
                label: 'Cadastrar',
                loading: _loading,
                loadingLabel: 'Cadastrando…',
                onPressed: _canSubmit && !_loading ? _submit : null,
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _entryFade,
            child: SlideTransition(
              position: _entrySlide,
              child: FxContentWidthLimiter(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    6,
                    FxSettingsLayout.pageInset,
                    24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AccessProgressStrip(
                          name: _firstName,
                          hasName: _nomeCtrl.text.trim().isNotEmpty,
                          hasEmail: addAlunoEmailValido(_emailCtrl.text),
                          isDark: isDark,
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          header: 'Identidade',
                          caption: 'Acesso e contato.',
                          footer: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: FxSettingsLayout.groupPadH,
                            ),
                            child: Text(
                              'WhatsApp opcional — se preencher, o convite abre pronto.',
                              style: FxSettingsLayout.footer(
                                color: chrome.mute,
                              ),
                            ),
                          ),
                          children: [
                            AlunoInsetFormField(
                              controller: _nomeCtrl,
                              label: 'Nome completo',
                              hint: 'Ex.: Beatriz Andrade',
                              icon: Icons.person_outline_rounded,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(
                                  addAlunoNomeMax,
                                ),
                              ],
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome completo.'
                                          : null,
                              textCapitalization: TextCapitalization.words,
                            ),
                            AlunoInsetFormField(
                              controller: _emailCtrl,
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
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) {
                                  return 'Informe o e-mail.';
                                }
                                if (!addAlunoEmailValido(value)) {
                                  return 'Informe um e-mail válido.';
                                }
                                return null;
                              },
                            ),
                            AlunoInsetFormField(
                              controller: _whatsappCtrl,
                              label: 'WhatsApp',
                              hint: '(11) 99999-9999',
                              icon: Icons.phone_iphone_rounded,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [BrPhone.formatter()],
                              validator: BrPhone.validateOptional,
                              showDivider: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Perfil inicial',
                          caption:
                              'Opcional — melhora filtros e atendimento.',
                          children: [
                            AlunoChoiceSection(
                              label: 'Objetivo',
                              isDark: isDark,
                              child: _ChipWrap(
                                children: [
                                  ...addAlunoObjetivosRapidos.map((objetivo) {
                                    final selected =
                                        !_objetivoLivre &&
                                        _objetivoCtrl.text.trim() == objetivo;
                                    return AlunoOptionChip(
                                      label: objetivo,
                                      selected: selected,
                                      isDark: isDark,
                                      onTap:
                                          () => _selectObjetivoPreset(objetivo),
                                    );
                                  }),
                                  AlunoOptionChip(
                                    label: 'Outro',
                                    selected: _objetivoLivre,
                                    isDark: isDark,
                                    onTap: _toggleObjetivoLivre,
                                  ),
                                ],
                              ),
                            ),
                            if (_objetivoLivre) ...[
                              const SizedBox(height: TokensStrip.s2),
                              AlunoInsetFormField(
                                controller: _objetivoCtrl,
                                label: 'Outro objetivo',
                                hint: 'Ex.: Reabilitação',
                                icon: Icons.flag_outlined,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(
                                    addAlunoObjetivoMax,
                                  ),
                                ],
                                showDivider: false,
                              ),
                            ],
                            AlunoChoiceSection(
                              label: 'Gênero',
                              isDark: isDark,
                              showDividerAbove: true,
                              child: AlunoSegmentedChoice(
                                isDark: isDark,
                                options: [
                                  for (final g in addAlunoGeneros)
                                    (value: g, label: g),
                                ],
                                selected: _genero,
                                onSelect: (value) {
                                  setState(
                                    () =>
                                        _genero =
                                            _genero == value ? null : value,
                                  );
                                },
                              ),
                            ),
                            AlunoChoiceSection(
                              label: 'Consultoria',
                              isDark: isDark,
                              showDividerAbove: true,
                              child: AlunoSegmentedChoice(
                                isDark: isDark,
                                options: List.generate(
                                  addAlunoTiposConsultoria.length,
                                  (i) => (
                                    value: addAlunoTiposConsultoria[i],
                                    label: addAlunoTiposConsultoriaLabel[i],
                                  ),
                                ),
                                selected: _tipoConsultoria,
                                onSelect: (value) {
                                  setState(
                                    () =>
                                        _tipoConsultoria =
                                            _tipoConsultoria == value
                                                ? null
                                                : value,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_canSubmit) ...[
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxSettingsGroup(
                            header: 'Depois do cadastro',
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: TokensStrip.s3,
                                ),
                                child: Text(
                                  addAlunoAfterSubmitCopy(
                                    firstName: _firstName,
                                    hasWhatsapp:
                                        _whatsappCtrl.text.trim().isNotEmpty,
                                  ),
                                  style: FxSettingsLayout.subhead(
                                    color: chrome.mute,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: TokensStrip.s3),
                          Semantics(
                            liveRegion: true,
                            label: _error!,
                            child: FxErrorState(
                              chromeOnDark: isDark,
                              primary: primary,
                              message: _error!,
                              onRetry: _submit,
                              title: 'Não foi possível cadastrar',
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
      ),
    );
  }
}
