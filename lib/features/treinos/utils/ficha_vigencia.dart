/// Vigência da ficha: quanto tempo ela vale. Só orienta: nunca bloqueia o treino.
/// Mesma regra do backend (FichaVigencia.java).
enum EstadoVigencia { semPrazo, emDia, venceEmBreve, venceHoje, vencida }

/// Janela do "vence em breve", em dias.
const diasDeAvisoDaVigencia = 7;

class VigenciaFicha {
  const VigenciaFicha({this.inicio, this.fim});

  static const semPrazo = VigenciaFicha();

  final DateTime? inicio;
  final DateTime? fim;

  bool get temPrazo => fim != null;

  EstadoVigencia estado(DateTime hoje) => estadoDaVigencia(fim, hoje: hoje);

  /// Negativo quando já venceu; nulo sem prazo.
  int? diasRestantes(DateTime hoje) =>
      fim == null ? null : diasAteOFim(fim!, hoje);

  factory VigenciaFicha.fromJson(Object? raw) {
    if (raw is! Map) return semPrazo;
    return VigenciaFicha(
      inicio: _data(raw['inicio']),
      fim: _data(raw['fim']),
    );
  }

  static DateTime? _data(Object? valor) {
    final texto = valor?.toString();
    if (texto == null || texto.isEmpty) return null;
    final lida = DateTime.tryParse(texto);
    return lida == null ? null : DateTime(lida.year, lida.month, lida.day);
  }
}

EstadoVigencia estadoDaVigencia(DateTime? fim, {required DateTime hoje}) {
  if (fim == null) return EstadoVigencia.semPrazo;
  final dias = diasAteOFim(fim, hoje);
  if (dias < 0) return EstadoVigencia.vencida;
  if (dias == 0) return EstadoVigencia.venceHoje;
  if (dias <= diasDeAvisoDaVigencia) return EstadoVigencia.venceEmBreve;
  return EstadoVigencia.emDia;
}

/// Dias de calendário entre [hoje] e [fim], sem se importar com a hora.
int diasAteOFim(DateTime fim, DateTime hoje) {
  final a = DateTime.utc(fim.year, fim.month, fim.day);
  final b = DateTime.utc(hoje.year, hoje.month, hoje.day);
  return a.difference(b).inDays;
}

/// "30/11".
String dataCurta(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';

/// "2026-11-30", como a API espera.
String dataIso(DateTime data) =>
    '${data.year.toString().padLeft(4, '0')}-'
    '${data.month.toString().padLeft(2, '0')}-'
    '${data.day.toString().padLeft(2, '0')}';
