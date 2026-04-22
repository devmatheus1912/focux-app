import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhiteLabelScreen extends ConsumerStatefulWidget {
  const WhiteLabelScreen({super.key});

  @override
  ConsumerState<WhiteLabelScreen> createState() => _WhiteLabelScreenState();
}

class _WhiteLabelScreenState extends ConsumerState<WhiteLabelScreen> {
  Color _corPrimaria = const Color(0xFF6C63FF);
  Color _corSecundaria = const Color(0xFF00BFA6);
  final _nomeCtrl = TextEditingController(text: 'Meu Studio');
  bool _saving = false;

  final _cores = [
    const Color(0xFF6C63FF),
    const Color(0xFF2196F3),
    const Color(0xFF00BCD4),
    const Color(0xFF4CAF50),
    const Color(0xFFFF5722),
    const Color(0xFF9C27B0),
    const Color(0xFFFF9800),
    const Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Identidade Visual'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _salvar,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Preview Card
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_corPrimaria, _corSecundaria],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                _nomeCtrl.text,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Nome do Studio
          Text('Nome do Studio', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          TextField(
            controller: _nomeCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Ex: FitLife Studio',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 28),

          // Cor Primária
          Text('Cor Primária', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          _colorPicker(selected: _corPrimaria, onSelect: (c) => setState(() => _corPrimaria = c)),
          const SizedBox(height: 28),

          // Cor Secundária
          Text('Cor Secundária', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 12),
          _colorPicker(selected: _corSecundaria, onSelect: (c) => setState(() => _corSecundaria = c)),
          const SizedBox(height: 32),

          // Plano info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EagleTokens.warn.withValues(alpha: 0.1),
              border: Border.all(color: EagleTokens.warn),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, color: EagleTokens.warn),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Domínio personalizado e logo exclusiva disponíveis no plano Enterprise.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorPicker({required Color selected, required ValueChanged<Color> onSelect}) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _cores.map((c) {
        final isSelected = c == selected;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
              boxShadow: isSelected ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1)); // simulate API call
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identidade visual salva!'), backgroundColor: EagleTokens.good),
      );
    }
  }
}
