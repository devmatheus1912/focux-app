import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../../../core/utils/friendly_error.dart';

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
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _crefCtrl.dispose();
    _especialidadeCtrl.dispose();
    _especialidadesCtrl.dispose();
    _instagramCtrl.dispose();
    _bioCtrl.dispose();
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

  Future<void> _submit() async {
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
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() => _error = 'Erro ao salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final chrome = ShellChrome.forDark(isDark);

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Editar Perfil',
        subtitle: 'PERFIL',
        onBack: () => safePopOrGo(context, '/perfil'),
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
            TokensStrip.s5,
            12,
            TokensStrip.s5,
            12,
          ),
          child: SafeArea(
            top: false,
            child: Semantics(
              button: true,
              enabled: !_loading,
              label:
                  _loading
                      ? 'Salvando alterações do perfil'
                      : 'Salvar alterações do perfil',
              child: FxLiquidPrimaryButton(
                label: 'Salvar alterações',
                loadingLabel: 'Salvando…',
                loading: _loading,
                onPressed: _loading ? null : _submit,
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
              TokensStrip.s5,
              8,
              TokensStrip.s5,
              24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    button: true,
                    enabled: !_uploadingPhoto,
                    label:
                        _uploadingPhoto
                            ? 'Enviando foto do perfil'
                            : 'Foto do perfil. Toque no ícone da câmera para trocar a foto',
                    child: Center(
                      child: FxGlowSurface(
                        color: primary,
                        enabled: true,
                        intensity: 0.7,
                        borderRadius: 999,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: primary.withValues(alpha: 0.12),
                              backgroundImage:
                                  _logoUrl != null
                                      ? NetworkImage(_logoUrl!)
                                      : null,
                              child:
                                  _logoUrl == null
                                      ? Text(
                                        widget.perfil.nome.isNotEmpty
                                            ? widget.perfil.nome[0]
                                                .toUpperCase()
                                            : '?',
                                        style: AppTypography.inter(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: primary,
                                        ),
                                      )
                                      : null,
                            ),
                            GestureDetector(
                              onTap:
                                  _uploadingPhoto ? null : _pickAndUploadPhoto,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? EagleTokens.darkBg
                                            : TokensStrip.pageBg,
                                    width: 2,
                                  ),
                                ),
                                child:
                                    _uploadingPhoto
                                        ? const Padding(
                                          padding: EdgeInsets.all(7),
                                          child: FxLoading(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Toque no ícone para trocar a foto',
                      style: TextStyle(fontSize: 12, color: mute),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FxStaggerItem(
                    index: 0,
                    child: _SectionCard(
                      title: 'Dados pessoais',
                      showHint: true,
                      child: Column(
                        children: [
                          Semantics(
                            label: 'Nome completo',
                            child: TextFormField(
                              controller: _nomeCtrl,
                              decoration: FxInputDeco.build(
                                context,
                                'Nome completo',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Telefone ou WhatsApp',
                            child: TextFormField(
                              controller: _telefoneCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [BrPhone.formatter()],
                              decoration: FxInputDeco.build(
                                context,
                                'Telefone / WhatsApp',
                                icon: Icons.phone_iphone_rounded,
                                hint: '(11) 99999-0000',
                              ),
                              validator: BrPhone.validateOptional,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FxStaggerItem(
                    index: 1,
                    child: _SectionCard(
                      title: 'Dados profissionais',
                      child: Column(
                        children: [
                          Semantics(
                            label: 'CREF opcional',
                            child: TextFormField(
                              controller: _crefCtrl,
                              decoration: FxInputDeco.build(
                                context,
                                'CREF (opcional)',
                                icon: Icons.badge_outlined,
                                hint: 'Ex: 012345-G/SP',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Especialidade principal',
                            child: TextFormField(
                              controller: _especialidadeCtrl,
                              decoration: FxInputDeco.build(
                                context,
                                'Especialidade principal',
                                icon: Icons.fitness_center_outlined,
                                hint: 'Ex: Musculação',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Áreas de atuação opcional',
                            child: TextFormField(
                              controller: _especialidadesCtrl,
                              decoration: FxInputDeco.build(
                                context,
                                'Áreas de atuação (opcional)',
                                icon: Icons.category_outlined,
                                hint: 'Ex: Funcional, Hipertrofia',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Instagram opcional',
                            child: TextFormField(
                              controller: _instagramCtrl,
                              decoration: FxInputDeco.build(
                                context,
                                'Instagram (opcional)',
                                icon: Icons.alternate_email_rounded,
                                hint: 'seuusuario',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FxStaggerItem(
                    index: 2,
                    child: _SectionCard(
                      title: 'Bio / Apresentação',
                      child: Semantics(
                        label: 'Sobre você, até 500 caracteres',
                        child: TextFormField(
                          controller: _bioCtrl,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: FxInputDeco.build(
                            context,
                            'Sobre você (opcional)',
                            icon: Icons.notes_rounded,
                            hint:
                                'Conte sua história, metodologia e diferenciais...',
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      label: _error!,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: EagleTokens.bad),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.showHint = false,
  });

  final String title;
  final Widget child;
  final bool showHint;

  static const _hintCopy =
      'Campos usados no perfil comercial e na experiência do aluno.';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final a11y = showHint ? '$title. $_hintCopy' : title;

    return Semantics(
      container: true,
      label: a11y,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.inter(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            if (showHint) ...[
              const SizedBox(height: 4),
              Text(
                _hintCopy,
                style: TextStyle(color: mute, fontSize: 11.5, height: 1.3),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
