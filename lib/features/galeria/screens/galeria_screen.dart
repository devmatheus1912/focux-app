import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/galeria_repository.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class GaleriaScreen extends ConsumerStatefulWidget {
  const GaleriaScreen({super.key});
  @override
  ConsumerState<GaleriaScreen> createState() => _State();
}

class _State extends ConsumerState<GaleriaScreen> {
  List<GalleryItem> _fotos = [];
  bool _loading = true, _uploading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final items =
          await GaleriaRepository(ref.read(apiClientProvider)).listar();
      if (mounted) {
        setState(() {
          _fotos = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
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
      final client = ref.read(apiClientProvider);
      final url = await MediaUploadService(client).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'galeria',
        resourceType: 'image',
      );
      await GaleriaRepository(
        client,
      ).adicionar(fotoUrl: url, ordem: _fotos.length);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
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
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return fxScreenA11yScope(
      label: 'Galeria',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Galeria',
          subtitle: '${_fotos.length} de 9 fotos',
          actions: [
            if (_uploading)
              const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: FxLoading(size: 20, strokeWidth: 2),
              ),
            if (!_uploading && _fotos.length < 9)
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: 'Adicionar foto',
                onPressed: _add,
              ),
          ],
        ),
        body:
            _loading
                ? const FxLoading()
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: Theme.of(context).colorScheme.primary,
                  message: _erro!,
                  onRetry: _load,
                  title: 'Não conseguimos carregar a galeria',
                )
                : _fotos.isEmpty
                ? FxEmptyState(
                  icon: 'image',
                  title: 'Nenhuma foto ainda',
                  subtitle: 'Adicione até 9 fotos para o seu perfil público.',
                  action: FxEmptyAction(
                    label: 'Adicionar foto',
                    onTap: _add,
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
      ),
    );
  }
}
