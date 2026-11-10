part of 'automacoes_screen.dart';

/// Uma automação na lista: o modelo e, se o personal já ligou alguma vez, o
/// fluxo dele (ligado ou pausado).
class _AutomacaoLinha {
  const _AutomacaoLinha({this.template, this.fluxo});

  final AutomacaoTemplate? template;
  final AutomacaoFluxo? fluxo;

  bool get ligada => fluxo?.ativo ?? false;

  String get nome => automacaoNome(
    templateId: template?.id ?? fluxo?.templateId,
    nomeGravado: template?.nome ?? fluxo?.nome ?? '',
  );

  String get gatilho =>
      automacaoTriggerLabel(template?.triggerTipo ?? fluxo?.triggerTipo ?? '');
}

/// Junta modelo e fluxo pelo `templateId`: cada automação aparece uma vez.
List<_AutomacaoLinha> _linhasDeAutomacao(
  List<AutomacaoTemplate> templates,
  List<AutomacaoFluxo> fluxos,
) {
  final porTemplate = <String, AutomacaoFluxo>{
    for (final f in fluxos)
      if (f.templateId != null) f.templateId!: f,
  };
  return [
    for (final t in templates)
      _AutomacaoLinha(template: t, fluxo: porTemplate[t.id]),
    // Fluxo sem modelo no catálogo (plano mudou, modelo antigo): continua visível.
    for (final f in fluxos)
      if (f.templateId == null || !templates.any((t) => t.id == f.templateId))
        _AutomacaoLinha(fluxo: f),
  ];
}

extension on _AutomacoesScreenState {
  Widget _buildList(List<_AutomacaoLinha> linhas) {
    final primary = Theme.of(context).colorScheme.primary;
    if (linhas.isEmpty) {
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              icon: FxIcons.raio,
              title: 'Nenhuma automação disponível',
              subtitle: 'As automações do seu plano aparecem aqui.',
              action: FxEmptyAction(label: 'Atualizar', onTap: _load),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        itemCount: linhas.length,
        itemBuilder: (context, i) {
          final linha = linhas[i];
          final template = linha.template;
          final fluxo = linha.fluxo;
          final resumo =
              template == null
                  ? linha.gatilho
                  : '${linha.gatilho} · ${automacaoResumoPassos(template.passos)}';
          return FxSatelliteListTile(
            title: linha.nome,
            titleCase: false,
            subtitle: Text(
              linha.ligada
                  ? '${automacaoLigadaLabel(fluxo?.emAndamento)} · $resumo'
                  : resumo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading: Icon(FxIcons.raio, color: primary),
            trailing: Semantics(
              label:
                  linha.ligada
                      ? 'Desligar ${linha.nome}'
                      : 'Ligar ${linha.nome}',
              child: Switch.adaptive(
                value: linha.ligada,
                onChanged: (ligar) => _alternar(linha, ligar),
              ),
            ),
            onTap: () {
              if (fluxo != null) {
                _openLogs(fluxo);
              } else if (template != null) {
                _ativar(template);
              }
            },
          );
        },
      ),
    );
  }

  Future<void> _alternar(_AutomacaoLinha linha, bool ligar) async {
    final fluxo = linha.fluxo;
    final template = linha.template;
    if (ligar && fluxo == null && template != null) {
      await _ativar(template);
      return;
    }
    if (fluxo == null) return;
    await _toggleFluxoAtivo(fluxo);
  }
}
