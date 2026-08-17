part of 'evolucao_screen.dart';

// ─── Banner variação ──────────────────────────────────────────────────────────

class _BannerVariacao extends StatelessWidget {
  final String texto;
  const _BannerVariacao({required this.texto});

  @override
  Widget build(BuildContext context) {
    final isPositivo = texto.startsWith('+');
    final cor = isPositivo ? EagleTokens.bad : EagleTokens.good;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: cor.withValues(alpha: 0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositivo ? Icons.trending_up : Icons.trending_down,
            color: cor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Medidas ──────────────────────────────────────────────────────────────

class _TabMedidas extends StatelessWidget {
  final int alunoId;
  final String alunoNome;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final VoidCallback onRegister;
  final VoidCallback onRetry;
  const _TabMedidas({
    required this.alunoId,
    required this.alunoNome,
    required this.medidasAsync,
    required this.onRegister,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return medidasAsync.when(
      loading: () => const SkeletonList(count: 4),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: Theme.of(context).brightness == Brightness.dark,
            primary: Theme.of(context).colorScheme.primary,
            message: friendlyError(e),
            onRetry: onRetry,
            title: 'Não conseguimos carregar as medidas',
          ),
      data: (lista) {
        if (lista.isEmpty) {
          final first = satelliteFirstName(alunoNome);
          return satelliteEmptyBody(
            child: FxEmptyState(
              key: const ValueKey('evolucao_medidas_empty'),
              icon: 'trend',
              title: 'Nenhuma medida registrada',
              subtitle:
                  'Registre peso e circunferências de $first para liberar o gráfico e o radar corporal.',
              action: FxEmptyAction(
                label: 'Registrar medida',
                onTap: onRegister,
              ),
            ),
          );
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
        final pesos = [...lista]..sort((a, b) => a.data.compareTo(b.data));
        final weightData =
            pesos.where((m) => m.peso != null).map((m) => m.peso!).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 16, 16, 80),
          itemCount: ordenada.length + (weightData.length > 1 ? 1 : 0),
          itemBuilder: (_, i) {
            if (weightData.length > 1 && i == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: fxListCardDecoration(
                  context,
                  accent: EagleTokens.good,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  child: FxSparkline(
                    data: weightData,
                    width: 320,
                    height: 72,
                    color: EagleTokens.good,
                    fill: true,
                  ),
                ),
              );
            }
            final index = weightData.length > 1 ? i - 1 : i;
            return _CardMedida(medida: ordenada[index]);
          },
        );
      },
    );
  }
}

class _CardMedida extends StatelessWidget {
  final MedidaCorporal medida;
  const _CardMedida({required this.medida});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: TokensStrip.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  fxDateShort(DateTime.parse(medida.data)),
                  style: const TextStyle(
                    color: TokensStrip.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (medida.peso != null)
                  _Chip(
                    label: 'Peso',
                    valor: '${medida.peso!.toStringAsFixed(1)} kg',
                  ),
                if (medida.cintura != null)
                  _Chip(
                    label: 'Abdômen',
                    valor: '${medida.cintura!.toStringAsFixed(1)} cm',
                  ),
                if (medida.quadril != null)
                  _Chip(
                    label: 'Quadril',
                    valor: '${medida.quadril!.toStringAsFixed(1)} cm',
                  ),
                if (medida.braco != null)
                  _Chip(
                    label: 'Braço',
                    valor: '${medida.braco!.toStringAsFixed(1)} cm',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Recordes ─────────────────────────────────────────────────────────────

class _TabRecordes extends StatelessWidget {
  final int alunoId;
  final String alunoNome;
  final AsyncValue<List<RecordePessoal>> recordesAsync;
  final VoidCallback onRegister;
  final VoidCallback onRetry;
  const _TabRecordes({
    required this.alunoId,
    required this.alunoNome,
    required this.recordesAsync,
    required this.onRegister,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return recordesAsync.when(
      loading: () => const SkeletonList(count: 4),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: Theme.of(context).brightness == Brightness.dark,
            primary: Theme.of(context).colorScheme.primary,
            message: friendlyError(e),
            onRetry: onRetry,
            title: 'Não conseguimos carregar os recordes',
          ),
      data: (lista) {
        if (lista.isEmpty) {
          final first = satelliteFirstName(alunoNome);
          return satelliteEmptyBody(
            child: FxEmptyState(
              key: const ValueKey('evolucao_recordes_empty'),
              icon: 'star',
              title: 'Nenhum recorde registrado',
              subtitle:
                  'Marque o primeiro recorde de $first após um check-in ou treino forte.',
              action: FxEmptyAction(
                label: 'Registrar recorde',
                onTap: onRegister,
              ),
            ),
          );
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 16, 16, 80),
          itemCount: ordenada.length,
          itemBuilder: (_, i) => _CardRecorde(recorde: ordenada[i]),
        );
      },
    );
  }
}

class _CardRecorde extends StatelessWidget {
  final RecordePessoal recorde;
  const _CardRecorde({required this.recorde});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return fxListTileCardShell(
      context: context,
      margin: const EdgeInsets.only(bottom: 10),
      accent: primary,
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: EagleTokens.goldSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.emoji_events, color: EagleTokens.gold),
        ),
        title: Text(
          recorde.exercicioNome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (recorde.cargaKg != null)
              '${recorde.cargaKg!.toStringAsFixed(1)}kg',
            if (recorde.repeticoes != null) '${recorde.repeticoes} reps',
            fxDateShort(DateTime.parse(recorde.data)),
          ].join(' × '),
          style: const TextStyle(
            fontSize: 12,
            color: TokensStrip.textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'NOVO PR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets utilitários ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label, valor;
  const _Chip({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: TokensStrip.textSecondary,
            ),
          ),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CampoNumerico extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _CampoNumerico({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
