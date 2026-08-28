import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../pacotes/providers/pacotes_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../widgets/editar_perfil_help_sheet.dart';

part 'editar_perfil_screen_widgets.part.dart';

class EditarPerfilScreen extends ConsumerStatefulWidget {
  final PerfilPersonal perfil;

  const EditarPerfilScreen({super.key, required this.perfil});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telefoneCtrl;
  late final TextEditingController _crefCtrl;
  late final TextEditingController _especialidadeCtrl;
  late final TextEditingController _especialidadesCtrl;
  late final TextEditingController _instagramCtrl;
  late final TextEditingController _bioCtrl;

  bool _loading = false;
  bool _uploadingPhoto = false;
  String? _logoUrl;
  String? _error;

  bool get _nomeOk => _nomeCtrl.text.trim().isNotEmpty;

  bool get _isDirty {
    final baseline = widget.perfil;
    final telNow = BrPhone.normalizeOrNull(_telefoneCtrl.text) ?? '';
    final telBase = BrPhone.normalizeOrNull(baseline.telefone) ?? '';
    return _nomeCtrl.text.trim() != baseline.nome.trim() ||
        telNow != telBase ||
        _crefCtrl.text.trim() != (baseline.cref ?? '').trim() ||
        _especialidadeCtrl.text.trim() !=
            (baseline.especialidade ?? '').trim() ||
        _especialidadesCtrl.text.trim() !=
            (baseline.especialidades ?? '').trim() ||
        _instagramCtrl.text.trim() != (baseline.instagram ?? '').trim() ||
        _bioCtrl.text.trim() !=
            (baseline.descricaoProfissional ?? '').trim() ||
        (_logoUrl ?? '') != (baseline.logoUrl ?? '');
  }

