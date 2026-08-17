import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/friendly_error.dart';
import 'fx_empty_state.dart';
import 'fx_error_state.dart';
import 'skeleton_loader.dart';

/// Home-parity AsyncValue body: skeleton → FxErrorState → empty → data.
class FxAsyncBody<T> extends StatelessWidget {
  const FxAsyncBody({
    super.key,
    required this.value,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.empty,
    this.skeletonCount = 6,
    this.skeleton,
    this.chromeOnDark,
    this.primary,
    this.errorTitle,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final int skeletonCount;
  final Widget? skeleton;
  final bool? chromeOnDark;
  final Color? primary;
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onDark = chromeOnDark ?? isDark;
    final accent = primary ?? Theme.of(context).colorScheme.primary;

    return value.when(
      loading:
          () =>
              skeleton ??
              Padding(
                padding: const EdgeInsets.all(16),
                child: SkeletonList(count: skeletonCount),
              ),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: onDark,
            primary: accent,
            message: friendlyError(e),
            onRetry: onRetry,
            title: errorTitle,
          ),
      data: (data) {
        if (isEmpty != null && isEmpty!(data)) {
          return empty ??
              const FxEmptyState(
                icon: 'inbox',
                title: 'Nada por aqui',
                subtitle: 'Quando houver dados, eles aparecem nesta tela.',
              );
        }
        return builder(context, data);
      },
    );
  }
}
