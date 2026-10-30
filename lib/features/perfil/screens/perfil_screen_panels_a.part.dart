part of 'perfil_screen.dart';

/// Código do personal: o aluno precisa dele em todo plano, sem cadeado.
class _PerfilAcessoAlunos extends StatelessWidget {
  const _PerfilAcessoAlunos({
    required this.perfil,
    required this.mute,
    required this.line,
  });

  final PerfilPersonal perfil;
  final Color mute;
  final Color line;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final codigo = perfil.slug?.trim() ?? '';
    final escolher = perfil.needsBrandPublicIdentity || codigo.isEmpty;
    return FxSettingsGroup(
      header: s.perfilAcessoAlunos,
      caption: escolher ? s.perfilEscolhaCodigoTexto : null,
      children: [
        FxSettingsTile(
          icon: Icons.key_outlined,
          label: escolher ? s.perfilEscolhaCodigo : s.perfilSeuCodigo,
          value:
              escolher
                  ? ''
                  : codigo.length > 22
                  ? '${codigo.substring(0, 20)}…'
                  : codigo,
          mute: mute,
          line: line,
          showDivider: false,
          onTap:
              escolher
                  ? () => context.push('/perfil/link-publico', extra: perfil)
                  : () => showPerfilCodigoSheet(context, perfil: perfil),
        ),
      ],
    );
  }
}

class _PerfilVitrineTiles extends ConsumerWidget {
  const _PerfilVitrineTiles({
    required this.mute,
    required this.line,
    required this.onOpenEditor,
  });

  final Color mute;
  final Color line;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marca = PlanGate.watch(ref, PlanoRecursoKeys.whiteLabel);
    final landing = PlanGate.watch(ref, PlanoRecursoKeys.landing);

    return Column(
      children: [
        FxSettingsTile(
          icon: Icons.language_outlined,
          label: S.of(context).perfilPaginaPublica,
          value: '',
          mute: mute,
          line: line,
          locked: !landing.liberado,
          upgradeTierLabel: PlanGate.tierLabel(landing.planoMinimo),
          onTap: onOpenEditor,
        ),
        FxSettingsTile(
          icon: Icons.palette_outlined,
          label: 'Marca',
          value: '',
          mute: mute,
          line: line,
          locked: !marca.liberado,
          upgradeTierLabel: PlanGate.tierLabel(marca.planoMinimo),
          showDivider: false,
          onTap: PlanGate.tap(
            context,
            ref,
            PlanoRecursoKeys.whiteLabel,
            featureName: 'Marca própria',
            source: 'perfil_marca',
            action: () => context.push('/identidade-visual'),
          ),
        ),
      ],
    );
  }
}
