import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/galeria_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';

class GaleriaScreen extends ConsumerStatefulWidget {
  const GaleriaScreen({super.key});
  @override
  ConsumerState<GaleriaScreen> createState() => _State();
}

class _State extends ConsumerState<GaleriaScreen> {
  List<GalleryItem> _fotos = [];
  bool _loading = true, _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items =
          await GaleriaRepository(ref.read(apiClientProvider)).listar();
      if (mounted) {
        setState(() {
          _fotos = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    if (_fotos.length >= 9) {
      FeedbackHelper.showSuccess(context, 'Limite de 9 fotos atingido.');
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('https://api.cloudinary.com/v1_1/focux/image/upload'),
            )
            ..fields['upload_preset'] = 'focux_unsigned'
            ..files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode != 200) throw Exception('Upload failed');
      final url =
          (jsonDecode(body) as Map<String, dynamic>)['secure_url'] as String;
      await GaleriaRepository(
        ref.read(apiClientProvider),
      ).adicionar(fotoUrl: url, ordem: _fotos.length);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showSuccess(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Remover foto'),
            content: const Text('Remover esta foto da galeria?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remover'),
              ),
            ],
          ),
    );
    if (ok != true) return;
    try {
      await GaleriaRepository(ref.read(apiClientProvider)).deletar(id);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showSuccess(context, 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Galeria (${_fotos.length}/9)'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: FxLoading(strokeWidth: 2),
              ),
            ),
          if (!_uploading && _fotos.length < 9)
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: _add,
            ),
        ],
      ),
      body:
          _loading
              ? const FxLoading()
              : _fotos.isEmpty
              ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color:
                          isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma foto ainda.',
                      style: TextStyle(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Adicionar foto'),
                      onPressed: _add,
                    ),
                  ],
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _fotos.length,
                itemBuilder: (_, i) {
                  final f = _fotos[i];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(f.fotoUrl, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _delete(f.id),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
