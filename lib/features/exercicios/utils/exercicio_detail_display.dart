String exercicioHubSubtitle({
  required String? grupo,
  String? freshness,
}) {
  final parts = <String>[];
  final group = grupo?.trim();
  if (group != null && group.isNotEmpty) parts.add(group);
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}
