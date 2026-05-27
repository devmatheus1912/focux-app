import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/landing_growth_repository.dart';
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
  final _offerCta = TextEditingController();
  final _finalCta = TextEditingController();
  final _contactCta = TextEditingController();
  List<String> _sectionOrder = List<String>.from(_defaultSections);
  List<LandingServiceItem> _servicos = [];
  List<LandingFaqItem> _faq = [];
  String? _slug;
  String? _heroImageUrl;
  String? _bioImageUrl;
  bool _loaded = false;
  bool _saving = false;
  bool _uploadingHero = false;
  bool _uploadingBio = false;
  bool _generatingHero = false;
  List<LandingNichePreset> _presets = [];
  List<LandingChecklistItem> _checklist = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGrowth());
  }

  Future<void> _loadGrowth() async {
    try {
      final repo = ref.read(landingGrowthRepositoryProvider);
      final presets = await repo.presets();
      final checklist = await repo.checklist();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _checklist = checklist;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _heroTitle.dispose();
    _heroSubtitle.dispose();
    _primaryCta.dispose();
    _offerCta.dispose();
    _finalCta.dispose();
    _contactCta.dispose();
    super.dispose();
  }

  void _applyPerfil(PerfilPersonal p) {
    _heroTitle.text = p.heroTitle ?? '';
    _heroSubtitle.text = p.heroSubtitle ?? '';
    _primaryCta.text = p.primaryCta ?? '';
    _offerCta.text = p.offerCta ?? '';
    _finalCta.text = p.finalCta ?? '';
    _contactCta.text = p.contactCta ?? '';
    _slug = p.slug;
    _heroImageUrl = p.heroImageUrl;
    _bioImageUrl = p.bioImageUrl;
    _servicos = p.servicos.map((e) => LandingServiceItem(
      titulo: e.titulo,
      descricao: e.descricao,
    )).toList();
    _faq = p.faq.map((e) => LandingFaqItem(
      pergunta: e.pergunta,
      resposta: e.resposta,
    )).toList();
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

  void _addServico() {
    setState(() {
      _servicos = [
        ..._servicos,
        const LandingServiceItem(titulo: '', descricao: ''),
      ];
    });
  }

  void _removeServico(int index) {
    setState(() => _servicos = [..._servicos]..removeAt(index));
  }

  void _updateServico(int index, {String? titulo, String? descricao}) {
    final current = _servicos[index];
    setState(() {
      _servicos[index] = LandingServiceItem(
        titulo: titulo ?? current.titulo,
        descricao: descricao ?? current.descricao,
      );
    });
  }

  void _addFaq() {
    setState(() {
      _faq = [
        ..._faq,
        const LandingFaqItem(pergunta: '', resposta: ''),
      ];
    });
  }

  void _removeFaq(int index) {
    setState(() => _faq = [..._faq]..removeAt(index));
  }

  void _updateFaq(int index, {String? pergunta, String? resposta}) {
    final current = _faq[index];
    setState(() {
      _faq[index] = LandingFaqItem(
        pergunta: pergunta ?? current.pergunta,
        resposta: resposta ?? current.resposta,
      );
    });
  }

  Future<void> _uploadImage({required bool hero}) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1920,
    );
    if (file == null || !mounted) return;
    setState(() {
      if (hero) {
        _uploadingHero = true;
      } else {
        _uploadingBio = true;
      }
    });
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: hero ? 'landing/hero' : 'landing/bio',
        resourceType: 'image',
      );
      if (!mounted) return;
      setState(() {
        if (hero) {
          _heroImageUrl = url;
        } else {
          _bioImageUrl = url;
        }
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (hero) {
            _uploadingHero = false;
          } else {
            _uploadingBio = false;
          }
        });
      }
    }
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await ref.read(perfilRepositoryProvider).atualizarLanding(
        heroTitle: _heroTitle.text.trim(),
        heroSubtitle: _heroSubtitle.text.trim(),
        primaryCta: _primaryCta.text.trim(),
        sectionOrder: _sectionOrder,
        servicos: _servicos,
        faq: _faq,
        heroImageUrl: _heroImageUrl,
        bioImageUrl: _bioImageUrl,
        offerCta: _offerCta.text.trim(),
        finalCta: _finalCta.text.trim(),
        contactCta: _contactCta.text.trim(),
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
    final url = Env.landingPageUrl(_slug!);
    Clipboard.setData(ClipboardData(text: url));
    FeedbackHelper.showSnackBar(
      context,
      SnackBar(content: Text('Link copiado: $url')),
    );
  }

  Widget _imageUploadCard({
    required String title,
    required String? imageUrl,
    required bool uploading,
    required VoidCallback onUpload,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                child: const Icon(Icons.image_outlined, size: 36),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: uploading ? null : onUpload,
              icon: uploading
                  ? const FxLoading(size: 18, strokeWidth: 2)
                  : const Icon(Icons.upload_outlined),
              label: Text(uploading ? 'Enviando…' : 'Enviar imagem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (onAdd != null)
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
          ),
      ],
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
      error: (e, _) => FxShellScaffold(
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
                ? Env.landingPageUrl(_slug!)
                : 'Defina slug no perfil';
        final capturaLink = _slug != null && _slug!.isNotEmpty
            ? Env.capturaPageUrl(_slug!)
            : null;

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
                  subtitle: const Text('Preview do link público (site)'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copiarPreview,
                  ),
                ),
              ),
              if (capturaLink != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bolt_outlined),
                    title: Text(capturaLink),
                    subtitle: const Text('Link Captura — priorize para vender'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: capturaLink));
                        FeedbackHelper.showSnackBar(
                          context,
                          SnackBar(content: Text('Link captura copiado')),
                        );
                      },
                    ),
                  ),
                ),
              if (_presets.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Preset de nicho',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets
                      .map(
                        (p) => ActionChip(
                          label: Text(p.label),
                          onPressed: _saving
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(landingGrowthRepositoryProvider)
                                        .applyPreset(p.id);
                                    ref.invalidate(perfilProvider);
                                    if (!context.mounted) return;
                                    FeedbackHelper.showSuccess(
                                      context,
                                      'Preset ${p.label} aplicado',
                                    );
                                    await _loadGrowth();
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    FeedbackHelper.showError(
                                      context,
                                      friendlyError(e),
                                    );
                                  }
                                },
                        ),
                      )
                      .toList(),
                ),
              ],
              if (_checklist.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Checklist vendas (${_checklist.where((c) => c.done).length}/${_checklist.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                ..._checklist.map(
                  (item) => CheckboxListTile(
                    value: item.done,
                    onChanged: null,
                    title: Text(item.label, style: const TextStyle(fontSize: 14)),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Hero',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _generatingHero
                    ? null
                    : () async {
                        setState(() => _generatingHero = true);
                        try {
                          final copy = await ref
                              .read(landingGrowthRepositoryProvider)
                              .generateHero();
                          _heroTitle.text = copy.heroTitle;
                          _heroSubtitle.text = copy.heroSubtitle;
                          _primaryCta.text = copy.primaryCta;
                          if (!context.mounted) return;
                          FeedbackHelper.showSuccess(
                            context,
                            'Copy gerada com IA',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          FeedbackHelper.showError(context, friendlyError(e));
                        } finally {
                          if (mounted) setState(() => _generatingHero = false);
                        }
                      },
                icon: _generatingHero
                    ? const FxLoading(size: 16, strokeWidth: 2)
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Gerar hero com IA'),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              _imageUploadCard(
                title: 'Imagem do hero',
                imageUrl: _heroImageUrl,
                uploading: _uploadingHero,
                onUpload: () => _uploadImage(hero: true),
              ),
              const SizedBox(height: 12),
              _imageUploadCard(
                title: 'Imagem da bio',
                imageUrl: _bioImageUrl,
                uploading: _uploadingBio,
                onUpload: () => _uploadImage(hero: false),
              ),
              const SizedBox(height: 20),
              const Text(
                'CTAs adicionais',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _offerCta,
                decoration: const InputDecoration(labelText: 'CTA ofertas'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _finalCta,
                decoration: const InputDecoration(labelText: 'CTA final'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contactCta,
                decoration: const InputDecoration(labelText: 'CTA contato'),
              ),
              const SizedBox(height: 20),
              _sectionHeader('Serviços', onAdd: _addServico),
              const SizedBox(height: 8),
              if (_servicos.isEmpty)
                Text(
                  'Nenhum serviço cadastrado.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              for (var i = 0; i < _servicos.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Serviço ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeServico(i),
                              tooltip: 'Remover serviço',
                            ),
                          ],
                        ),
                        TextFormField(
                          key: ValueKey('servico-titulo-$i'),
                          initialValue: _servicos[i].titulo,
                          decoration: const InputDecoration(labelText: 'Título'),
                          onChanged: (v) => _updateServico(i, titulo: v),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: ValueKey('servico-desc-$i'),
                          initialValue: _servicos[i].descricao,
                          decoration: const InputDecoration(labelText: 'Descrição'),
                          maxLines: 3,
                          onChanged: (v) => _updateServico(i, descricao: v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionHeader('FAQ', onAdd: _addFaq),
              const SizedBox(height: 8),
              if (_faq.isEmpty)
                Text(
                  'Nenhuma pergunta cadastrada.',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              for (var i = 0; i < _faq.length; i++) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'FAQ ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeFaq(i),
                              tooltip: 'Remover FAQ',
                            ),
                          ],
                        ),
                        TextFormField(
                          key: ValueKey('faq-pergunta-$i'),
                          initialValue: _faq[i].pergunta,
                          decoration: const InputDecoration(labelText: 'Pergunta'),
                          onChanged: (v) => _updateFaq(i, pergunta: v),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: ValueKey('faq-resposta-$i'),
                          initialValue: _faq[i].resposta,
                          decoration: const InputDecoration(labelText: 'Resposta'),
                          maxLines: 3,
                          onChanged: (v) => _updateFaq(i, resposta: v),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Ordem das seções',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < _sectionOrder.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          _sectionLabels[_sectionOrder[i]] ?? _sectionOrder[i],
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _salvar,
                child: _saving
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
