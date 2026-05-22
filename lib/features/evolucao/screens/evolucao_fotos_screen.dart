import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';

class EvolucaoFotosScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoFotosScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });
  @override
  ConsumerState<EvolucaoFotosScreen> createState() => _State();
}

class _State extends ConsumerState<EvolucaoFotosScreen> {
  final _picker = ImagePicker();
  List<_Foto> _fotos = [];
  bool _loading = true;
  int? _selBefore;
  int? _selAfter;
  double _slider = 0.5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get('/api/alunos/${widget.alunoId}/fotos');
      final list =
          (res.data as List? ?? [])
              .map((e) => _Foto.fromJson(e as Map<String, dynamic>))
              .toList();
      if (mounted) {
        setState(() {
          _fotos = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFoto() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Câmera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeria'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );
    if (src == null) return;
    final file = await _picker.pickImage(
      source: src,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final bytes = await file.readAsBytes();
      final fd = FormData.fromMap({
        'foto': MultipartFile.fromBytes(bytes, filename: file.name),
      });
      await api.dio.post('/api/alunos/${widget.alunoId}/fotos', data: fd);
      HapticFeedback.mediumImpact();
      await _load();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        FeedbackHelper.showSuccess(context, 'Erro: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Evolução · ${widget.alunoNome}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _addFoto),
        ],
      ),
      body:
          _loading
              ? const FxLoading()
              : _fotos.isEmpty
              ? _empty(primary)
              : _content(isDark, primary),
    );
  }

  Widget _empty(Color p) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: p.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.compare, size: 64, color: p),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhuma foto de evolução',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tire a primeira foto para acompanhar a evolução.',
            textAlign: TextAlign.center,
            style: TextStyle(color: EagleTokens.inkMute),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addFoto,
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text(
              'Tirar Foto',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: p,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _content(bool isDark, Color primary) => Column(
    children: [
      if (_selBefore != null && _selAfter != null) ...[
        Padding(padding: const EdgeInsets.all(16), child: _comparison()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Slider(
            value: _slider,
            onChanged: (v) => setState(() => _slider = v),
            activeColor: primary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Antes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: EagleTokens.inkMute,
                ),
              ),
              Text(
                'Depois',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: EagleTokens.inkMute,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(
          children: [
            Text(
              '${_fotos.length} foto${_fotos.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: EagleTokens.inkMute,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (_selBefore != null || _selAfter != null)
              TextButton(
                onPressed:
                    () => setState(() {
                      _selBefore = null;
                      _selAfter = null;
                    }),
                child: const Text('Limpar'),
              ),
          ],
        ),
      ),
      Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: _fotos.length,
          itemBuilder: (ctx, i) {
            final f = _fotos[i];
            final isB = _selBefore == i;
            final isA = _selAfter == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (_selBefore == null) {
                  setState(() => _selBefore = i);
                } else if (_selAfter == null && _selBefore != i) {
                  setState(() => _selAfter = i);
                } else {
                  setState(() {
                    _selBefore = i;
                    _selAfter = null;
                  });
                }
              },
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      f.url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (isB || isA)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isB ? Colors.orange : Colors.green,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f.dataFmt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _comparison() {
    final w = MediaQuery.of(context).size.width - 32;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 300,
        width: w,
        child: Stack(
          children: [
            Image.network(
              _fotos[_selAfter!].url,
              fit: BoxFit.cover,
              width: w,
              height: 300,
            ),
            ClipRect(
              clipper: _Clip(_slider, w),
              child: Image.network(
                _fotos[_selBefore!].url,
                fit: BoxFit.cover,
                width: w,
                height: 300,
              ),
            ),
            Positioned(
              left: w * _slider - 1,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _Clip extends CustomClipper<Rect> {
  final double f;
  final double w;
  _Clip(this.f, this.w);
  @override
  Rect getClip(Size s) => Rect.fromLTWH(0, 0, w * f, s.height);
  @override
  bool shouldReclip(_Clip o) => o.f != f;
}

class _Foto {
  final int id;
  final String url;
  final String data;
  _Foto({required this.id, required this.url, required this.data});
  factory _Foto.fromJson(Map<String, dynamic> j) => _Foto(
    id: j['id'] ?? 0,
    url: j['url'] ?? j['fotoUrl'] ?? '',
    data: j['data'] ?? j['createdAt'] ?? '',
  );
  String get dataFmt {
    try {
      return fxDateShort(DateTime.parse(data));
    } catch (_) {
      return data.length >= 10 ? data.substring(0, 10) : data;
    }
  }
}
