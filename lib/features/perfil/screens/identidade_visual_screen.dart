import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';

// Paleta Eagle Precision — cores de brand para identidade visual
const _coresPredefinidas = [
  EagleTokens.primary,          // Eagle Royal Blue (#2B4A9E) — padrão
  Color(0xFF1E3A8A),            // Eagle Deep Blue
  Color(0xFF0097A7),            // Ciano complementar
  EagleTokens.success,          // Verde (#22C55E)
  EagleTokens.warning,          // Âmbar (#F59E0B)
  EagleTokens.danger,           // Vermelho (#EF4444)
  Color(0xFF7C3AED),            // Violeta
  Color(0xFF6D28D9),            // Púrpura
  Color(0xFFDB2777),            // Rosa
  Color(0xFF0369A1),            // Azul petróleo
  Color(0xFF374151),            // Cinza slate
  Color(0xFF111827),            // Quase preto
];

class IdentidadeVisualScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const IdentidadeVisualScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<IdentidadeVisualScreen> createState() => _IdentidadeVisualScreenState();
}

class _IdentidadeVisualScreenState extends ConsumerState<IdentidadeVisualScreen> {
  final _descCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _instaCtrl = TextEditingController();
  Color _corPrimaria = _coresPredefinidas[0];
  Color _corSecundaria = _coresPredefinidas[2];
  bool _salvando = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _espCtrl.dispose();
    _instaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      await dio.put('/api/personal/identidade', data: {
        'corPrimaria': '#${_corPrimaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'corSecundaria': '#${_corSecundaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        'descricaoProfissional': _descCtrl.text.trim(),
        'especialidades': _espCtrl.text.trim(),
        'instagram': _instaCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identidade visual salva!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSetup ? 'Configurar meu app' : 'Identidade visual'),
        automaticallyImplyLeading: !widget.isSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isSetup) ...[
              Text('Bem-vindo! 🎉', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Configure a identidade visual do seu app. Seus alunos verão estas cores e informações.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
            ],

            // Passo 1: Cores
            _SecaoTitulo(
              icone: Icons.palette_outlined,
              titulo: 'Cores do app',
              subtitulo: 'Escolha as cores que representam sua marca',
            ),
            const SizedBox(height: 16),
            Text('Cor principal', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _coresPredefinidas.map((cor) {
                final selecionada = cor == _corPrimaria;
                return GestureDetector(
                  onTap: () => setState(() => _corPrimaria = cor),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selecionada ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selecionada
                          ? [BoxShadow(color: cor.withValues(alpha: 0.6), blurRadius: 8)]
                          : null,
                    ),
                    child: selecionada ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Cor secundária', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _coresPredefinidas.map((cor) {
                final selecionada = cor == _corSecundaria;
                return GestureDetector(
                  onTap: () => setState(() => _corSecundaria = cor),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selecionada ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: selecionada
                          ? [BoxShadow(color: cor.withValues(alpha: 0.6), blurRadius: 8)]
                          : null,
                    ),
                    child: selecionada ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                  ),
                );
              }).toList(),
            ),

            // Preview
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_corPrimaria, _corSecundaria],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: const Icon(Icons.fitness_center, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Preview do seu app',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            _SecaoTitulo(
              icone: Icons.person_outline,
              titulo: 'Seu perfil profissional',
              subtitulo: 'Visível no app para seus alunos',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição profissional',
                hintText: 'Ex: Personal trainer especializado em emagrecimento e hipertrofia',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _espCtrl,
              decoration: const InputDecoration(
                labelText: 'Especialidades',
                hintText: 'Ex: Musculação, Funcional, Emagrecimento',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instaCtrl,
              decoration: const InputDecoration(
                labelText: 'Instagram',
                hintText: '@seuperfil',
                prefixIcon: Icon(Icons.camera_alt_outlined),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _salvando ? null : _salvar,
                style: FilledButton.styleFrom(backgroundColor: _corPrimaria),
                child: Text(_salvando ? 'Salvando...' : (widget.isSetup ? 'Finalizar configuração' : 'Salvar')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecaoTitulo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  const _SecaoTitulo({required this.icone, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icone, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: theme.textTheme.titleMedium),
              Text(subtitulo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
