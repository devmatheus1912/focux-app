part of 'conversation_screen.dart';

extension ConversationScreenSheetsSearch on _ConversationScreenState {
  void _showSearchSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final ctrl = TextEditingController();
    var query = '';
    var searching = false;
    var searched = false;
    var results = <ChatMsg>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              final media = MediaQuery.of(sheetContext);
              final keyboardInset = media.viewInsets.bottom;
              final availableHeight =
                  media.size.height - keyboardInset - media.padding.top - 32;
              final sheetHeight = availableHeight.clamp(280.0, 440.0);

              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TokensStrip.rXl),
                  child: DecoratedBox(
                    decoration: fxListCardDecoration(
                      context,
                      accent: primary,
                      radius: TokensStrip.rXl,
                    ),
                    child: AnimatedPadding(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.only(bottom: keyboardInset),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            14,
                            16,
                            16,
                          ),
                          child: SizedBox(
                            height: sheetHeight,
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? EagleTokens.darkLine
                                            : TokensStrip.borderDefault,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                TextField(
                                  controller: ctrl,
                                  autofocus: true,
                                  onChanged:
                                      (value) =>
                                          setSheetState(() => query = value),
                                  onSubmitted: (_) async {
                                    await _performSearch(
                                      query: query,
                                      setSearching:
                                          (value) => setSheetState(
                                            () => searching = value,
                                          ),
                                      setResults:
                                          (value) => setSheetState(() {
                                            searched = true;
                                            results = value;
                                          }),
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Buscar na conversa',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () async {
                                        await _performSearch(
                                          query: query,
                                          setSearching:
                                              (value) => setSheetState(
                                                () => searching = value,
                                              ),
                                          setResults:
                                              (value) => setSheetState(() {
                                                searched = true;
                                                results = value;
                                              }),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor:
                                        isDark
                                            ? EagleTokens.darkCardHi
                                            : TokensStrip.cardBg,
                                    border: FxInputDeco.outlineBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Expanded(
                                  child:
                                      query.trim().isEmpty
                                          ? const ConversationSearchState(
                                            icon: Icons.search_rounded,
                                            title: 'Digite para buscar',
                                            subtitle:
                                                'Encontre mensagens antigas da conversa.',
                                          )
                                          : searching
                                          ? const Center(child: FxLoading())
                                          : searched && results.isEmpty
                                          ? const ConversationSearchState(
                                            icon: Icons.chat_bubble_outline,
                                            title: 'Nada encontrado',
                                            subtitle:
                                                'Tente outra palavra-chave.',
                                          )
                                          : ListView.separated(
                                            itemCount: results.length,
                                            separatorBuilder:
                                                (_, __) =>
                                                    const SizedBox(height: 8),
                                            itemBuilder: (_, index) {
                                              final msg = results[index];
                                              return InkWell(
                                                onTap: () {
                                                  Navigator.pop(sheetContext);
                                                  _focusMessage(msg);
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isDark
                                                            ? EagleTokens
                                                                .darkCardHi
                                                            : primarySoft,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _replySenderLabel(
                                                          msg.remetente,
                                                        ),
                                                        style: TextStyle(
                                                          color: primary,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _previewText(msg),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        _fullDateLabel(
                                                          msg.enviadoEm,
                                                        ),
                                                        style: TextStyle(
                                                          color:
                                                              isDark
                                                                  ? EagleTokens
                                                                      .darkInkMute
                                                                  : EagleTokens
                                                                      .inkMute,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    ).whenComplete(ctrl.dispose);
  }

  Future<void> _performSearch({
    required String query,
    required void Function(bool value) setSearching,
    required void Function(List<ChatMsg> value) setResults,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      setResults(const []);
      return;
    }
    setSearching(true);
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final results =
          _isAlunoMode
              ? await repo.buscarHistoricoAluno(normalized)
              : await repo.buscarHistorico(_alunoId!, normalized);
      setResults(results);
    } catch (_) {
      final fallback = _msgs.reversed
          .where((msg) {
            final content = msg.conteudo.toLowerCase();
            final reply = (msg.replyToConteudo ?? '').toLowerCase();
            return content.contains(normalized.toLowerCase()) ||
                reply.contains(normalized.toLowerCase());
          })
          .toList(growable: false);
      setResults(fallback);
    } finally {
      setSearching(false);
    }
  }
}
