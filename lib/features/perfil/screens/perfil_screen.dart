import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/env.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../pacotes/providers/pacotes_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/brand_slogan_display.dart';
import '../utils/perfil_plan_labels.dart';
import '../utils/perfil_professional_summary.dart';
import '../utils/perfil_readiness.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../constants/perfil_layout.dart';
import '../widgets/landing_editor_widgets.dart';
import '../widgets/perfil_card_section.dart';
import '../widgets/perfil_conta_seguranca_section.dart';
import '../widgets/perfil_marca_vitrine_section.dart';
import '../widgets/perfil_operacao_section.dart';
import '../widgets/perfil_quiet_collapsible.dart';
import '../widgets/perfil_sticky_bar.dart';
import '../widgets/perfil_loading_scaffold.dart';
import '../widgets/perfil_error_scaffold.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
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

  Future<void> _refreshHub() async {
    ref.invalidate(perfilProvider);
    ref.invalidate(dashboardHomeProvider);
    ref.invalidate(dashboardProvider);
    invalidatePacotesCaches(ref);
    unawaited(
      AnalyticsService.instance.track(ProductEvents.perfilRefreshed),
    );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Sair da conta'),
            content: const Text('Deseja encerrar esta sessão neste aparelho?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
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
    // Landing Completa / gates usam planoFeaturesProvider (seed do cache home
    // abaixo). Dashboard home aqui NÃO é só planoFeatures: a faixa do hero
    // precisa de totalAlunos + alunosAtivos. Preferimos cache fresco; só
    // disparamos GET /api/dashboard/home em cache miss.
    final cachedHome = DashboardHomeClientCache.getIfFresh();
    final cachedPersonal = cachedHome?.personal;
    final cachedPlano = cachedHome?.planoFeatures;
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
          final readiness = PerfilReadinessView.from(
            perfil: perfil,
            dashboard:
                cachedPersonal ??
                DashboardData(
                  totalAlunos: 0,
                  alunosAtivos: 0,
                  planoAtual: perfil.plano,
                  limiteAlunos: 0,
                  nomePersonal: perfil.nome,
                ),
          );
          _trackViewedOnce(profileComplete: readiness.score >= 100);

          if (cachedPersonal != null) {
            return _PerfilBody(
              perfil: perfil,
              dashboard: cachedPersonal,
              uploadingPhoto: _uploadingPhoto,
              freshnessLabel: freshnessLabel,
              onRefresh: _refreshHub,
              onPickPhoto: _pickAndUploadPhoto,
              onEditPerfil: () => _openEditPerfil(perfil),
              onLogout: _logout,
              onOpenLandingEditor:
                  () => openLandingEditorOrUpgrade(context, ref),
              onChecklistAction:
                  (action) => _handleChecklistAction(action, perfil),
            );
          }

          final dashboardAsync = ref.watch(dashboardProvider);
          return dashboardAsync.when(
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
                  freshnessLabel: freshnessLabel,
                  onRefresh: _refreshHub,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onOpenLandingEditor:
                      () => openLandingEditorOrUpgrade(context, ref),
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
                  freshnessLabel: freshnessLabel,
                  onRefresh: _refreshHub,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onOpenLandingEditor:
                      () => openLandingEditorOrUpgrade(context, ref),
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
                ),
            data:
                (dashboard) => _PerfilBody(
                  perfil: perfil,
                  dashboard: dashboard,
                  uploadingPhoto: _uploadingPhoto,
                  freshnessLabel: freshnessLabel,
                  onRefresh: _refreshHub,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onOpenLandingEditor:
                      () => openLandingEditorOrUpgrade(context, ref),
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
                ),
          );
        },
      ),
    );
  }
}
