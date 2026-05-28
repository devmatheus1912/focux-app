import 'package:flutter/material.dart';

import '../../../core/theme/tokens_strip.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_controller.dart';
import 'landing_editor_shared_widgets.dart';

class LandingEditorOrderTab extends StatelessWidget {
  const LandingEditorOrderTab({
    super.key,
    required this.controller,
    required this.onReorder,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final LandingEditorController controller;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index) onMoveUp;
  final void Function(int index) onMoveDown;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ListView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        const LandingEditorSectionHeader(
          title: 'Ordem das seções',
          hint:
              'Arraste pelo ícone ≡ ou use as setas. A abertura sempre fica no topo da página.',
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: c.sectionOrder.length,
          onReorder: onReorder,
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(animation.value);
                final scheme = Theme.of(context).colorScheme;
                return Material(
                  elevation: 4 + 8 * t,
                  shadowColor: scheme.primary.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  color: scheme.surface,
                  child: child,
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, i) {
            return LandingSectionOrderTile(
              key: ValueKey('section-${c.sectionOrder[i]}-$i'),
              index: i,
              sectionKey: c.sectionOrder[i],
              highlighted: c.highlightedSectionKey == c.sectionOrder[i],
              canMoveUp: i > 0,
              canMoveDown: i < c.sectionOrder.length - 1,
              onMoveUp: () => onMoveUp(i),
              onMoveDown: () => onMoveDown(i),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
