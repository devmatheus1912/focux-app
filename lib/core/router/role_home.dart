import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

String roleHomePath(WidgetRef ref) {
  final status = ref.read(authProvider);
  if (status != AuthStatus.authenticated) return '/login';

  final role = ref.read(authProvider.notifier).currentRole;
  return role == UserRole.aluno ? '/dashboard/aluno' : '/dashboard/personal';
}

void goToRoleHome(BuildContext context, WidgetRef ref) {
  final target = roleHomePath(ref);
  final router = GoRouter.of(context);
  if (router.routeInformationProvider.value.uri.path ==
      Uri.parse(target).path) {
    return;
  }
  router.go(target);
}

class HomeRedirectScreen extends ConsumerWidget {
  const HomeRedirectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(authProvider);
    if (status == AuthStatus.unknown) {
      return const Scaffold(body: Center(child: FxLoading()));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) goToRoleHome(context, ref);
    });

    return const Scaffold(body: SizedBox.shrink());
  }
}
