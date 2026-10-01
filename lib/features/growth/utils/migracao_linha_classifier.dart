/// Decide se uma linha de planilha/print parece um aluno.
/// Mesmas regras do classificador do servidor.
enum MigracaoLinhaStatus { valido, duvidoso, ignorado }

MigracaoLinhaStatus migracaoLinhaStatusFromApi(Object? raw) =>
    switch (raw?.toString().toUpperCase()) {
      'DUVIDOSO' => MigracaoLinhaStatus.duvidoso,
      'IGNORADO' => MigracaoLinhaStatus.ignorado,
      _ => MigracaoLinhaStatus.valido,
    };

const _termosDocumento = {
  'art', 'lei', 'certificado', 'certificacao', 'cpf', 'cnpj', 'ementa',
  'codigo', 'autoridade', 'declaracao', 'declaracoes', 'processo', 'medida',
  'provisoria', 'digital', 'assinatura', 'documento', 'pagina', 'civil',
  'registro',
};

const _conectivos = {'de', 'da', 'do', 'dos', 'das', 'e'};

final _email = RegExp(r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$', caseSensitive: false);
final _palavra = RegExp(r"^\p{L}[\p{L}'-]+$", unicode: true);
final _maiuscula = RegExp(r'^\p{Lu}', unicode: true);

MigracaoLinhaStatus migracaoClassificar(
  String? nome,
  String? email,
  String? telefone,
) {
  if (migracaoEmailValido(email) || migracaoTelefoneValido(telefone)) {
    return MigracaoLinhaStatus.valido;
  }
  if (!migracaoNomePlausivel(nome)) return MigracaoLinhaStatus.ignorado;
  return nome!.trim().split(RegExp(r'\s+')).length >= 2
      ? MigracaoLinhaStatus.valido
      : MigracaoLinhaStatus.duvidoso;
}

bool migracaoEmailValido(String? email) =>
    email != null && _email.hasMatch(email.trim());

bool migracaoTelefoneValido(String? telefone) {
  if (telefone == null) return false;
  final digitos = telefone.replaceAll(RegExp(r'\D'), '').length;
  return digitos >= 10 && digitos <= 13;
}

bool migracaoNomePlausivel(String? nome) {
  final limpo = nome?.trim() ?? '';
  if (limpo.isEmpty ||
      limpo.length > 60 ||
      limpo.contains('§') ||
      limpo.contains(':')) {
    return false;
  }
  final palavras = limpo.split(RegExp(r'\s+'));
  if (palavras.length > 5) return false;
  for (var i = 0; i < palavras.length; i++) {
    final p = palavras[i];
    if (!_palavra.hasMatch(p)) return false;
    final lower = p.toLowerCase();
    if (_termosDocumento.contains(_semAcento(lower))) return false;
    final conectivo = i > 0 && _conectivos.contains(lower);
    if (!conectivo && !_maiuscula.hasMatch(p)) return false;
  }
  final sigla = palavras.length == 1 &&
      palavras.first.length <= 3 &&
      palavras.first == palavras.first.toUpperCase();
  return !sigla;
}

String _semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    buf.write(i >= 0 ? para[i] : ch);
  }
  return buf.toString();
}
