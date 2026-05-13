import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

// ─── Cloudinary ──────────────────────────────────────────────────────────────
class EditarPerfilScreen extends ConsumerStatefulWidget {
  final PerfilPersonal perfil;

  const EditarPerfilScreen({super.key, required this.perfil});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
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
    _crefCtrl.dispose();
    _especialidadeCtrl.dispose();
    _especialidadesCtrl.dispose();
    _instagramCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
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
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(perfilRepositoryProvider)
          .atualizar(
            nome: _nomeCtrl.text.trim(),
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
      setState(() {
        _error = 'Erro ao salvar. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = primary.withValues(alpha: 0.12);

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Editar Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Avatar com botão de troca ─────────────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor:
                            isDark ? EagleTokens.darkCard : primarySoft,
                        backgroundImage:
                            _logoUrl != null ? NetworkImage(_logoUrl!) : null,
                        child:
                            _logoUrl == null
                                ? Text(
                                  widget.perfil.nome.isNotEmpty
                                      ? widget.perfil.nome[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark ? EagleTokens.darkInk : primary,
                                  ),
                                )
                                : null,
                      ),
                      GestureDetector(
                        onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  isDark
                                      ? EagleTokens.darkBg
                                      : EagleTokens.paper,
                              width: 2,
                            ),
                          ),
                          child:
                              _uploadingPhoto
                                  ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: FxLoading(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Toque no ícone para trocar a foto',
                    style: TextStyle(fontSize: 12, color: EagleTokens.inkMute),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Dados básicos ─────────────────────────────────────
                _SectionLabel(text: 'Dados pessoais', isDark: isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator:
                      (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),

                // ── Dados profissionais ───────────────────────────────
                _SectionLabel(text: 'Dados profissionais', isDark: isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _crefCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CREF (opcional)',
                    hintText: 'Ex: 012345-G/SP',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _especialidadeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Especialidade principal',
                    hintText: 'Ex: Musculação',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _especialidadesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Áreas de atuação (opcional)',
                    hintText: 'Ex: Funcional, Hipertrofia, Emagrecimento',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instagram (opcional)',
                    hintText: 'Ex: seuusuario (sem o @)',
                    prefixText: '@',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Bio ───────────────────────────────────────────────
                _SectionLabel(text: 'Bio / Apresentação', isDark: isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Sobre você (opcional)',
                    hintText:
                        'Conte sua história, metodologia e diferenciais...',
                    alignLabelWithHint: true,
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: EagleTokens.bad)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child:
                      _loading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: FxLoading(strokeWidth: 2),
                          )
                          : const Text('Salvar alterações'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;

  const _SectionLabel({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
        letterSpacing: 0.5,
      ),
    );
  }
}
