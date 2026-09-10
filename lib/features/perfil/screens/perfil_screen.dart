import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../pacotes/providers/pacotes_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/perfil_plan_labels.dart';
import '../utils/perfil_readiness.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../constants/perfil_layout.dart';
import '../widgets/perfil_appearance_section.dart';
import '../widgets/perfil_conta_seguranca_section.dart';
import '../widgets/perfil_marca_vitrine_section.dart';
import '../widgets/perfil_operacao_section.dart';
import '../widgets/perfil_sticky_bar.dart';
import '../widgets/perfil_loading_scaffold.dart';
import '../widgets/perfil_error_scaffold.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_settings_group.dart';
import 'package:focux_app/core/widgets/fx_settings_tile.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

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
  var _viewTracked = false;
  DateTime? _fetchedAt;
  bool _mfaAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadMfaCapability();
  }

  Future<void> _loadMfaCapability() async {
    try {
      final caps = await ref.read(authRepositoryProvider).capabilities();
      if (!mounted) return;
      setState(() => _mfaAvailable = caps.personalMfaTotpAvailable);
    } catch (_) {
      // MFA tile fica oculto se capabilities falhar.
    }
  }

  Future<void> _refreshHub() async {
    ref.invalidate(perfilProvider);
    ref.invalidate(dashboardHomeProvider);
    ref.invalidate(dashboardProvider);
    invalidatePacotesCaches(ref);
    unawaited(AnalyticsService.instance.track(ProductEvents.perfilRefreshed));
    setState(() => _fetchedAt = DateTime.now());
  }

  void _markFetched() {
    _fetchedAt ??= DateTime.now();
  }

  void _trackViewedOnce({required bool profileComplete}) {
    if (_viewTracked) return;
    _viewTracked = true;
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.perfilViewed,
        props: {'profileComplete': profileComplete},
      ),
    );
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
      invalidatePacotesCaches(ref);

      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Foto atualizada com sucesso.');
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(error, fallback: 'Não foi possível enviar a foto agora.'),
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
      invalidatePacotesCaches(ref);
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Perfil atualizado.',
        reserveBottom: 96,
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Sair da conta',
      message: 'Deseja encerrar esta sessão neste aparelho?',
      confirmLabel: 'Sair',
      icon: Icons.logout_rounded,
      destructive: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }


  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final cachedPlano = DashboardHomeClientCache.getIfFresh()?.planoFeatures;
    if (cachedPlano != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        if (ref.read(planoFeaturesProvider).valueOrNull != null) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(cachedPlano);
      });
    }

    return fxScreenA11yScope(
      label: 'Perfil',
      child: perfilAsync.when(
        loading: () => const PerfilLoadingScaffold(),
        error:
            (error, _) => PerfilErrorScaffold(
              error: error,
              onRetry: () => ref.invalidate(perfilProvider),
            ),
        data: (perfil) {
          _markFetched();
          final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
          final readiness = PerfilReadinessView.from(perfil);
          _trackViewedOnce(profileComplete: readiness.score >= 100);

          return _PerfilBody(
            perfil: perfil,
            uploadingPhoto: _uploadingPhoto,
            showMfa: _mfaAvailable,
            freshnessLabel: freshnessLabel,
            onRefresh: _refreshHub,
            onPickPhoto: _pickAndUploadPhoto,
            onEditPerfil: () => _openEditPerfil(perfil),
            onLogout: _logout,
            onOpenLandingEditor:
                () => openLandingEditorOrUpgrade(context, ref),
          );
        },
      ),
    );
  }
}
