import '../../../core/state/fx_value_notifier.dart';

/// Texto pronto para a conversa do aluno. A aba do chat fica viva no shell,
/// então o texto chega por aqui, e não por parâmetro de rota.
final chatAlunoRascunhoProvider = fxValueProvider<String?>(null);
