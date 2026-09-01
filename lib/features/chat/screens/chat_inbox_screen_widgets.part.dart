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
    final homeAsync = ref.watch(alunosHomeProvider);
    final alunos = alunoPickerAlunosFromHome(homeAsync);
    final maxHeight =
        MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor;

    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight: maxHeight,
      expand: true,
      child: Column(
        children: [
          FxHomeSheetHandle(isDark: isDark),
          SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Nova mensagem',
            leading: Icon(
              Icons.chat_bubble_outline_rounded,
              color: primary,
              size: 18,
            ),
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
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          FxSettingsGroup(
            children: [
              for (var i = 0; i < filtered.length; i++)
                _AlunoContactTile(
                  aluno: filtered[i],
                  isDark: isDark,
                  primary: primary,
                  showDivider: i < filtered.length - 1,
                  onTap: () => widget.onSelect(filtered[i]),
                ),
            ],
          ),
        ],
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
    this.showDivider = true,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    assert(isDark || !isDark);
    return FxSettingsTile(
      fxIcon: 'chat',
      label: aluno.nome,
      subtitle: aluno.email.isNotEmpty ? aluno.email : 'Aluno',
      value: 'Abrir',
      showDivider: showDivider,
      accent: primary,
      accessory: AlunoAvatar(
        name: aluno.nome,
        photoUrl: aluno.fotoUrl,
        variant: AlunoAvatarVariant.strip,
      ),
      onTap: onTap,
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ChatMsg msg;
  final bool isDark;
  final Color ink;
  final Color mute;
  final bool showDivider;
  const _SearchResultTile({
    required this.msg,
    required this.isDark,
    required this.ink,
    required this.mute,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    assert(isDark || !isDark);
    assert(ink.a >= 0 && mute.a >= 0);
    return FxSettingsTile(
      fxIcon: 'chat',
      label: msg.remetente == 'PERSONAL' ? 'Você' : 'Aluno',
      subtitle: msg.conteudo,
      value: fxTimeAgo(msg.enviadoEm),
      showDivider: showDivider,
      onTap: () {
        if (msg.alunoId != null) {
          context.push('/alunos/${msg.alunoId}/chat');
        }
      },
    );
  }
}

class _InboxTile extends StatelessWidget {
  final ChatInboxItem item;
  final bool isDark;
  final bool selected;
  final bool selecting;
  final bool showDivider;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _InboxTile({
    required this.item,
    required this.isDark,
    this.selected = false,
    this.selecting = false,
    this.showDivider = true,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    assert(isDark || !isDark);
    final preview = item.ultimoRemetente == 'PERSONAL'
        ? 'Você: ${item.ultimaMensagem}'
        : item.ultimaMensagem;
    final unread = item.naoLidas;
    return FxSettingsTile(
      icon: selecting && selected ? Icons.check_rounded : null,
      fxIcon: selecting && selected ? null : 'chat',
      label: item.alunoNome,
      subtitle: preview,
      value: unread > 0
          ? (unread > 99 ? '99+' : '$unread')
          : fxTimeAgo(item.enviadoEm),
      highlight: unread > 0 || selected,
      numeric: unread > 0,
      showDivider: showDivider,
      accessory: AlunoAvatar(
        name: item.alunoNome,
        photoUrl: item.fotoUrl,
        variant: AlunoAvatarVariant.strip,
      ),
      semanticsLabel: unread > 0
          ? '${item.alunoNome}. $unread não lidas. $preview'
          : '${item.alunoNome}. $preview',
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
