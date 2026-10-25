/// Nome limpo e objetivo achado no meio do texto de uma linha de aluno.
///
/// Espelho de `MigracaoLeitor.limparNome` (Java): os dois leem o mesmo arquivo de
/// casos (`limpeza_nome.json`) nos testes e precisam dar a mesma saída.
class NomeLimpo {
  const NomeLimpo(this.nome, this.objetivo);

  final String nome;
  final String? objetivo;
}

final _cpf = RegExp(r'\b\d{3}\.\d{3}\.\d{3}-\d{2}\b');
final _data = RegExp(r'\b\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4}\b');
final _idade = RegExp(r'\b\d{1,3}\s*anos?\b', caseSensitive: false);
final _objetivoExplicito = RegExp(r'objetivo\s*[:=-]\s*([^,;|]+)', caseSensitive: false);
final _separadorEntreEspacos = RegExp(r'\s+[-–—•·|]+\s+');
final _separadorSolto = RegExp(r'[,;|•·]+');
final _marcadorDeLista = RegExp(r'^#?\d+[.)]?$');
final _pontasSemLetra = RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true);

/// Status e plano que aparecem colados ao nome em listas de outros apps.
const _ruidoDeNome = {
  'ativo', 'ativa', 'inativo', 'inativa', 'vencido', 'vencida', 'pendente', 'pago', 'paga',
  'bloqueado', 'bloqueada', 'pausado', 'pausada', 'mensal', 'trimestral', 'semestral',
  'anual', 'plano', 'planos', 'nascimento', 'nasc', 'cpf',
};

const _objetivos = {
  'hipertrofia': 'Hipertrofia',
  'emagrecimento': 'Emagrecimento',
  'emagrecer': 'Emagrecimento',
  'forca': 'Força',
  'condicionamento': 'Condicionamento',
  'saude': 'Saúde',
  'reabilitacao': 'Reabilitação',
  'definicao': 'Definição',
};

/// Tira CPF, data, idade, status, plano, separadores e número de lista do nome.
NomeLimpo limparNome(String? bruto) {
  if (bruto == null) return const NomeLimpo('', null);
  var texto = bruto;
  String? objetivo;

  final explicito = _objetivoExplicito.firstMatch(texto);
  if (explicito != null) {
    objetivo = _canonicoDoObjetivo(explicito.group(1)!.trim());
    texto = texto.replaceAll(_objetivoExplicito, ' ');
  }
  texto = texto
      .replaceAll(_cpf, ' ')
      .replaceAll(_data, ' ')
      .replaceAll(_idade, ' ')
      .replaceAll(_separadorEntreEspacos, ' ')
      .replaceAll(_separadorSolto, ' ');

  final tokens = <String>[];
  for (final t in texto.trim().split(RegExp(r'\s+'))) {
    final limpo = t.replaceAll(_pontasSemLetra, '');
    if (limpo.isNotEmpty) tokens.add(limpo);
  }
  if (tokens.length > 1 && _marcadorDeLista.hasMatch(tokens.first)) {
    tokens.removeAt(0);
  }
  while (tokens.isNotEmpty && _ehRuidoDeNome(tokens.last)) {
    tokens.removeLast();
  }
  while (tokens.isNotEmpty && _ehRuidoDeNome(tokens.first)) {
    tokens.removeAt(0);
  }
  final nome = <String>[];
  for (final t in tokens) {
    final canonico = _objetivos[migracaoSemAcento(t)];
    if (canonico != null && objetivo == null) {
      objetivo = canonico;
    } else if (canonico == null) {
      nome.add(t);
    }
  }
  // Só número solto no fim (ex.: "Maria Silva 2") não é nome.
  while (nome.isNotEmpty && RegExp(r'^\d+$').hasMatch(nome.last)) {
    nome.removeLast();
  }
  return NomeLimpo(nome.join(' '), objetivo);
}

bool _ehRuidoDeNome(String token) => _ruidoDeNome.contains(migracaoSemAcento(token));

String _canonicoDoObjetivo(String texto) =>
    _objetivos[migracaoSemAcento(texto)] ?? texto;

/// Minúsculas sem acento, para comparar palavras.
String migracaoSemAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const para = 'aaaaaeeeeiiiiooooouuuuc';
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = de.indexOf(ch);
    buf.write(i >= 0 ? para[i] : ch);
  }
  return buf.toString();
}
