String pacoteCountLabel(int count) {
  if (count <= 0) return 'Nenhum plano';
  if (count == 1) return '1 plano';
  return '$count planos';
}

const pacoteDuracaoMesesValues = [1, 3, 6, 12];
const pacoteTituloMax = 120;
const pacoteDescricaoMax = 4000;

String pacoteDuracaoLabel(int meses) {
  if (meses <= 1) return '1 mês';
  return '$meses meses';
}

/// "1 mês · Treino e consultoria".
String pacoteLinha({
  required bool treino,
  required bool consultoria,
  required int meses,
}) {
  final inclui = [if (treino) 'Treino', if (consultoria) 'consultoria'];
  final texto =
      inclui.isEmpty
          ? ''
          : inclui.length == 1
          ? (inclui.first == 'consultoria' ? 'Consultoria' : inclui.first)
          : '${inclui.first} e ${inclui.last}';
  return [pacoteDuracaoLabel(meses), if (texto.isNotEmpty) texto].join(' · ');
}

/// Subtítulo de Vendas: o que pede ação primeiro.
String vendasSubtitulo({required int pixAguardando, required int planos}) {
  if (pixAguardando == 1) return '1 PIX aguardando';
  if (pixAguardando > 1) return '$pixAguardando PIX aguardando';
  if (planos == 0) return 'Nenhum plano à venda';
  if (planos == 1) return '1 plano à venda';
  return '$planos planos à venda';
}

/// Busca de planos só com mais de 6.
bool vendasMostraBusca({required int planos, required String query}) =>
    planos > 6 || query.trim().isNotEmpty;

const pacotePaginaForaDoArTitulo = 'Sua página ainda não está no ar';

const pacotePaginaForaDoArTexto =
    'Os planos só aparecem para o cliente depois que você gera a página no Estúdio. Toque para abrir.';

String pacoteCriadoMensagem({required bool paginaNoAr}) =>
    paginaNoAr
        ? 'Plano criado e já na sua página.'
        : 'Plano criado. Gere sua página no Estúdio para ele aparecer.';

const vendasOfertasVazio =
    'Ofereça um plano a quem já é aluno: um upgrade, a renovação ou um pacote extra.';

const vendasPedidosVazio =
    'Quando alguém comprar pela sua página, aparece aqui.';
