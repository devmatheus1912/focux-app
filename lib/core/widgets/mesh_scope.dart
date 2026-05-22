import 'package:flutter/material.dart';

/// Marks that [CinematicMeshBackground] is already active in an ancestor shell.
class MeshScope extends InheritedWidget {
  const MeshScope({super.key, required this.active, required super.child});

  final bool active;

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MeshScope>()?.active ?? false;

  @override
  bool updateShouldNotify(MeshScope oldWidget) => active != oldWidget.active;
}