  bool get _canSubmit => _nomeOk && _isDirty && !_loading && !_uploadingPhoto;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.perfil.nome);
    _telefoneCtrl = TextEditingController(
      text: BrPhone.formatDisplay(widget.perfil.telefone),
    );
    _crefCtrl = TextEditingController(text: widget.perfil.cref ?? '');
    _especialidadeCtrl = TextEditingController(
      text: widget.perfil.especialidade ?? '',
    );
    _especialidadesCtrl = TextEditingController(
      text: widget.perfil.especialidades ?? '',
    );
    _instagramCtrl = TextEditingController(text: widget.perfil.instagram ?? '');
    _bioCtrl = TextEditingController(
      text: widget.perfil.descricaoProfissional ?? '',
    );
    _logoUrl = widget.perfil.logoUrl;

    for (final c in [
      _nomeCtrl,
      _telefoneCtrl,
      _crefCtrl,
      _especialidadeCtrl,
      _especialidadesCtrl,
      _instagramCtrl,
      _bioCtrl,
    ]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _nomeCtrl,
      _telefoneCtrl,
      _crefCtrl,
      _especialidadeCtrl,
      _especialidadesCtrl,
      _instagramCtrl,
      _bioCtrl,
    ]) {
      c
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'perfil',
        resourceType: 'image',
      );
      if (mounted) setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  void _invalidateAfterSave() {
    ref.invalidate(perfilProvider);
    ref.invalidate(dashboardHomeProvider);
    ref.invalidate(dashboardProvider);
    invalidatePacotesCaches(ref);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_canSubmit) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(perfilRepositoryProvider)
          .atualizar(
            nome: _nomeCtrl.text.trim(),
            telefone: BrPhone.normalizeOrNull(_telefoneCtrl.text) ?? '',
            cref: _crefCtrl.text.trim().isEmpty ? null : _crefCtrl.text.trim(),
            especialidade:
                _especialidadeCtrl.text.trim().isEmpty
                    ? null
                    : _especialidadeCtrl.text.trim(),
            logoUrl: _logoUrl,
            especialidades:
                _especialidadesCtrl.text.trim().isEmpty
                    ? null
                    : _especialidadesCtrl.text.trim(),
            instagram:
                _instagramCtrl.text.trim().isEmpty
                    ? null
                    : _instagramCtrl.text.trim(),
            descricaoProfissional:
                _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
          );
      if (!mounted) return;
      _invalidateAfterSave();
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.perfilUpdated,
          props: {
            'has_photo': (_logoUrl ?? '').isNotEmpty,
            'has_bio': _bioCtrl.text.trim().isNotEmpty,
          },
        ),
      );
      HapticFeedback.heavyImpact();
      context.pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);

    return fxScreenA11yScope(
      label: 'Editar Perfil',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Editar Perfil',
          subtitle: 'Conta e marca comercial',
          onBack: () => safePopOrGo(context, '/perfil'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como editar o perfil',
              onTap: () => showEditarPerfilHelpSheet(context),
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  TokensStrip.s4,
                  6,
                  TokensStrip.s4,
                  88 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FxStaggerItem(
                        index: 0,
                        child: FxSettingsGroup(
                          header: 'Foto',
                          caption: 'Aparece no app e na página pública.',
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: TokensStrip.s3,
                              ),
                              child: _PerfilPhotoEditor(
                                logoUrl: _logoUrl,
                                nome: _nomeCtrl.text.isNotEmpty
                                    ? _nomeCtrl.text
                                    : widget.perfil.nome,
                                uploading: _uploadingPhoto,
                                isDark: isDark,
                                primary: primary,
                                onTap: _pickAndUploadPhoto,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxStaggerItem(
                        index: 1,
                        child: FxSettingsGroup(
                          header: 'Dados pessoais',
                          caption:
                              'Usado no perfil comercial e no contato com alunos.',
                          children: [
                            _PerfilFormField(
                              controller: _nomeCtrl,
                              label: 'Nome completo',
                              icon: Icons.person_outline_rounded,
                              soft: soft,
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                              textCapitalization: TextCapitalization.words,
                            ),
                            _PerfilFormField(
                              controller: _telefoneCtrl,
                              label: 'Telefone / WhatsApp',
                              hint: '(11) 99999-0000',
                              icon: Icons.phone_iphone_rounded,
                              soft: soft,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [BrPhone.formatter()],
                              validator: BrPhone.validateOptional,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxStaggerItem(
                        index: 2,
                        child: FxSettingsGroup(
                          header: 'Dados profissionais',
                          caption:
                              'Especialidade primeiro; CREF e Instagram reforçam a vitrine.',
                          children: [
                            _PerfilFormField(
                              controller: _especialidadeCtrl,
                              label: 'Especialidade principal',
                              hint: 'Especialidade',
                              icon: Icons.fitness_center_outlined,
                              soft: soft,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            _PerfilFormField(
                              controller: _especialidadesCtrl,
                              label: 'Outras áreas',
                              hint: 'Funcional, emagrecimento…',
                              icon: Icons.category_outlined,
                              soft: soft,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            _PerfilFormField(
                              controller: _crefCtrl,
                              label: 'CREF',
                              hint: '012345-G/SP',
                              icon: Icons.badge_outlined,
                              soft: soft,
                            ),
                            _PerfilFormField(
                              controller: _instagramCtrl,
                              label: 'Instagram',
                              hint: '@seuusuario',
                              icon: Icons.alternate_email_rounded,
                              soft: soft,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxStaggerItem(
                        index: 3,
                        child: FxSettingsGroup(
                          header: 'Bio',
                          caption: 'Apresentação curta na landing (até 500).',
                          children: [
                            _PerfilFormField(
                              controller: _bioCtrl,
                              label: 'Sobre você (opcional)',
                              hint: 'Metodologia, público e diferenciais…',
                              icon: Icons.notes_rounded,
                              soft: soft,
                              maxLines: 4,
                              maxLength: 500,
                              showDivider: false,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: TokensStrip.s3),
                        Semantics(
                          liveRegion: true,
                          label: _error!,
                          child: FxErrorState(
                            chromeOnDark: chrome.isDark,
                            primary: primary,
                            message: _error!,
                            onRetry: _submit,
                            title: 'Não foi possível salvar',
                          ),
                        ),
                      ],
                    ],
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
                  child: Semantics(
                    button: true,
                    enabled: _canSubmit,
                    label:
                        _loading
                            ? 'Salvando alterações do perfil'
                            : _canSubmit
                            ? 'Salvar alterações do perfil'
                            : 'Salvar. Faça uma alteração para habilitar',
                    child: DashboardHomeActionChip(
                      label: _loading ? 'Salvando…' : 'Salvar',
                      accent: primary,
                      isDark: isDark,
                      enabled: _canSubmit,
                      onPressed: _submit,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
