import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/notificacoes/notificacoes_locais.dart';
import 'package:focux_app/core/notificacoes/tipos_de_notificacao.dart';
import 'package:focux_app/features/perfil/data/notificacoes_preferencias_repository.dart';

void main() {
  test(
    'toque no aviso do descanso não empilha a execução que já está aberta',
    () {
      expect(
        jaEstaEm(
          '/checkin/executar?treinoId=3',
          atual: '/checkin/executar?treinoId=3',
        ),
        isTrue,
      );
      expect(
        jaEstaEm('/checkin/executar?treinoId=3', atual: '/dashboard/aluno'),
        isFalse,
      );
      expect(jaEstaEm('/perfil/notificacoes', atual: null), isFalse);
    },
  );

  test('canais do Android têm os ids que o servidor manda como channel_id', () {
    final ids = canaisAndroid.map((c) => c.id).toSet();
    for (final tipo in [
      'treino',
      'descanso',
      'chat',
      'agenda',
      'alunos',
      'financeiro',
      'vendas',
      'comunidade',
      'novidades',
      'ofertas',
      'sistema',
    ]) {
      expect(ids, contains(tipo));
    }
    expect(
      const PreferenciaDeNotificacao(
        tipo: 'FINANCEIRO',
        rotulo: 'Financeiro',
        descricao: '',
        ligado: true,
      ).canal,
      'financeiro',
    );
  });

  test('resultado do teste vira texto para a pessoa', () {
    expect(resultadoDoTeste('ENVIADO'), ResultadoDoTeste.enviado);
    expect(resultadoDoTeste('SEM_TOKEN'), ResultadoDoTeste.semAparelho);
    expect(resultadoDoTeste('DESLIGADO'), ResultadoDoTeste.falhou);
    expect(
      textoDoTeste(ResultadoDoTeste.semAparelho),
      contains('não tem notificações ativas'),
    );
  });
}
