part of 'chat_inbox_screen.dart';


class _AlunoPickerSheet extends ConsumerStatefulWidget {
  const _AlunoPickerSheet({required this.onSelect});

  final ValueChanged<Aluno> onSelect;

  @override
  ConsumerState<_AlunoPickerSheet> createState() => _AlunoPickerSheetState();
}

class _AlunoPickerSheetState extends ConsumerState<_AlunoPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final homeAsync = ref.watch(alunosHomeProvider);
    final alunos = alunoPickerAlunosFromHome(homeAsync);

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 12, 16, 16),
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: chrome.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Nova mensagem',
                        style: TextStyle(
                          color: ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: mute),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Buscar aluno',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: chrome.cardFill,
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: chrome.line),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildAlunosBody(
                    homeAsync: homeAsync,
                    alunos: alunos,
                    isDark: isDark,
                    primary: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlunosBody({
    required AsyncValue<AlunosHomeBundle> homeAsync,
    required List<Aluno>? alunos,
    required bool isDark,
    required Color primary,
  }) {
    if (alunos != null) {
      final filtered = filterAlunoPickerAlunos(alunos, _query);
      if (filtered.isEmpty) {
        return FxEmptyState(
          icon: _query.isEmpty ? 'users' : 'search',
          title:
              _query.isEmpty
                  ? 'Nenhum aluno cadastrado'
                  : 'Nenhum aluno encontrado',
          subtitle:
              _query.isEmpty
                  ? 'Cadastre um aluno para poder conversar por aqui.'
                  : 'Tente outro nome ou e-mail.',
        );
      }
      return ListView.separated(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, index) {
          final aluno = filtered[index];
          return _AlunoContactTile(
            aluno: aluno,
            isDark: isDark,
            primary: primary,
            onTap: () => widget.onSelect(aluno),
          );
        },
      );
    }
    if (homeAsync.hasError) {
      return FxErrorState(
        chromeOnDark: isDark,
        primary: primary,
        message: friendlyError(homeAsync.error ?? 'Erro ao carregar alunos'),
        onRetry: () => ref.invalidate(alunosHomeProvider),
      );
    }
    return const SkeletonList(count: 6);
  }
}

class _AlunoContactTile extends StatelessWidget {
  const _AlunoContactTile({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.soft(
      primary,
      dark: Theme.of(context).brightness == Brightness.dark,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: fxListCardDecoration(context),
        child: Row(
          children: [
            aluno.fotoUrl != null && aluno.fotoUrl!.isNotEmpty
                ? CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(aluno.fotoUrl!),
                )
                : CircleAvatar(
                  radius: 22,
                  backgroundColor: soft,
                  child: Text(
                    fxInitials(aluno.nome),
                    style: TextStyle(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aluno.email.isNotEmpty ? aluno.email : 'Aluno',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mute, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_bubble_outline_rounded, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ChatMsg msg;
  final bool isDark;
  final Color ink;
  final Color mute;
  const _SearchResultTile({
    required this.msg,
    required this.isDark,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      onTap: () {
        if (msg.alunoId != null) {
          context.push('/alunos/${msg.alunoId}/chat');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  msg.remetente == 'PERSONAL' ? Icons.person : Icons.school,
                  size: 14,
                  color: mute,
                ),
                const SizedBox(width: 6),
                Text(
                  msg.remetente == 'PERSONAL' ? 'Você' : 'Aluno',
                  style: TextStyle(
                    fontSize: 11,
                    color: mute,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  fxTimeAgo(msg.enviadoEm),
                  style: TextStyle(fontSize: 11, color: mute),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.conteudo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _InboxTile extends StatelessWidget {
  final ChatInboxItem item;
  final bool isDark;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _InboxTile({
    required this.item,
    required this.isDark,
    this.selected = false,
    this.selecting = false,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final brandSoft = BrandPalette.soft(
      primary,
      dark: Theme.of(context).brightness == Brightness.dark,
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration:
            selected
                ? fxListCardDecoration(context, accent: primary, selected: true)
                : fxListCardDecoration(context),
        child: Row(
          children: [
            if (selecting) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? primary : mute.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                ),
                child:
                    selected
                        ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                        : null,
              ),
              const SizedBox(width: 10),
            ],
            // Avatar
            item.fotoUrl != null && item.fotoUrl!.isNotEmpty
                ? CircleAvatar(
                  backgroundImage: NetworkImage(item.fotoUrl!),
                  radius: 24,
                )
                : CircleAvatar(
                  radius: 24,
                  backgroundColor: brandSoft,
                  child: Text(
                    fxInitials(item.alunoNome),
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.alunoNome,
                          style: TextStyle(
                            color: ink,
                            fontWeight:
                                item.naoLidas > 0
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        fxTimeAgo(item.enviadoEm),
                        style: TextStyle(
                          color: item.naoLidas > 0 ? primary : mute,
                          fontSize: 11,
                          fontWeight:
                              item.naoLidas > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (item.ultimoRemetente == 'PERSONAL')
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all, size: 14, color: mute),
                        ),
                      Expanded(
                        child: Text(
                          item.ultimaMensagem,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.naoLidas > 0 ? ink : mute,
                            fontSize: 13,
                            fontWeight:
                                item.naoLidas > 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (item.naoLidas > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            item.naoLidas > 99
                                ? '99+'
                                : item.naoLidas.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
