import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/utils/chat_inbox_display.dart';

void main() {
  test('chatInboxHubViewLabel e subtitle', () {
    expect(chatInboxHubViewLabel(ChatInboxHubView.todas), 'Todas');
    expect(chatInboxHubViewLabel(ChatInboxHubView.naoLidas), 'Não lidas');
    expect(chatInboxHubViewLabel(ChatInboxHubView.arquivadas), 'Arquivadas');
    // Só a conta: o filtro já aparece no chip.
    expect(chatInboxHubSubtitle(), isNull);
    expect(chatInboxCountLabel(0), 'Nenhuma conversa');
    expect(chatInboxCountLabel(1), '1 conversa');
    expect(
      chatInboxHubSubtitle(count: 12, freshness: 'Atualizado há 8min'),
      '12 conversas · Atualizado há 8min',
    );
  });

  test('busca e filtros só com mais de 3 conversas', () {
    bool mostra(int? total, {int arquivadas = 0, bool buscando = false}) =>
        chatInboxMostraBuscaEFiltros(
          totalConversas: total,
          arquivadas: arquivadas,
          buscando: buscando,
          outraAba: false,
        );
    expect(mostra(1), isFalse);
    expect(mostra(4), isTrue);
    expect(mostra(1, arquivadas: 1), isTrue);
    expect(mostra(1, buscando: true), isTrue);
    expect(mostra(null), isTrue);
  });

  test('chatInbox empty, seleção e ações', () {
    expect(chatInboxEmptyTitle(ChatInboxHubView.todas), 'Nenhuma conversa ainda');
    expect(
      chatInboxEmptySubtitle(ChatInboxHubView.arquivadas),
      'Arraste conversas para a esquerda para arquivar.',
    );
    expect(chatInboxSelectionTitle(0), 'Selecione mensagens');
    expect(chatInboxSelectionTitle(1), '1 selecionada');
    expect(chatInboxSelectionTitle(3), '3 selecionadas');
    expect(chatInboxDeleteConfirmTitle(1), 'Excluir mensagens?');
    expect(chatInboxDeleteDoneLabel(2), 'Conversas excluídas');
    expect(chatInboxActionLabel('archive'), 'Arquivada');
    expect(chatInboxActionLabel('pin'), 'Fixada');
    expect(chatInboxActionLabel('xyz'), 'Ação aplicada');
  });
}
