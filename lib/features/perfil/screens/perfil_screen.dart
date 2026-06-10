import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/api/api_client.dart';
import '../../../core/legal/focux_legal.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/brand_slogan_display.dart';
import '../utils/perfil_plan_labels.dart';
import '../utils/perfil_readiness.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../../dashboard/widgets/gated_profile_shortcuts.dart';
import '../widgets/landing_editor_widgets.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';

part 'perfil_screen_widgets_a.part.dart';
part 'perfil_screen_widgets_b.part.dart';
part 'perfil_screen_panels_a.part.dart';
part 'perfil_screen_panels_b.part.dart';


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
      final logoUrl = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'perfil',
        resourceType: 'image',
      );

      await ref.read(perfilRepositoryProvider).atualizar(logoUrl: logoUrl);
      ref.invalidate(perfilProvider);
      ref.invalidate(dashboardHomeProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback: 'Não foi possível enviar a foto agora.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _openEditPerfil(PerfilPersonal perfil) async {
    final updated = await context.push<bool>('/perfil/editar', extra: perfil);
    if (updated == true) {
      ref.invalidate(perfilProvider);
      ref.invalidate(dashboardHomeProvider);
      ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _handleChecklistAction(
    PerfilChecklistAction action,
    PerfilPersonal perfil,
  ) async {
    switch (action) {
      case PerfilChecklistAction.photo:
        await _pickAndUploadPhoto();
      case PerfilChecklistAction.editProfile:
        await _openEditPerfil(perfil);
      case PerfilChecklistAction.brand:
        if (mounted) context.push('/identidade-visual');
      case PerfilChecklistAction.wallet:
        if (mounted) context.push('/perfil/wallet');
      case PerfilChecklistAction.convites:
        if (mounted) context.push('/convites');
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return perfilAsync.when(
      loading: () => const _PerfilLoadingScaffold(),
      error:
          (error, _) => _PerfilErrorScaffold(
            error: error,
            onRetry: () => ref.invalidate(perfilProvider),
          ),
      data:
          (perfil) => dashboardAsync.when(
            loading:
                () => _PerfilBody(
                  perfil: perfil,
                  dashboard: DashboardData(
                    totalAlunos: 0,
                    alunosAtivos: 0,
                    planoAtual: perfil.plano,
                    limiteAlunos: 0,
                    nomePersonal: perfil.nome,
                    logoUrl: perfil.logoUrl,
                    corPrimaria: perfil.corPrimaria,
                    corSecundaria: perfil.corSecundaria,
                    descricaoProfissional: perfil.descricaoProfissional,
                    instagram: perfil.instagram,
                  ),
                  uploadingPhoto: _uploadingPhoto,
                  loadingMetrics: true,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onOpenLandingEditor: () => openLandingEditorOrUpgrade(context, ref),
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
                ),
            error:
                (_, __) => _PerfilBody(
                  perfil: perfil,
                  dashboard: DashboardData(
                    totalAlunos: 0,
                    alunosAtivos: 0,
                    planoAtual: perfil.plano,
                    limiteAlunos: 0,
                    nomePersonal: perfil.nome,
                    logoUrl: perfil.logoUrl,
                    corPrimaria: perfil.corPrimaria,
                    corSecundaria: perfil.corSecundaria,
                    descricaoProfissional: perfil.descricaoProfissional,
                    instagram: perfil.instagram,
                  ),
                  uploadingPhoto: _uploadingPhoto,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onOpenLandingEditor: () => openLandingEditorOrUpgrade(context, ref),
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
                ),
            data:
                (dashboard) => _PerfilBody(
                  perfil: perfil,
                  dashboard: dashboard,
                  uploadingPhoto: _uploadingPhoto,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onOpenLandingEditor: () => openLandingEditorOrUpgrade(context, ref),
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
                ),
          ),
    );
  }
}

