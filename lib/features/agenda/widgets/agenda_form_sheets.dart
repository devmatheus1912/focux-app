import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../alunos/data/aluno_contact_utils.dart';
import '../../alunos/data/aluno_repository.dart';

class _AgendaAlunoAvatar extends StatelessWidget {
  final Aluno? aluno;

  const _AgendaAlunoAvatar({required this.aluno});

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final foto = aluno?.fotoUrl;
    final hasPhoto = foto != null && foto.isNotEmpty;
    final initials = _initials(aluno?.nome ?? '');
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: 42,
        height: 42,
        color: BrandPalette.soft(primary, dark: chrome.isDark),
        child:
            hasPhoto
                ? FxCachedNetworkImage(
                  imageUrl: foto,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  memCacheWidth: 84,
                  errorBuilder: (_, _, _) => _fallback(primary, initials),
                )
                : _fallback(primary, initials),
      ),
    );
  }

  Widget _fallback(Color primary, String initials) {
    if (initials == '?') {
      return Icon(Icons.person_outline_rounded, color: primary, size: 20);
    }
    return Center(
      child: Text(
        initials,
        style: FocuxHubTypography.cardTitle(color: primary),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }
}

class AgendaAlunoSheet extends StatefulWidget {
  final List<Aluno> alunos;
  final int? selectedId;

  const AgendaAlunoSheet({
    super.key,
    required this.alunos,
    required this.selectedId,
  });

  @override
  State<AgendaAlunoSheet> createState() => _AgendaAlunoSheetState();
}

class _AgendaAlunoSheetState extends State<AgendaAlunoSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final query = _search.text.trim().toLowerCase();
    final alunos =
        widget.alunos.where((aluno) {
          if (query.isEmpty) return true;
          return aluno.nome.toLowerCase().contains(query) ||
              aluno.email.toLowerCase().contains(query) ||
              (aluno.objetivo ?? '').toLowerCase().contains(query);
        }).toList();

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Selecionar aluno, ${alunos.length} de ${widget.alunos.length}',
      child: FxHomeSheetSurface(
        isDark: chrome.isDark,
        expand: true,
        maxHeight:
            MediaQuery.sizeOf(context).height *
            FxHomeSheetChrome.expandHeightFactor,
        child: Column(
          children: [
            FxHomeSheetHandle(isDark: chrome.isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: chrome.isDark,
              title: 'Selecionar aluno',
              subtitle: '${alunos.length} de ${widget.alunos.length}',
              leading: Icon(
                Icons.person_outline_rounded,
                color: primary,
                size: 18,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            Semantics(
              textField: true,
              label: 'Buscar por nome, e-mail ou objetivo',
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, e-mail ou objetivo',
                  prefixIcon: Icon(Icons.search, size: 19, color: chrome.mute),
                  filled: true,
                  fillColor:
                      chrome.isDark
                          ? EagleTokens.darkCardHi
                          : TokensStrip.pageBg,
                  border: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: chrome.lineStrong),
                  ),
                  enabledBorder: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: chrome.lineStrong),
                  ),
                  focusedBorder: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primary),
                  ),
                ),
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            Expanded(
              child:
                  alunos.isEmpty
                      ? FxEmptyState(
                        icon: 'search',
                        title:
                            query.isEmpty
                                ? 'Nenhum aluno'
                                : 'Nada com essa busca',
                        subtitle:
                            query.isEmpty
                                ? 'Cadastre um aluno para marcar o atendimento.'
                                : 'Tente outro nome, e-mail ou objetivo.',
                      )
                      : ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: alunos.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final aluno = alunos[index];
                          final selected = aluno.id == widget.selectedId;
                          return Semantics(
                            button: true,
                            selected: selected,
                            label:
                                'Aluno ${aluno.nome}${selected ? ', selecionado' : ''}',
                            child: InkWell(
                              onTap: () => Navigator.pop(context, aluno),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      selected
                                          ? primary.withValues(
                                            alpha: chrome.isDark ? 0.18 : 0.10,
                                          )
                                          : chrome.cardFill,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        selected ? primary : chrome.lineStrong,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _AgendaAlunoAvatar(aluno: aluno),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            aluno.nome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FocuxHubTypography.cardTitle(
                                              color: chrome.ink,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            [
                                              if ((aluno.objetivo ?? '')
                                                  .isNotEmpty)
                                                aluno.objetivo!,
                                              maskEmailForList(aluno.email),
                                            ].join(' · '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: FocuxHubTypography.bodyMuted(
                                              color: chrome.mute,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      selected
                                          ? Icons.check_circle
                                          : Icons.check_circle_outline,
                                      color: selected ? primary : chrome.mute,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
