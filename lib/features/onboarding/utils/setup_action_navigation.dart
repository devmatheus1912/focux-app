import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../widgets/setup_step_widgets.dart';

/// `/perfil/editar` exige [PerfilPersonal] no `extra`; sem isso o router
/// redireciona para o hub `/perfil`. Setup sempre carrega o perfil antes.
bool isSetupPerfilEditRoute(String route) =>
    normalizeSetupActionRoute(route) == '/perfil/editar';

Future<T?> pushSetupActionRoute<T extends Object?>(
  BuildContext context,
  WidgetRef ref,
  String route,
) async {
  final normalized = normalizeSetupActionRoute(route);
  if (normalized == '/perfil/editar') {
    try {
      final perfil = await ref.read(perfilProvider.future);
      if (!context.mounted) return null;
      return context.push<T>('/perfil/editar', extra: perfil);
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
      return null;
    }
  }
  if (!context.mounted) return null;
  return context.push<T>(normalized);
}
