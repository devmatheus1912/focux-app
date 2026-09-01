import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/utils/chat_inbox_display.dart';

void main() {
  test('chatInboxHubViewLabel e subtitle', () {
    expect(chatInboxHubViewLabel(ChatInboxHubView.todas), 'Todas');
    expect(chatInboxHubViewLabel(ChatInboxHubView.naoLidas), 'Não lidas');
    expect(chatInboxHubViewLabel(ChatInboxHubView.arquivadas), 'Arquivadas');
    expect(
      chatInboxHubSubtitle(view: ChatInboxHubView.todas),
      'Todas',
    );
    expect(
      chatInboxHubSubtitle(
        view: ChatInboxHubView.naoLidas,
        freshness: 'Atualizado agora',
      ),
      'Não lidas · Atualizado agora',
    );
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
