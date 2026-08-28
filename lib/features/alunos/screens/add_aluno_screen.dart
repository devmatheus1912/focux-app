import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../providers/alunos_provider.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/utils/friendly_error.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_invite_copy.dart';
import '../widgets/add_aluno_help_sheet.dart';
import '../widgets/aluno_form_choices.dart';

part 'add_aluno_screen_widgets.part.dart';

const _generos = ['Masculino', 'Feminino', 'Outro'];
const _tiposConsultoria = ['ONLINE', 'PRESENCIAL', 'HIBRIDO'];
const _tiposConsultoriaLabel = ['Online', 'Presencial', 'HÃ­brido'];
const _objetivosRapidos = [
  'Hipertrofia',
  'Emagrecimento',
  'ForÃ§a',
  'Condicionamento',
];

const _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

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

  bool get _canSubmit {
    return _nomeCtrl.text.trim().isNotEmpty &&
        RegExp(_emailPattern).hasMatch(_emailCtrl.text.trim()) &&
        !_loading;
  }

  String get _firstName {
    final name = _nomeCtrl.text.trim();
    if (name.isEmpty) return 'Aluno';
    return name.split(RegExp(r'\s+')).first;
  }

  bool _entryStarted = false;

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
        if (_objetivosRapidos.contains(_objetivoCtrl.text.trim())) {
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
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

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
        _showSenhaBottomSheet(novoAluno);
      } else {
        HapticFeedback.heavyImpact();
        context.pop(true);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      var errorMsg = friendlyError(
        e,
        fallback: 'NÃ£o foi possÃ­vel cadastrar o aluno. Revise os dados.',
      );
      String? requestId;

      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('erro')) {
          errorMsg = data['erro'].toString();
        }
        if (data.containsKey('detalhes') && data['detalhes'] is Map) {
          final details = (data['detalhes'] as Map).entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');
          errorMsg = '$errorMsg\n$details';
        }
        requestId = data['requestId']?.toString();
      }
      if (requestId != null) {
        errorMsg = '$errorMsg\n\nRef: $requestId';
      }

      if (mounted) setState(() => _error = errorMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSenhaBottomSheet(Aluno aluno) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forDark(isDark);
    final senha = aluno.senhaProvisoria ?? '';
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;
    final convite = alunoInviteMessage(
      nome: aluno.nome,
      email: aluno.email,
      senhaProvisoria: senha,
    );

    Future<void> copyConvite() async {
      await copySensitiveToClipboard(convite);
      HapticFeedback.mediumImpact();
    }

    showFxHomeSheet<void>(
      context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return FxHomeSheetScaffold(
          isDark: isDark,
          leading: Icon(
            Icons.check_rounded,
            color: EagleTokens.good,
            size: 22,
          ),
          title: 'Aluno cadastrado',
          subtitle: 'Compartilhe o convite para o aluno acessar o app.',
          trailing: const SizedBox.shrink(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxSettingsGroup(
                header: 'Senha provisÃ³ria',
                caption: 'O aluno deve trocar a senha no primeiro acesso.',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensStrip.s3,
                    ),
                    child: Center(
                      child: Text(
                        senha,
                        textAlign: TextAlign.center,
                        style: FxSettingsLayout.rowLabel(
                          color: chrome.ink,
                        ).copyWith(
                          fontSize: 28,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
              FxSettingsGroup(
                children: [
                  if (hasWhatsapp)
                    FxSettingsTile(
                      icon: Icons.send_rounded,
                      label: 'Enviar no WhatsApp',
                      value: '',
                      highlight: true,
                      showDivider: true,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        final uri = Uri.parse(
                          'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(convite)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) context.pop(true);
                          return;
                        }
                        await copyConvite();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          FeedbackHelper.showSuccess(
                            context,
                            'Mensagem copiada. Abra o WhatsApp e envie ao aluno.',
                          );
                          context.pop(true);
                        }
                      },
                    ),
                  FxSettingsTile(
                    icon: Icons.copy_rounded,
                    label: 'Copiar convite',
                    value: '',
                    showDivider: false,
                    onTap: () async {
                      await copyConvite();
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        FeedbackHelper.showSuccess(
                          context,
                          'Convite copiado.',
                        );
                        context.pop(true);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
              TextButton(
                style: TextButton.styleFrom(
                  minimumSize: const Size(
                    FxHomeSheetChrome.touchTarget,
                    FxHomeSheetChrome.touchTarget,
                  ),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted) context.pop(true);
                },
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    color: chrome.mute,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          subtitle: 'Cadastro rÃ¡pido',
          onBack: () => safePopOrGo(context, '/alunos'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como cadastrar',
              onTap: () {
                AnalyticsService.instance.track(ProductEvents.alunosHelpOpened);
                showAddAlunoHelpSheet(context);
              },
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
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
                enabled: _canSubmit && !_loading,
                label:
                    _canSubmit
                        ? (_loading
                            ? 'Cadastrando aluno'
                            : 'Cadastrar $_firstName. O convite serÃ¡ preparado apÃ³s o cadastro.')
                        : 'Cadastrar. Complete nome e e-mail para habilitar',
                child: FxLiquidPrimaryButton(
                  label: _loading ? 'Cadastrandoâ€¦' : 'Cadastrar',
                  loadingLabel: 'Cadastrandoâ€¦',
                  loading: _loading,
                  onPressed: _canSubmit && !_loading ? _submit : null,
                ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  6,
                  TokensStrip.s4,
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
                            hasEmail: RegExp(
                              _emailPattern,
                            ).hasMatch(_emailCtrl.text.trim()),
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
                                'WhatsApp opcional â€” se preencher, o convite abre pronto.',
                                style: FxSettingsLayout.footer(color: chrome.mute),
                              ),
                            ),
                            children: [
                              Semantics(
                                label: 'Nome completo',
                                child: _FxFormField(
                                  controller: _nomeCtrl,
                                  label: 'Nome completo',
                                  hint: 'Ex.: Beatriz Andrade',
                                  icon: Icons.person_outline_rounded,
                                  validator:
                                      (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Informe o nome completo.'
                                              : null,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              Semantics(
                                label: 'E-mail',
                                child: _FxFormField(
                                  controller: _emailCtrl,
                                  label: 'E-mail',
                                  hint: 'aluno@email.com',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    final value = v?.trim() ?? '';
                                    if (value.isEmpty) {
                                      return 'Informe o e-mail.';
                                    }
                                    if (!RegExp(
                                      _emailPattern,
                                    ).hasMatch(value)) {
                                      return 'Informe um e-mail vÃ¡lido.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              Semantics(
                                label: 'WhatsApp',
                                child: _FxFormField(
                                  controller: _whatsappCtrl,
                                  label: 'WhatsApp',
                                  hint: '(11) 99999-9999',
                                  icon: Icons.phone_iphone_rounded,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [BrPhone.formatter()],
                                  validator: BrPhone.validateOptional,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxSettingsGroup(
                            header: 'Perfil inicial',
                            caption: 'Opcional â€” melhora filtros e atendimento.',
                            children: [
                              AlunoChoiceSection(
                                label: 'Objetivo',
                                isDark: isDark,
                                child: _ChipWrap(
                                  children: [
                                    ..._objetivosRapidos.map((objetivo) {
                                      final selected =
                                          !_objetivoLivre &&
                                          _objetivoCtrl.text.trim() == objetivo;
                                      return AlunoOptionChip(
                                        label: objetivo,
                                        selected: selected,
                                        isDark: isDark,
                                        onTap:
                                            () =>
                                                _selectObjetivoPreset(objetivo),
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
                                _FxFormField(
                                  controller: _objetivoCtrl,
                                  label: 'Outro objetivo',
                                  hint: 'Ex.: ReabilitaÃ§Ã£o',
                                  icon: Icons.flag_outlined,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ],
                              AlunoChoiceSection(
                                label: 'GÃªnero',
                                isDark: isDark,
                                showDividerAbove: true,
                                child: AlunoSegmentedChoice(
                                  isDark: isDark,
                                  options: [
                                    for (final g in _generos)
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
                                    _tiposConsultoria.length,
                                    (i) => (
                                      value: _tiposConsultoria[i],
                                      label: _tiposConsultoriaLabel[i],
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
                                    '$_firstName entra na lista com senha provisÃ³ria'
                                    '${_whatsappCtrl.text.trim().isNotEmpty ? ' e WhatsApp pronto pra enviar.' : '. VocÃª copia o convite.'}',
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
                                title: 'NÃ£o foi possÃ­vel cadastrar',
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
