import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';

class FeedAlunoScreen extends ConsumerStatefulWidget {
  const FeedAlunoScreen({super.key});

  @override
  ConsumerState<FeedAlunoScreen> createState() => _FeedAlunoScreenState();
}

class _FeedAlunoScreenState extends ConsumerState<FeedAlunoScreen> {
  List<FeedPost> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final posts = await FeedRepository(ref.read(apiClientProvider)).listarAluno();
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Nenhuma publicação disponível.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (_, i) {
                      final p = _posts[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.titulo,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(p.conteudo, style: const TextStyle(fontSize: 14)),
                              if (p.imagemUrl != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p.imagemUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                p.criadoEm.length >= 10
                                    ? p.criadoEm.substring(0, 10)
                                    : p.criadoEm,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
