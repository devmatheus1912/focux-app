import '../data/feedback_video_repository.dart';
import '../../../core/utils/fx_utils.dart';

String feedbackVideoLabel(String? comentario) {
  final value = comentario?.trim();
  if (value == null || value.isEmpty) return 'Feedback';
  return value;
}

/// Mesmas palavras dos dois lados: "Para responder" (personal) ↔ "Enviado" (aluno).
String feedbackVideoStatusLabel({required bool respondido}) =>
    respondido ? 'Respondido' : 'Para responder';

/// Falha ao subir o áudio da correção (o texto digitado fica na folha).
const feedbackVideoAudioFalhou = 'Não deu para enviar o áudio. Tente de novo.';

String feedbackVideoResponderLabel({required bool respondido}) =>
    respondido ? 'Editar resposta' : 'Responder';

/// Palavras que já são dor.
const _palavrasDeDor = [
  'dor',
  'dores',
  'doeu',
  'doendo',
  'dói',
  'doi',
  'incômodo',
  'incomodo',
];

/// "Senti" só é dor junto de uma parte do corpo ("senti o joelho"); sozinho
/// ("senti evolução") não acende o alerta.
const _sentir = ['senti', 'sinto', 'sentindo'];
const _partesDoCorpo = [
  'joelho',
  'joelhos',
  'ombro',
  'ombros',
  'lombar',
  'costas',
  'coluna',
  'quadril',
  'punho',
  'punhos',
  'cotovelo',
  'cotovelos',
  'tornozelo',
  'tornozelos',
  'pescoço',
  'pescoco',
];

bool feedbackRecadoFalaDeDor(String recado) {
  final palavras = recado.toLowerCase().split(RegExp(r'[^a-zà-ú]+'));
  if (palavras.any(_palavrasDeDor.contains)) return true;
  return palavras.any(_sentir.contains) &&
      palavras.any(_partesDoCorpo.contains);
}

/// Linha da lista do personal: dor primeiro no texto, senão a prévia do
/// recado, senão o estado.
String feedbackVideoSubtituloDaLinha(FeedbackVideo item) {
  final data = fxDateShort(item.criadoEm);
  if (item.respondido) return '$data · Correção enviada';
  final recado = item.comentario.trim();
  if (recado.isNotEmpty && feedbackRecadoFalaDeDor(recado)) {
    return 'Fala de dor · $data';
  }
  if (recado.isNotEmpty) return '“$recado” · $data';
  return '$data · O aluno espera sua correção';
}

bool feedbackVideoComDor(FeedbackVideo item) =>
    !item.respondido && feedbackRecadoFalaDeDor(item.comentario);

/// Ordem da lista: para responder com dor, os outros para responder, os
/// respondidos; dentro de cada grupo, do mais novo ao mais antigo.
List<FeedbackVideo> feedbackVideosOrdenados(Iterable<FeedbackVideo> itens) {
  int grupo(FeedbackVideo f) =>
      feedbackVideoComDor(f) ? 0 : (f.respondido ? 2 : 1);
  return [...itens]..sort((a, b) {
    final g = grupo(a).compareTo(grupo(b));
    return g != 0 ? g : b.criadoEm.compareTo(a.criadoEm);
  });
}

/// "0:42" para o áudio da correção.
String feedbackAudioDuracao(int segundos) {
  final m = segundos ~/ 60;
  final s = (segundos % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Subtítulo do "Assistir vídeo": quando o aluno mandou.
String feedbackVideoEnviadoEm(DateTime criadoEm) =>
    'Enviado em ${fxDateShort(criadoEm)}';

/// Nome único do recurso nas duas pontas (360, plano, catálogo, telas).
const feedbackVideoNome = 'Feedback em vídeo';

/// A busca só aparece quando ajuda (mesma regra das mensalidades).
const feedbackVideoBuscaMinimo = 6;

/// Subtítulo do personal: "Julio · 2 para responder" (sem pendência, só o nome).
String feedbackVideoPersonalSubtitulo({
  String? primeiroNome,
  required int paraResponder,
}) {
  return [
    if (primeiroNome != null && primeiroNome.trim().isNotEmpty)
      primeiroNome.trim(),
    if (paraResponder > 0) '$paraResponder para responder',
  ].join(' · ');
}

/// Texto pronto do "Pedir vídeo": o personal revisa e envia no chat.
String feedbackVideoPedidoRascunho(String primeiroNome) =>
    'Oi, $primeiroNome! Grava um vídeo de uma série do seu treino e me manda em '
    'Ferramentas > Feedback em vídeo, que eu corrijo a execução.';

/// Título da linha: o exercício quando o backend manda, senão o comentário.
String feedbackVideoTitulo({String? exercicioNome, String? comentario}) {
  final nome = exercicioNome?.trim() ?? '';
  return nome.isNotEmpty ? nome : feedbackVideoLabel(comentario);
}

String feedbackVideoAlunoSubtitle({
  required DateTime criadoEm,
  required bool respondido,
}) {
  final date = fxDateShort(criadoEm);
  return respondido
      ? '$date · Correção pronta'
      : '$date · Aguardando a correção';
}

String feedbackVideoAlunoStatusLabel({required bool respondido}) =>
    respondido ? 'Respondido' : 'Enviado';

const feedbackVideoAlunoHelpTip =
    'Grave uma série do exercício e envie por esta tela. Seu personal assiste e '
    'responde com a correção. Você recebe um aviso quando ela chegar.';

/// Detalhe do aluno sem resposta ainda (sem supor o gênero do personal).
const feedbackVideoAlunoSemCorrecao =
    'Ainda sem correção. Você recebe um aviso quando ela chegar.';

const feedbackVideoBuscaDica = 'Buscar exercício ou recado';

const feedbackVideoNaoFeche = 'Não feche o app até terminar.';

String feedbackVideoEnviando(double? fracao) =>
    fracao == null ? 'Enviando…' : 'Enviando… ${(fracao * 100).round()}%';

const feedbackVideoMaxBytes = 120 * 1024 * 1024;
const feedbackVideoMaxDuration = Duration(seconds: 60);
const _feedbackVideoExtensoes = {'mp4', 'mov', 'm4v', 'webm'};

/// Nome aceito pelo upload (`feedback/videos` só recebe mp4/mov/m4v/webm).
String feedbackVideoUploadFilename(String? nomeOuCaminho) {
  final raw = (nomeOuCaminho ?? '').split(RegExp(r'[\\/]')).last;
  final dot = raw.lastIndexOf('.');
  final ext = dot >= 0 ? raw.substring(dot + 1).toLowerCase() : '';
  final safeExt = _feedbackVideoExtensoes.contains(ext) ? ext : 'mp4';
  return 'feedback_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
}

/// Mensagem de erro de tamanho, ou null quando o vídeo pode subir.
String? feedbackVideoTamanhoErro(int bytes) {
  if (bytes <= 0) return 'Vídeo vazio. Grave de novo.';
  if (bytes > feedbackVideoMaxBytes) {
    return 'Vídeo acima de 120 MB. Grave um trecho mais curto.';
  }
  return null;
}

const feedbackVideoHelpTip =
    'O aluno envia o vídeo do exercício e você responde com a correção: '
    'toque no vídeo para assistir e escrever. Segure para remover. '
    'Para pedir um vídeo, use o botão da tela vazia ou o chat: o aluno envia em '
    'Ferramentas > Feedback em vídeo. Disponível no Pro e no Enterprise.';
