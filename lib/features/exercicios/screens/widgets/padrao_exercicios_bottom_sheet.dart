import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/enums.dart';
import '../../data/exercicio_repository.dart';
import '../../data/exercicio_taxonomy_labels.dart';
import '../../providers/exercicios_provider.dart';

class PadraoExerciciosBottomSheet extends ConsumerWidget {
  const PadraoExerciciosBottomSheet({
    super.key,
    this.padrao,
    this.grupo,
    required this.onAdicionar,
  });

  final PadraoMovimento? padrao;
  final GrupoMuscular? grupo;
  final ValueChanged<Exercicio> onAdicionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(exerciciosProvider);
    final title =
        padrao != null
            ? TaxonomyLabels.padrao[padrao!] ?? 'Padrao'
            : TaxonomyLabels.grupo[grupo!] ?? 'Grupo';

    return SafeArea(
      child: asyncList.when(
        loading:
            () => const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (e, _) => const SizedBox(
              height: 220,
              child: Center(child: Text('Nao foi possivel carregar.')),
            ),
        data: (all) {
          final items =
              all.where((ex) {
                if (padrao != null) return ex.padraoMovimento == padrao;
                if (grupo != null) return ex.grupoMuscularPrimario == grupo;
                return false;
              }).toList()
                ..sort((a, b) {
                  final video = (b.hasPlayableMedia ? 1 : 0).compareTo(
                    a.hasPlayableMedia ? 1 : 0,
                  );
                  if (video != 0) return video;
                  return a.nome.compareTo(b.nome);
                });

          return Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhum exercicio nessa categoria.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ex = items[index];
                        final subtitle = [
                          if (ex.grupoMuscularPrimario != null)
                            TaxonomyLabels.grupo[ex.grupoMuscularPrimario!],
                          if (ex.equipamentos.isNotEmpty)
                            ex.equipamentos
                                .take(2)
                                .map((e) => TaxonomyLabels.equipamento[e])
                                .whereType<String>()
                                .join(' / '),
                        ].whereType<String>().join(' - ');
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            ex.hasPlayableMedia
                                ? Icons.play_circle_fill_rounded
                                : Icons.videocam_off_outlined,
                          ),
                          title: Text(ex.nome),
                          subtitle: subtitle.isEmpty ? null : Text(subtitle),
                          trailing: const Icon(Icons.add_rounded),
                          onTap: () {
                            Navigator.pop(context);
                            onAdicionar(ex);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
