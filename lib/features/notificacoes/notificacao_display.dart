import 'data/notificacoes_repository.dart';
import '../../l10n/pt.dart';

final notificacaoComoCalculamos =
    ptS.notificacaoAvisosOperacionaisDoEstudioMensalidade;

String notificacaoNaoLidasLabel(int unread) {
  if (unread <= 0) return ptS.notificacaoTudoLido;
  if (unread == 1) return ptS.notificacao1NaoLida;
  return ptS.notificacaoNaoLidas(unread);
}

String notificacaoSearchEmptyTitle(String query) =>
    query.trim().isEmpty ? ptS.notificacaoTudoEmOrdem : ptS.notificacaoNenhumAvisoEncontrado;

String notificacaoSearchEmptySubtitle(String query) => query.trim().isEmpty
    ? ptS.notificacaoAlertasFinanceirosNovidadesDoFeed
    : ptS.notificacaoNadaComEsseTextoNesta;

String notificacaoVazioTitle({required String query, required bool soNaoLidas}) {
  if (query.trim().isEmpty && soNaoLidas) return ptS.notificacaoNadaPendente;
  return notificacaoSearchEmptyTitle(query);
}

String notificacaoVazioSubtitle({
  required String query,
  required bool soNaoLidas,
}) {
  if (query.trim().isEmpty && soNaoLidas) {
    return ptS.notificacaoVoceLeuTodosOsAvisos;
  }
  return notificacaoSearchEmptySubtitle(query);
}

String notificacaoRemovidasLabel(int n) {
  if (n <= 0) return ptS.notificacaoNadaParaLimpar;
  if (n == 1) return ptS.notificacao1NotificacaoApagada;
  return ptS.notificacaoNotificacoesApagadas(n);
}

/// Com a lista inteira na tela, o número é o das linhas (avisos iguais viram
/// uma); senão, o total do servidor.
int notificacaoNaoLidasDaTela({
  required int servidor,
  required int? naLista,
  required bool listaCompleta,
}) => listaCompleta && naLista != null ? naLista : servidor;

/// Busca só faz sentido com lista longa.
const notificacaoBuscaAPartirDe = 15;

String notificacaoFiltroNaoLidasLabel(int unread) =>
    unread > 0 ? ptS.notificacaoNaoLidas2(unread) : ptS.notificacaoNaoLidas3;

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

/// Nome limpo do payload: sem traço solto e com maiúscula ("João -" → "João").
String notificacaoNomeLimpo(String raw) => formatDisplayName(
  raw.trim().replaceAll(RegExp(r'^[\s\-–—·:]+|[\s\-–—·:]+$'), ''),
);

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
