/// Abre uma tela por toque sem prender o toque seguinte.
///
/// A trava cobre só o toque duplo ([janela]) e não espera a tela fechar: a
/// prévia vira execução por `pushReplacement`, e no go_router 18 o `push` que
/// abriu a prévia nunca termina. Esperar por ele deixava a aba Treinos do aluno
/// ignorando todo toque até o app ser fechado.
class FxAberturaUnica {
  FxAberturaUnica({
    this.janela = const Duration(milliseconds: 600),
    DateTime Function()? agora,
  }) : _agora = agora ?? DateTime.now;

  final Duration janela;
  final DateTime Function() _agora;
  DateTime? _ultima;

  /// Navega e devolve o retorno da tela (que pode nunca chegar), ou `null`
  /// quando o toque caiu dentro da [janela] do anterior.
  Future<T?>? abrir<T>(Future<T?> Function() navegar) {
    final agora = _agora();
    final ultima = _ultima;
    if (ultima != null && agora.difference(ultima) < janela) return null;
    _ultima = agora;
    return navegar();
  }
}
