import 'semana_da_fila.dart';

/// Mede quanto o personal leva para montar uma ficha: do momento em que ela
/// está vazia até o primeiro "Pronto" com todas as sessões preenchidas.
/// Dispara uma vez por ficha montada; sem dado pessoal.
class FichaMedicao {
  DateTime? _inicio;
  var _enviado = false;

  void iniciar(DateTime agora) => _inicio ??= agora;

  /// Propriedades do evento, ou null quando ainda não vale medir.
  Map<String, Object>? aoConcluir(EstadoDaFicha estado, DateTime agora) {
    final inicio = _inicio;
    if (_enviado || inicio == null || !estado.completa) return null;
    _enviado = true;
    return {
      'dias': estado.dias,
      'sessoes': estado.sessoes,
      'segundos': agora.difference(inicio).inSeconds,
    };
  }
}
