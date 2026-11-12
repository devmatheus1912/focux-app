import 'package:flutter/material.dart';

/// Limpa o que a IA às vezes manda mesmo pedindo texto simples: `<br>`,
/// tabela em markdown e emojis numerados. Negrito (`**`) e listas ficam.
String iaTextoLimpo(String bruto) {
  var t = bruto.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  t = t.replaceAll(RegExp(r'</?[a-zA-Z][^>]*>'), '');
  const numerados = ['1️⃣', '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣'];
  for (var i = 0; i < numerados.length; i++) {
    t = t.replaceAll(numerados[i], '${i + 1}.');
  }
  final linhas = <String>[];
  for (final linha in t.split('\n')) {
    final l = linha.trim();
    // Linha separadora de tabela: some.
    if (RegExp(r'^\|?\s*:?-{2,}').hasMatch(l) && !l.contains(RegExp(r'[A-Za-zÀ-ú0-9]'))) {
      continue;
    }
    if (l.startsWith('|') && l.endsWith('|')) {
      final celulas = l
          .substring(1, l.length - 1)
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      if (celulas.isEmpty) continue;
      linhas.add('- ${celulas.join(': ')}');
      continue;
    }
    linhas.add(linha.trimRight());
  }
  return linhas.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// Texto da IA com negrito e listas, em vez do markdown cru.
class IaTextoFormatado extends StatelessWidget {
  const IaTextoFormatado(this.texto, {super.key, required this.style});

  final String texto;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final linhas = iaTextoLimpo(texto).split('\n');
    final negrito = style.copyWith(fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final linha in linhas)
          if (linha.trim().isEmpty)
            const SizedBox(height: 6)
          else
            _linha(linha, negrito),
      ],
    );
  }

  Widget _linha(String linha, TextStyle negrito) {
    final l = linha.trim();
    final marcador = RegExp(r'^([-•*]|\d+\.)\s+').firstMatch(l);
    final corpo = marcador == null ? l : l.substring(marcador.end);
    final rico = Text.rich(TextSpan(children: iaSpans(corpo, style, negrito)));
    if (marcador == null) return rico;
    final simbolo = marcador.group(1)!.endsWith('.') ? marcador.group(1)! : '•';
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 18, child: Text(simbolo, style: style)),
          Expanded(child: rico),
        ],
      ),
    );
  }
}

/// `**negrito**` vira peso 600; `**` sem par some.
List<TextSpan> iaSpans(String texto, TextStyle normal, TextStyle negrito) {
  final partes = texto.split('**');
  if (partes.length.isEven) {
    // Asterisco sem par: tudo normal, sem os asteriscos.
    return [TextSpan(text: partes.join(), style: normal)];
  }
  return [
    for (var i = 0; i < partes.length; i++)
      if (partes[i].isNotEmpty)
        TextSpan(text: partes[i], style: i.isOdd ? negrito : normal),
  ];
}
