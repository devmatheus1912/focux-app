import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Canal do Android do fim do descanso (o tipo DESCANSO do servidor).
const canalDescanso = 'descanso';

/// Contagem regressiva do descanso na tela de bloqueio (silenciosa).
const canalDescansoContagem = 'descanso_contagem';

/// Os mesmos tipos do servidor (`TipoNotificacao`), com o mesmo nome da tela.
/// O `id` é o `channel_id` que o push manda.
const canaisAndroid = <AndroidNotificationChannel>[
  AndroidNotificationChannel(
    'treino',
    'Treino',
    description: 'Lembretes, ficha nova e ficha vencendo',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    canalDescanso,
    'Fim do descanso',
    description: 'Aviso quando o descanso entre séries acaba',
    importance: Importance.max,
  ),
  AndroidNotificationChannel(
    canalDescansoContagem,
    'Contagem do descanso',
    description: 'Tempo que falta, na tela de bloqueio',
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
  ),
  AndroidNotificationChannel(
    'chat',
    'Mensagens',
    description: 'Mensagens do chat',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'agenda',
    'Agenda',
    description: 'Sessão marcada, mudada, cancelada e lembrete',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'alunos',
    'Alunos',
    description: 'Treino concluído, recorde, aluno em risco e tarefas',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'financeiro',
    'Financeiro',
    description: 'Mensalidade, PIX e cobrança',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'vendas',
    'Interessados e vendas',
    description: 'Interessado novo e venda pela sua página',
    importance: Importance.high,
  ),
  AndroidNotificationChannel(
    'comunidade',
    'Comunidade',
    description: 'Feed, desafios e hábitos',
  ),
  AndroidNotificationChannel(
    'novidades',
    'Novidades do app',
    description: 'Versão nova do app',
  ),
  AndroidNotificationChannel(
    'ofertas',
    'Ofertas e dicas do Focux',
    description: 'Planos, indicação e dicas',
  ),
  AndroidNotificationChannel(
    'sistema',
    'Conta e sistema',
    description: 'Plano, conta e notificação de teste',
    importance: Importance.high,
  ),
];
