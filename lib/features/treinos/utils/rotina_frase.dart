import '../../../l10n/app_localizations.dart';
import '../../checkin/utils/rotina_decisao.dart';
import '../../dashboard/utils/aluno_home_texts.dart';
import '../../dashboard/utils/aluno_today_action.dart';
import '../models/rotina_fila.dart';

/// A mesma frase da Home, lida pelo personal: "Hugo abre o app e vê: Agora, Treino A."
String? fraseQueAlunoVe(
  S s, {
  required String nome,
  required RotinaFila rotina,
  required DateTime agora,
}) {
  final decisao = decisaoParaPersonal(rotina, agora);
  if (decisao == null) return null;
  final texto = alunoTodayTexto(s, acaoDaDecisao(decisao), hoje: agora);
  final aluno = nome.trim().isEmpty ? 'O aluno' : nome.trim();
  return s.rotinaAbreVe(aluno, texto.eyebrow, texto.titulo);
}
