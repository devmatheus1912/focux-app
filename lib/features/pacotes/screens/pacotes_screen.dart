import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/perfil/data/perfil_repository.dart';
import '../data/pacote_repository.dart';

final _pacoteRepoProvider = Provider(
  (ref) => PacoteRepository(ref.read(apiClientProvider)),
);
final _perfilRepoProvider = Provider(
  (ref) => PerfilRepository(ref.read(apiClientProvider)),
);

class PacotesScreen extends ConsumerStatefulWidget {
  const PacotesScreen({super.key});

  @override
  ConsumerState<PacotesScreen> createState() => _PacotesScreenState();
}

class _PacotesScreenState extends ConsumerState<PacotesScreen> {
  List<Pacote> _pacotes = [];
  bool _loading = true;
  String? _slug;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(_pacoteRepoProvider);
      final perfilRepo = ref.read(_perfilRepoProvider);
      final lista = await repo.listar();
      String? slug;
      try {
        final perfil = await perfilRepo.buscar();
        slug = perfil.slug;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _pacotes = lista;
        _slug = slug;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _novoPacote() async {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    int duracao = 1;
    bool treino = true;
    bool nutri = false;
    bool consultoria = false;
    bool destaque = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Novo pacote'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: tituloCtrl,
                    decoration: const InputDecoration(labelText: 'Título')),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Descrição')),
                TextField(
                    controller: valorCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor (R\$)')),
                Row(
                  children: [
                    const Text('Duração (meses):'),
                    const SizedBox(width: 12),
                    DropdownButton<int>(
                      value: duracao,
                      items: [1, 3, 6, 12]
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m'),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setLocal(() => duracao = v ?? 1),
                    ),
                  ],
                ),
                CheckboxListTile(
                  value: treino,
                  onChanged: (v) => setLocal(() => treino = v ?? true),
                  title: const Text('Inclui treino'),
                ),
                CheckboxListTile(
                  value: nutri,
                  onChanged: (v) => setLocal(() => nutri = v ?? false),
                  title: const Text('Inclui nutrição'),
                ),
                CheckboxListTile(
                  value: consultoria,
                  onChanged: (v) =>
                      setLocal(() => consultoria = v ?? false),
                  title: const Text('Inclui consultoria'),
                ),
                CheckboxListTile(
                  value: destaque,
                  onChanged: (v) => setLocal(() => destaque = v ?? false),
                  title: const Text('Pacote em destaque'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Criar')),
          ],
        ),
      ),
    );

    if (ok == true && tituloCtrl.text.trim().isNotEmpty) {
      final valor = double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 0;
      if (valor <= 0) return;
      try {
        await ref.read(_pacoteRepoProvider).criar(
              titulo: tituloCtrl.text.trim(),
              descricao: descCtrl.text.trim(),
              valor: valor,
              duracaoMeses: duracao,
              incluiTreino: treino,
              incluiNutri: nutri,
              incluiConsultoria: consultoria,
              destaque: destaque,
            );
        await _carregar();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  void _copiarLink() {
    if (_slug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina seu slug em Perfil para gerar o link público.')),
      );
      return;
    }
    final url = 'https://focux.app/p/${_slug!}';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Link copiado: $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacotes & Storefront'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Copiar link público',
            onPressed: _copiarLink,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novoPacote,
        icon: const Icon(Icons.add),
        label: const Text('Novo pacote'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_slug != null)
                    Card(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(.4),
                      child: ListTile(
                        leading: const Icon(Icons.public),
                        title: Text('focux.app/p/$_slug'),
                        subtitle: const Text(
                            'Compartilhe este link para captar leads diretos.'),
                        trailing: TextButton(
                          onPressed: _copiarLink,
                          child: const Text('Copiar'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (_pacotes.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'Crie seu primeiro pacote',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Combinar treino+nutri+consultoria em um SKU aumenta ARPU em 30-60% (Trainerize 2026).',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._pacotes.map((p) => _PacoteCard(pacote: p, onDelete: () async {
                          await ref.read(_pacoteRepoProvider).desativar(p.id);
                          await _carregar();
                        })),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _PacoteCard extends StatelessWidget {
  const _PacoteCard({required this.pacote, required this.onDelete});
  final Pacote pacote;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: pacote.destaque
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (pacote.destaque)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('DESTAQUE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                if (pacote.destaque) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pacote.titulo,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (pacote.descricao != null && pacote.descricao!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(pacote.descricao!,
                    style: theme.textTheme.bodySmall),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (pacote.incluiTreino) const _Chip('Treino'),
                if (pacote.incluiNutri) const _Chip('Nutrição'),
                if (pacote.incluiConsultoria) const _Chip('Consultoria'),
                _Chip('${pacote.duracaoMeses} ${pacote.duracaoMeses == 1 ? 'mês' : 'meses'}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'R\$ ${pacote.valor.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
