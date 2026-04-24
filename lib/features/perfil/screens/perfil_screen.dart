import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/design_tokens.dart';
import '../providers/perfil_provider.dart';

// ─── Cloudinary ──────────────────────────────────────────────────────────────
const _kCloudName    = 'focux';
const _kUploadPreset = 'focux_unsigned';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _uploadingPhoto = false;

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
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_kCloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _kUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamed = await request.send();
      final body     = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) {
        throw Exception('Cloudinary error ${streamed.statusCode}: $body');
      }
      final logoUrl = (jsonDecode(body) as Map<String, dynamic>)['secure_url'] as String;

      await ref.read(perfilRepositoryProvider).atualizar(logoUrl: logoUrl);
      ref.invalidate(perfilProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto atualizada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Meu Perfil'),
      ),
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (perfil) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar com botão de foto ──────────────────────────────
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.brandSoft,
                      backgroundImage: perfil.logoUrl != null
                          ? NetworkImage(perfil.logoUrl!)
                          : null,
                      child: perfil.logoUrl == null
                          ? Text(
                              perfil.nome.isNotEmpty ? perfil.nome[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: isDark ? EagleTokens.darkInk : EagleTokens.brand,
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
                          color: EagleTokens.brand,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? EagleTokens.darkBg : EagleTokens.paper,
                            width: 2,
                          ),
                        ),
                        child: _uploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Nome e email ──────────────────────────────────────────
              Center(
                child: Text(
                  perfil.nome,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Center(
                child: Text(
                  perfil.email,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: Text('Plano: ${perfil.plano}'),
                  backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.brandSoft,
                ),
              ),
              const SizedBox(height: 20),

              // ── Dados profissionais ───────────────────────────────────
              _SectionCard(
                title: 'Dados profissionais',
                isDark: isDark,
                children: [
                  _InfoRow(label: 'CREF', value: perfil.cref ?? '—', isDark: isDark),
                  _InfoRow(label: 'Especialidade', value: perfil.especialidade ?? '—', isDark: isDark),
                  if ((perfil.especialidades ?? '').isNotEmpty)
                    _InfoRow(label: 'Áreas', value: perfil.especialidades!, isDark: isDark),
                  if ((perfil.instagram ?? '').isNotEmpty)
                    _InfoRow(label: 'Instagram', value: '@${perfil.instagram!}', isDark: isDark),
                ],
              ),

              // ── Bio ───────────────────────────────────────────────────
              if ((perfil.descricaoProfissional ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Bio',
                  isDark: isDark,
                  children: [
                    Text(
                      perfil.descricaoProfissional!,
                      style: TextStyle(
                        color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Editar perfil'),
                onPressed: () async {
                  final atualizado = await context.push<bool>('/perfil/editar', extra: perfil);
                  if (atualizado == true) ref.invalidate(perfilProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? EagleTokens.darkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
