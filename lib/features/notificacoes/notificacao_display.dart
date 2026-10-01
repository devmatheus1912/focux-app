import 'data/notificacoes_repository.dart';

const notificacaoComoCalculamos =
    'Avisos operacionais do estúdio: mensalidade, feed, trial e Radar. Mensagens de chat ficam só na inbox de chat.';

String notificacaoNaoLidasLabel(int unread) {
  if (unread <= 0) return 'Tudo lido';
  if (unread == 1) return '1 não lida';
  return '$unread não lidas';
}

String notificacaoSearchEmptyTitle(String query) =>
    query.trim().isEmpty ? 'Tudo em ordem' : 'Nenhum aviso encontrado';

String notificacaoSearchEmptySubtitle(String query) => query.trim().isEmpty
    ? 'Alertas financeiros, novidades do feed e sinais do Radar aparecem aqui.'
    : 'Nada com esse texto nesta caixa.';

String notificacaoVazioTitle({required String query, required bool soNaoLidas}) {
  if (query.trim().isEmpty && soNaoLidas) return 'Nada pendente';
  return notificacaoSearchEmptyTitle(query);
}

String notificacaoVazioSubtitle({
  required String query,
  required bool soNaoLidas,
}) {
  if (query.trim().isEmpty && soNaoLidas) {
    return 'Você leu todos os avisos. As lidas continuam em Todas.';
  }
  return notificacaoSearchEmptySubtitle(query);
}

String notificacaoRemovidasLabel(int n) {
  if (n <= 0) return 'Nada para limpar.';
  if (n == 1) return '1 notificação apagada.';
  return '$n notificações apagadas.';
}

String notificacaoFiltroNaoLidasLabel(int unread) =>
    unread > 0 ? 'Não lidas · $unread' : 'Não lidas';

List<NotificacaoApp> notificacoesVisiveis(
  List<NotificacaoApp> items, {
  Set<int> ocultas = const {},
  bool soNaoLidas = false,
}) {
  return items
      .where((n) => !ocultas.contains(n.id) && (!soNaoLidas || !n.lida))
      .toList();
}

const _nameParticles = {'de', 'da', 'do', 'dos', 'das', 'e'};

/// Title-case person names from API payloads (e.g. `thales` → `Thales`).
String formatDisplayName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  return trimmed
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        final lower = word.toLowerCase();
        if (_nameParticles.contains(lower)) return lower;
        if (lower.length == 1) return lower.toUpperCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String normalizeNotificationText(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Collapses duplicate Radar rows (same aluno + mesma ação + mesma rota).
String radarSignalDedupeKey({
  required String displayName,
  required String summary,
  String route = '',
}) {
  return [
    normalizeNotificationText(displayName),
    normalizeNotificationText(summary),
    normalizeNotificationText(route),
  ].join('|');
}
