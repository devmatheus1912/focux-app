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
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../providers/alunos_provider.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/utils/friendly_error.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno_invite_copy.dart';

part 'add_aluno_screen_widgets.part.dart';

const _generos = ['Masculino', 'Feminino', 'Outro'];
const _tiposConsultoria = ['ONLINE', 'PRESENCIAL', 'HIBRIDO'];
const _tiposConsultoriaLabel = ['Online', 'Presencial', 'Híbrido'];
const _objetivosRapidos = [
  'Hipertrofia',
  'Emagrecimento',
  'Força',
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
      final whatsapp = _whatsappCtrl.text.trim();
      final novoAluno = await ref
          .read(alunoRepositoryProvider)
          .criar(
            nome: _nomeCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            objetivo: objetivo.isEmpty ? null : objetivo,
            whatsapp: whatsapp.isEmpty ? null : whatsapp,
            genero: _genero,
            tipoConsultoria: _tipoConsultoria,
          );

      if (!mounted) return;
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
        fallback: 'Não foi possível cadastrar o aluno. Revise os dados.',
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
                header: 'Senha provisória',
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
          subtitle: 'Cadastro rápido',
          onBack: () => safePopOrGo(context, '/alunos'),
        ),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      8,
                      TokensStrip.s4,
                      96,
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
                          const SizedBox(height: TokensStrip.s4),
                          FxSettingsGroup(
                            header: 'Identidade',
                            caption: 'Acesso e contato.',
                            children: [
                              _FxFormField(
                                controller: _nomeCtrl,
                                label: 'Nome completo',
                                hint: 'Ex.: Beatriz Andrade',
                                icon: Icons.person_outline_rounded,
                                isDark: isDark,
                                validator:
                                    (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Informe o nome completo.'
                                            : null,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 14),
                              _FxFormField(
                                controller: _emailCtrl,
                                label: 'E-mail',
                                hint: 'aluno@email.com',
                                icon: Icons.alternate_email_rounded,
                                isDark: isDark,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) {
                                    return 'Informe o e-mail.';
                                  }
                                  if (!RegExp(_emailPattern).hasMatch(value)) {
                                    return 'Informe um e-mail válido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _FxFormField(
                                controller: _whatsappCtrl,
                                label: 'WhatsApp',
                                helper:
                                    'Opcional. Se preencher, abrimos o WhatsApp com a mensagem pronta.',
                                hint: '(11) 99999-9999',
                                icon: Icons.phone_outlined,
                                isDark: isDark,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxSettingsGroup(
                            header: 'Perfil inicial',
                            caption: 'Filtros e atendimento.',
                            children: [
                              _LabelRow(label: 'Objetivo', isDark: isDark),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._objetivosRapidos.map((objetivo) {
                                    final selected =
                                        !_objetivoLivre &&
                                        _objetivoCtrl.text.trim() == objetivo;
                                    return _OptionChip(
                                      label: objetivo,
                                      selected: selected,
                                      isDark: isDark,
                                      onTap:
                                          () => _selectObjetivoPreset(objetivo),
                                    );
                                  }),
                                  _OptionChip(
                                    label: 'Outro',
                                    selected: _objetivoLivre,
                                    isDark: isDark,
                                    onTap: _toggleObjetivoLivre,
                                  ),
                                ],
                              ),
                              if (_objetivoLivre) ...[
                                const SizedBox(height: 10),
                                _FxFormField(
                                  controller: _objetivoCtrl,
                                  label: 'Outro objetivo',
                                  hint: 'Ex.: Reabilitação',
                                  icon: Icons.flag_outlined,
                                  isDark: isDark,
                                  textCapitalization: TextCapitalization.words,
                                ),
                              ],
                              const SizedBox(height: 18),
                              _LabelRow(label: 'Gênero', isDark: isDark),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _generos.map((g) {
                                      return _OptionChip(
                                        label: g,
                                        selected: _genero == g,
                                        isDark: isDark,
                                        onTap:
                                            () => setState(
                                              () =>
                                                  _genero =
                                                      _genero == g ? null : g,
                                            ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 18),
                              _LabelRow(label: 'Consultoria', isDark: isDark),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  _tiposConsultoria.length,
                                  (i) {
                                    final value = _tiposConsultoria[i];
                                    return _OptionChip(
                                      label: _tiposConsultoriaLabel[i],
                                      selected: _tipoConsultoria == value,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () =>
                                                _tipoConsultoria =
                                                    _tipoConsultoria == value
                                                        ? null
                                                        : value,
                                          ),
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
                                    '$_firstName entra na lista com senha provisória'
                                    '${_whatsappCtrl.text.trim().isNotEmpty ? ' e WhatsApp pronto pra enviar.' : '. Você copia o convite.'}',
                                    style: FxSettingsLayout.subhead(
                                      color: chrome.mute,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
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
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      TokensStrip.s4,
                      12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _canSubmit
                              ? 'O convite de $_firstName será preparado após o cadastro.'
                              : 'Complete nome e e-mail para cadastrar',
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                          ).copyWith(fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        DashboardHomeActionChip(
                          label: _loading ? 'Cadastrando…' : 'Cadastrar',
                          accent: primary,
                          isDark: isDark,
                          enabled: _canSubmit && !_loading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
