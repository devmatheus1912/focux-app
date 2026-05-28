import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/pacote_repository.dart';

/// Skeleton de carregamento — alinhado ao Setup D0.
class PacotesStorefrontSkeleton extends StatelessWidget {
  const PacotesStorefrontSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : TokensStrip.borderDefault;
    final highlight = isDark ? EagleTokens.darkCardHi : TokensStrip.pageBg;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          for (var i = 0; i < 3; i++) ...[
            Container(
              height: 132,
              margin: const EdgeInsets.only(bottom: TokensStrip.s3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Resumo dinâmico — contagem e ticket médio.
class PacotesOverviewStrip extends StatelessWidget {
  const PacotesOverviewStrip({super.key, required this.pacotes});

  final List<Pacote> pacotes;

  @override
  Widget build(BuildContext context) {
    if (pacotes.isEmpty) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final count = pacotes.length;
    final ticketMedio = pacotes.map((p) => p.valor).reduce((a, b) => a + b) / count;
    final ticketLabel = ticketMedio.toStringAsFixed(2).replaceAll('.', ',');

    return Semantics(
      label:
          '$count ${count == 1 ? 'plano ativo' : 'planos ativos'}, preço médio R\$ $ticketLabel',
      child: Container(
        margin: const EdgeInsets.only(bottom: TokensStrip.s3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          border: Border.all(color: primary.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(Icons.inventory_2_outlined, size: 18, color: primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? 'plano ativo' : 'planos ativos'} · preço médio R\$ $ticketLabel',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explica o fluxo em linguagem simples — sem jargão de “vitrine”.
class PacotesComoFuncionaCard extends StatelessWidget {
  const PacotesComoFuncionaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s3),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 20, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como funciona',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Você monta planos com preço (ex.: musculação, 3 meses, R\$ 500). '
                  'Eles ficam numa página sua na internet. Envie o link no WhatsApp ou '
                  'Instagram — a pessoa vê seus planos e pode te contratar.',
                  style: TokensStrip.bodyMuted(color: mute).copyWith(
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card premium do link público da storefront.
class StorefrontLinkCard extends StatelessWidget {
  const StorefrontLinkCard({
    super.key,
    required this.slug,
    required this.onCopy,
    required this.onPreview,
  });

  final String slug;
  final VoidCallback onCopy;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final label = Env.landingPageDisplayLabel(slug);

    return Semantics(
      container: true,
      label: 'Link da sua página de vendas na internet, $label',
      child: Container(
        decoration: fxStripCardDecoration(context, accent: primary),
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.public_rounded, color: primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua página na internet',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Como um cartão de visitas online: o cliente abre o link, '
                        'vê seus planos e valores e pode te chamar.',
                        style: TokensStrip.bodyMuted(color: mute).copyWith(
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Link para enviar no WhatsApp ou Instagram',
              style: TokensStrip.bodyMuted(color: mute).copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : TokensStrip.pageBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : TokensStrip.borderDefault,
                ),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Copiar link da página de vendas',
                    child: FxLiquidSecondaryButton(
                      label: 'Copiar link',
                      icon: Icons.link_rounded,
                      onPressed: onCopy,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Ver página como o cliente vê',
                    child: FxLiquidSecondaryButton(
                      label: 'Ver como cliente',
                      icon: Icons.open_in_new_rounded,
                      onPressed: onPreview,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state alinhado ao Setup D0.
class PacotesEmptyState extends StatelessWidget {
  const PacotesEmptyState({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    return Container(
      decoration: fxStripCardDecoration(context),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined, color: primary, size: 28),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Crie seu primeiro plano',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Um plano tem nome, preço e o que está incluso (treino, nutrição…). '
            'Ele aparece na sua página quando alguém abrir seu link.\n\n'
            'Ex.: Musculação · 3 meses · R\$ 500',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.45),
          ),
          const SizedBox(height: TokensStrip.s5),
          FxLiquidPrimaryButton(
            label: 'Criar plano',
            icon: Icons.add_rounded,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// Card de pacote na lista.
class PacoteStorefrontCard extends StatelessWidget {
  const PacoteStorefrontCard({
    super.key,
    required this.pacote,
    required this.onDelete,
    this.entranceIndex = 0,
  });

  final Pacote pacote;
  final VoidCallback onDelete;
  final int entranceIndex;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s3),
      decoration: fxStripCardDecoration(
        context,
        accent: pacote.destaque ? primary : null,
        glowStrength: pacote.destaque ? 0.55 : 0.38,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pacote.destaque) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DESTAQUE NA PÁGINA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  pacote.titulo,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.5,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Desativar pacote ${pacote.titulo}',
                child: IconButton(
                  tooltip: 'Desativar pacote',
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onDelete();
                  },
                  icon: Icon(Icons.delete_outline_rounded, color: mute),
                ),
              ),
            ],
          ),
          if (pacote.descricao != null && pacote.descricao!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              pacote.descricao!,
              style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.35),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (pacote.incluiTreino) const _PacoteTag('Treino'),
              if (pacote.incluiNutri) const _PacoteTag('Nutrição'),
              if (pacote.incluiConsultoria) const _PacoteTag('Consultoria'),
              _PacoteTag(
                '${pacote.duracaoMeses} ${pacote.duracaoMeses == 1 ? 'mês' : 'meses'}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'R\$ ${pacote.valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ),
    );

    if (reduceMotionOf(context)) return card;
    return card
        .animate(delay: Duration(milliseconds: entranceIndex * 70))
        .fadeIn(duration: 260.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.03, curve: Curves.easeOutCubic, duration: 280.ms);
  }
}

class _PacoteTag extends StatelessWidget {
  const _PacoteTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Estado de erro com retry.
class PacotesLoadErrorState extends StatelessWidget {
  const PacotesLoadErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mute = fxScreenMute(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: mute),
            const SizedBox(height: TokensStrip.s3),
            Text(
              'Não foi possível carregar seus planos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: fxScreenInk(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            FxLiquidPrimaryButton(
              label: 'Tentar novamente',
              expand: false,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre bottom sheet premium; retorna true se pacote foi criado.
Future<bool> showNovoPacoteSheet(
  BuildContext context, {
  required PacoteRepository repo,
}) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NovoPacoteSheet(repo: repo),
  );
  return created ?? false;
}

/// Confirma desativação antes de remover da vitrine.
Future<bool> confirmDesativarPacote(BuildContext context, String titulo) async {
  final ink = fxScreenInk(context);
  final mute = fxScreenMute(context);
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCard : TokensStrip.pageBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Desativar plano?',
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '“$titulo” some da sua página na internet. '
                'Quem abrir seu link não verá mais este plano. '
                'Você pode criar outro depois.',
                textAlign: TextAlign.center,
                style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.4),
              ),
              const SizedBox(height: 20),
              FxLiquidPrimaryButton(
                label: 'Desativar',
                icon: Icons.delete_outline_rounded,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 10),
              FxLiquidSecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

class _NovoPacoteSheet extends StatefulWidget {
  const _NovoPacoteSheet({required this.repo});

  final PacoteRepository repo;

  @override
  State<_NovoPacoteSheet> createState() => _NovoPacoteSheetState();
}

class _NovoPacoteSheetState extends State<_NovoPacoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();

  int _duracao = 1;
  bool _treino = true;
  bool _nutri = false;
  bool _consultoria = false;
  bool _destaque = false;
  bool _enviando = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() => _enviando = true);
    try {
      await widget.repo.criar(
        titulo: _tituloCtrl.text.trim(),
        descricao:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        valor: double.parse(_valorCtrl.text.trim().replaceAll(',', '.')),
        duracaoMeses: _duracao,
        incluiTreino: _treino,
        incluiNutri: _nutri,
        incluiConsultoria: _consultoria,
        destaque: _destaque,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final reduceMotion = reduceMotionOf(context);

    Widget sheet = Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : TokensStrip.pageBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? EagleTokens.darkLine
                          : TokensStrip.borderDefault,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Novo plano',
                        style: TextStyle(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Fechar',
                      child: IconButton(
                        tooltip: 'Fechar',
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed:
                            _enviando ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Quem abrir seu link verá este plano na sua página de vendas.',
                  style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tituloCtrl,
                  enabled: !_enviando,
                  textInputAction: TextInputAction.next,
                  decoration: FxInputDeco.build(
                    context,
                    'Título *',
                    icon: Icons.title_rounded,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Informe um título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  enabled: !_enviando,
                  textInputAction: TextInputAction.next,
                  maxLines: 2,
                  decoration: FxInputDeco.build(
                    context,
                    'Descrição',
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorCtrl,
                  enabled: !_enviando,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  decoration: FxInputDeco.build(
                    context,
                    'Valor que o cliente paga (R\$) *',
                    icon: Icons.attach_money_rounded,
                    hint: 'Ex.: 500',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o valor';
                    }
                    final valor =
                        double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;
                    if (valor <= 0) return 'Valor deve ser maior que zero';
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _SheetSectionLabel('Duração do plano', ink: ink),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final meses in [1, 3, 6, 12])
                      _PacoteOptionChip(
                        label: meses == 1 ? '1 mês' : '$meses meses',
                        selected: _duracao == meses,
                        onTap:
                            _enviando
                                ? null
                                : () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _duracao = meses);
                                },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _SheetSectionLabel('O que inclui', ink: ink),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PacoteOptionChip(
                      label: 'Treino',
                      selected: _treino,
                      onTap:
                          _enviando
                              ? null
                              : () => setState(() => _treino = !_treino),
                    ),
                    _PacoteOptionChip(
                      label: 'Nutrição',
                      selected: _nutri,
                      onTap:
                          _enviando
                              ? null
                              : () => setState(() => _nutri = !_nutri),
                    ),
                    _PacoteOptionChip(
                      label: 'Consultoria',
                      selected: _consultoria,
                      onTap:
                          _enviando
                              ? null
                              : () => setState(() => _consultoria = !_consultoria),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SheetSectionLabel('Mostrar em destaque', ink: ink),
                const SizedBox(height: 10),
                _PacoteOptionChip(
                  label: 'Aparecer primeiro na página',
                  selected: _destaque,
                  onTap:
                      _enviando
                          ? null
                          : () => setState(() => _destaque = !_destaque),
                ),
                const SizedBox(height: 20),
                FxLiquidPrimaryButton(
                  label: 'Criar plano',
                  icon: Icons.check_rounded,
                  loading: _enviando,
                  loadingLabel: 'Criando…',
                  onPressed: _enviando ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) return sheet;
    return sheet
        .animate()
        .fadeIn(duration: 220.ms, curve: Curves.easeOutCubic)
        .slideY(begin: 0.04, curve: Curves.easeOutCubic, duration: 260.ms);
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.label, {required this.ink});

  final String label;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: ink,
        fontWeight: FontWeight.w700,
        fontSize: 13.5,
        letterSpacing: -0.1,
      ),
    );
  }
}

class _PacoteOptionChip extends StatelessWidget {
  const _PacoteOptionChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onTap == null ? null : (_) => onTap!(),
        showCheckmark: selected,
        checkmarkColor: Colors.white,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 10 : 9,
          vertical: selected ? 7 : 6,
        ),
        labelStyle: TextStyle(
          color: selected ? Colors.white : ink,
          fontSize: selected ? 12 : 11.5,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
        ),
        selectedColor: primary,
        backgroundColor:
            isDark ? Colors.white.withValues(alpha: 0.035) : TokensStrip.pageBg,
        side: BorderSide(
          color:
              selected
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : TokensStrip.borderDefault),
        ),
      ),
    );
  }
}

/// Copia link real; toast amigável sem URL crua.
void copyStorefrontLink(BuildContext context, String? slug) {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para gerar o link da sua página de vendas.',
    );
    return;
  }
  Clipboard.setData(ClipboardData(text: Env.landingPageUrl(slug)));
  FeedbackHelper.showSuccess(context, 'Link copiado!');
}

/// Abre vitrine no navegador externo.
Future<void> openStorefrontPreview(BuildContext context, String? slug) async {
  if (slug == null || slug.isEmpty) {
    FeedbackHelper.showWarn(
      context,
      'Complete seu perfil para abrir sua página de vendas.',
    );
    return;
  }
  final uri = Uri.parse(Env.landingPageUrl(slug));
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (opened) {
      FeedbackHelper.showInfo(context, 'Abrindo como seu cliente vê…');
    } else {
      FeedbackHelper.showWarn(context, 'Não foi possível abrir o link.');
    }
  } catch (_) {
    if (!context.mounted) return;
    FeedbackHelper.showError(context, 'Não foi possível abrir a página.');
  }
}
