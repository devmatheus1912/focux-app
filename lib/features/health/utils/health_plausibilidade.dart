import 'package:flutter/foundation.dart';

import '../data/health_repository.dart';

/// Calorias ativas só valem com relógio: sem ele o iPhone grava quase zero e
/// o número ("24 kcal" com 5 mil passos) engana.
bool caloriasPlausiveis({required int passos, required double kcalAtivas}) =>
    !(passos > 2000 && kcalAtivas < passos * 0.02);

/// A fonte dos dados é um relógio ("Apple Watch de Ana", "Galaxy Watch5", "Garmin"…).
bool fonteEhRelogio(String fonte) {
  final f = fonte.toLowerCase();
  return const ['watch', 'relógio', 'relogio', 'wear os', 'garmin', 'fitbit', 'amazfit', 'polar', 'coros', 'whoop']
      .any(f.contains);
}

/// Texto de apoio do cartão de calorias. Com relógio e sem energia ativa o problema
/// não é "falta relógio": é a permissão ou o relógio fora do pulso.
String apoioDasCalorias({
  required int passos,
  required double kcal,
  required bool fonteEhRelogio,
  required String semDadosHoje,
}) {
  if (caloriasPlausiveis(passos: passos, kcalAtivas: kcal) && kcal >= 1) return 'Até agora';
  if (fonteEhRelogio) return 'Sem energia ativa hoje';
  return passos > 2000 ? 'Precisa de um relógio' : semDadosHoje;
}

/// 5124 vira "5.124".
String milhar(int n) {
  final texto = n.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < texto.length; i++) {
    if (i > 0 && (texto.length - i) % 3 == 0) out.write('.');
    out.write(texto[i]);
  }
  return n < 0 ? '-$out' : out.toString();
}

/// 6,5 h vira "6h30".
String duracaoDeSono(double horas) {
  final minutos = (horas * 60).round();
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
}

/// "Apple Saúde" no iPhone, "Health Connect" no Android.
String rotuloPlataformaSaude([TargetPlatform? plataforma]) =>
    (plataforma ?? defaultTargetPlatform) == TargetPlatform.iOS
        ? 'Apple Saúde'
        : 'Health Connect';

/// O que o card da nota mostra.
enum ProntidaoEstado { comNota, semSono, calibrando, indisponivel }

/// [sonoLocal]: o aparelho tem sono hoje, mas o servidor ainda não respondeu
/// (sync falhou): a nota está indisponível, não "sem sono".
ProntidaoEstado prontidaoEstado(
  RecoverySnapshot? recovery, {
  bool sonoLocal = false,
}) {
  if (recovery == null) {
    return sonoLocal ? ProntidaoEstado.indisponivel : ProntidaoEstado.semSono;
  }
  if (recovery.recoveryScore != null) return ProntidaoEstado.comNota;
  return recovery.calibrando
      ? ProntidaoEstado.calibrando
      : ProntidaoEstado.semSono;
}

/// Frase que liga a nota ao treino de hoje.
String dicaDoTreino(int score) {
  if (score >= 80) return 'Corpo recuperado: dá para treinar forte hoje.';
  if (score >= 65) return 'Prontidão moderada: mantenha as cargas de hoje.';
  if (score >= 45) return 'Treine mais leve hoje e capriche no aquecimento.';
  return 'Hoje vale um treino leve ou mobilidade.';
}

/// Um item da folha "Por quê?".
class InsumoDaNota {
  const InsumoDaNota(this.titulo, this.detalhe);

  final String titulo;
  final String detalhe;
}

/// O que entrou na nota e o que faltou. Passos não entram.
List<InsumoDaNota> insumosDaNota(RecoverySnapshot r) {
  final usou = r.insumos.toSet();
  return [
    if (usou.contains('sono'))
      InsumoDaNota(
        'Sono ${duracaoDeSono(r.sleepHours)}',
        'Entrou na nota, comparado com a sua média das últimas noites.',
      )
    else
      const InsumoDaNota(
        'Sono',
        'Sem sono registrado não calculamos a nota.',
      ),
    if (usou.contains('fcRepouso'))
      InsumoDaNota(
        'FC em repouso ${r.restingHeartRate.round()} bpm',
        'Entrou na nota, comparada com a sua própria linha de base.',
      )
    else
      const InsumoDaNota(
        'FC em repouso',
        'Seu relógio não mediu hoje. A nota usa só o sono.',
      ),
    if (usou.contains('hrv'))
      InsumoDaNota(
        'Variabilidade (HRV) ${r.hrv.round()} ms',
        'Entrou na nota. Quanto maior que a sua média, melhor.',
      )
    else
      const InsumoDaNota(
        'Variabilidade (HRV)',
        'Opcional: sem ela a nota funciona do mesmo jeito.',
      ),
    const InsumoDaNota(
      'Passos',
      'Não entram: medem atividade, não recuperação.',
    ),
  ];
}
