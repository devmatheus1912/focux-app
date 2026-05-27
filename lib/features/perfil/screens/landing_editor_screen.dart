import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';

const _defaultSections = [
  'hero',
  'bio',
  'ofertas',
  'pacotes',
  'servicos',
  'faq',
  'galeria',
  'depoimentos',
  'contato',
];

const _sectionLabels = <String, String>{
  'hero': 'Hero',
  'bio': 'Bio',
  'ofertas': 'Ofertas',
  'pacotes': 'Pacotes',
  'servicos': 'Serviços',
  'faq': 'FAQ',
  'galeria': 'Galeria',
  'depoimentos': 'Depoimentos',
  'contato': 'Contato',
};

class LandingEditorScreen extends ConsumerStatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  ConsumerState<LandingEditorScreen> createState() =>
      _LandingEditorScreenState();
}

class _LandingEditorScreenState extends ConsumerState<LandingEditorScreen> {
  final _heroTitle = TextEditingController();
  final _heroSubtitle = TextEditingController();
  final _primaryCta = TextEditingController();
  List<String> _sectionOrder = List<String>.from(_defaultSections);
  String? _slug;
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _heroTitle.dispose();
    _heroSubtitle.dispose();
    _primaryCta.dispose();
    super.dispose();
  }

  void _applyPerfil(PerfilPersonal p) {
    _heroTitle.text = p.heroTitle ?? '';
    _heroSubtitle.text = p.heroSubtitle ?? '';
    _primaryCta.text = p.primaryCta ?? '';
    _slug = p.slug;
    if (p.sectionOrder.isNotEmpty) {
      _sectionOrder = List<String>.from(p.sectionOrder);
      for (final s in _defaultSections) {
        if (!_sectionOrder.contains(s)) _sectionOrder.add(s);
      }
    }
    _loaded = true;
  }

  void _moveSection(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= _sectionOrder.length) return;
    setState(() {
      final item = _sectionOrder.removeAt(index);
      _sectionOrder.insert(next, item);
    });
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await ref.read(perfilRepositoryProvider).atualizarLanding(
        heroTitle: _heroTitle.text.trim(),
        heroSubtitle: _heroSubtitle.text.trim(),
        primaryCta: _primaryCta.text.trim(),
        sectionOrder: _sectionOrder,
      );
      ref.invalidate(perfilProvider);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Landing atualizada.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copiarPreview() {
    if (_slug == null || _slug!.isEmpty) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Defina seu slug no perfil primeiro.')),
      );
      return;
    }
    final url = 'https://focux.app/p/$_slug';
    Clipboard.setData(ClipboardData(text: url));
    FeedbackHelper.showSnackBar(
      context,
      SnackBar(content: Text('Link copiado: $url')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);

    return perfilAsync.when(
      loading: () => const FxShellScaffold(
        appBar: FxShellAppBar(title: 'Editor da landing'),
        body: Center(child: FxLoading()),
      ),
      error:
          (e, _) => FxShellScaffold(
            appBar: FxShellAppBar(
              title: 'Editor da landing',
              onBack: () => context.pop(),
            ),
            body: Center(child: Text(friendlyError(e))),
          ),
      data: (perfil) {
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _applyPerfil(perfil));
          });
        }
        final preview =
            _slug != null && _slug!.isNotEmpty
                ? 'https://focux.app/p/$_slug'
                : 'Defina slug no perfil';

        return FxShellScaffold(
          appBar: FxShellAppBar(
            title: 'Editor da landing',
            onBack: () => context.pop(),
          ),
          body: ListView(
            padding: const EdgeInsets.all(TokensStrip.s4),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.public),
                  title: Text(preview),
                  subtitle: const Text('Preview do link público'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copiarPreview,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heroTitle,
                decoration: const InputDecoration(labelText: 'Título do hero'),
                maxLength: 180,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _heroSubtitle,
                decoration: const InputDecoration(
                  labelText: 'Subtítulo do hero',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _primaryCta,
                decoration: const InputDecoration(labelText: 'CTA principal'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ordem das seções',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...[
                for (var i = 0; i < _sectionOrder.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Chip(
                          label: Text(
                            _sectionLabels[_sectionOrder[i]] ??
                                _sectionOrder[i],
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: i > 0 ? () => _moveSection(i, -1) : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward),
                          onPressed:
                              i < _sectionOrder.length - 1
                                  ? () => _moveSection(i, 1)
                                  : null,
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _salvar,
                child:
                    _saving
                        ? const FxLoading(size: 22, strokeWidth: 2)
                        : const Text('Salvar landing'),
              ),
            ],
          ),
        );
      },
    );
  }
}
