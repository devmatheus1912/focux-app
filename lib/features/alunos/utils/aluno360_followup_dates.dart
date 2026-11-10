/// "01/11"; o ano só aparece quando não é o ano corrente.
String alunoFollowUpDateLabel(DateTime date, {DateTime? agora}) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final ano = (agora ?? DateTime.now()).year;
  return date.year == ano ? '$d/$m' : '$d/$m/${date.year}';
}
