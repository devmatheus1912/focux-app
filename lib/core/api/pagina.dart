/// Envelope de paginação dos endpoints **novos**, conforme §1 do contrato
/// pareado em `docs/CONTRATO_APP_BACKEND.md`.
///
/// Offset e cursor compartilham `content` e `hasNext`. O parser distingue os
/// dois olhando se veio `page`/`totalElements` ou `nextCursor`. Os três
/// formatos que já estão em produção (Page do Spring, financeiro,
/// notificações) **não** passam por aqui — cada um continua no `fromJson`
/// do próprio repositório.
class Pagina<T> {
  final List<T> content;
  final bool hasNext;

  /// Presente no envelope offset (§1.2). Ausente no cursor.
  final int? page;
  final int? size;

  /// Pode faltar mesmo no offset: `COUNT` caro sob carga, avisado antes de
  /// omitir (§1.4). `hasNext` sozinho já sustenta a paginação.
  final int? totalElements;

  /// Presente no envelope cursor (§1.3). Ausente no offset.
  final String? nextCursor;

  const Pagina({
    required this.content,
    required this.hasNext,
    this.page,
    this.size,
    this.totalElements,
    this.nextCursor,
  });

  bool get isOffset => page != null;
  bool get isCursor => nextCursor != null;

  /// Falha alto se o array não se chama `content`: é exatamente o quinto
  /// formato que o contrato existe para impedir. `items` no chat atual não
  /// entra aqui — fica no parser legado.
  factory Pagina.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) parseItem,
  ) {
    final raw = json['content'];
    if (raw is! List) {
      throw FormatException(
        'Pagina exige content (array). Chaves recebidas: ${json.keys.join(', ')}',
      );
    }
    return Pagina<T>(
      content: raw.map(parseItem).toList(),
      hasNext: json['hasNext'] == true,
      page: (json['page'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
      totalElements: (json['totalElements'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
