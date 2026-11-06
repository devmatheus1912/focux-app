import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';
import 'evolucao_series.dart';

/// O que um anel mostra: nome, valor por escrito e quanto do arco preencher.
class LeituraDoAnel {
  const LeituraDoAnel({
    required this.rotulo,
    required this.valor,
    required this.fracao,
    this.vazio = false,
  });

  final String rotulo;
  final String valor;
  final double fracao;
  final bool vazio;
}

/// Sempre 3, na mesma ordem: a tela não muda de forma quando falta dado.
///
/// [metaNome] nomeia o anel de meta ("Meta · Braço"): "Meta 25%" sozinho não
/// diz de qual meta é.
List<LeituraDoAnel> leiturasDosAneis(
  EvolucaoAneis aneis, {
  required bool doPersonal,
  DateTime? hoje,
  String? metaNome,
}) {
  final previstos = aneis.treinoPrevistos;
  final meta = aneis.metaProgresso;
  return [
    previstos == null
        ? LeituraDoAnel(
          rotulo: ptS.evolucaoAnelTreino,
          valor: ptS.evolucaoAnelSemFicha,
          fracao: 0,
          vazio: true,
        )
        : LeituraDoAnel(
          rotulo: ptS.evolucaoAnelTreino,
          valor: ptS.evolucaoAnelTreinoValor(
            '${aneis.treinoFeitos}',
            '$previstos',
          ),
          fracao: aneis.treinoFeitos / previstos,
        ),
    meta == null
        ? LeituraDoAnel(
          rotulo: ptS.evolucaoAnelMeta,
          valor: doPersonal ? ptS.evolucaoDefinirMeta : ptS.evolucaoAnelSemMeta,
          fracao: 0,
          vazio: true,
        )
        : LeituraDoAnel(
          rotulo:
              metaNome == null
                  ? ptS.evolucaoAnelMeta
                  : ptS.evolucaoAnelMetaDe(metaNome),
          valor: '$meta%',
          fracao: meta / 100,
        ),
    _leituraDasMedidas(aneis, hoje ?? DateTime.now()),
  ];
}

LeituraDoAnel _leituraDasMedidas(EvolucaoAneis aneis, DateTime hoje) {
  final ultima = DateTime.tryParse(aneis.ultimaMedida ?? '');
  if (ultima == null) {
    return LeituraDoAnel(
      rotulo: ptS.evolucaoAnelMedidas,
      valor: ptS.evolucaoAnelPrimeiraMedida,
      fracao: 0,
      vazio: true,
    );
  }
  final dia = DateTime(hoje.year, hoje.month, hoje.day);
  final restantes = aneis.cicloMedidasDias - dia.difference(ultima).inDays;
  return LeituraDoAnel(
    rotulo: ptS.evolucaoAnelMedidas,
    valor:
        restantes < 0
            ? ptS.evolucaoAnelVencida
            : ptS.evolucaoAnelDias('$restantes'),
    fracao: restantes / aneis.cicloMedidasDias,
  );
}

/// A meta aberta mais avançada. Manutenção não entra.
MetaCorporal? metaPrincipal(List<MetaCorporal> metas) {
  final abertas = metas.where((m) => m.aberta && !m.manutencao).toList()
    ..sort((a, b) => b.progresso.compareTo(a.progresso));
  return abertas.firstOrNull;
}

/// Frase do aluno: quanto falta e, com registros que sustentem, o ritmo.
String? fraseDoAluno(
  List<MetaCorporal> metas,
  List<MedidaCorporal> medidas,
) {
  final meta = metaPrincipal(metas);
  if (meta == null) return null;
  final atual = meta.valorAtual;
  if (atual == null) return null;
  final falta = (meta.valorAlvo - atual).abs();
  final partes = [
    if (falta == 0)
      ptS.evolucaoMetaBatida
    else
      ptS.evolucaoFaltam(metaValor(meta.metrica, falta)),
  ];
  final metrica = EvolucaoMetrica.values
      .where((m) => m.codigoMeta == meta.metrica)
      .firstOrNull;
  if (metrica != null) {
    final ritmo = ritmoSemanal(serieDaMetrica(medidas, metrica));
    if (ritmo != null && ritmo != 0) {
      partes.add(ptS.evolucaoRitmo(diferencaTexto(ritmo, metrica.unidade)));
    }
  }
  return partes.join(' · ');
}

/// Nome da medida da meta que o anel mostra ([metaPrincipal]).
String? nomeDaMetaPrincipal(List<MetaCorporal> metas) =>
    switch (metaPrincipal(metas)) {
      final m? => metaMetricaRotulo(m.metrica),
      null => null,
    };
