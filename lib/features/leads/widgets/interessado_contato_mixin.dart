import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../data/lead_repository.dart';
import '../utils/interessados_display.dart';
import 'interessado_sheets.dart';

/// WhatsApp/Ligar com a pergunta "Conversou com X?" ao voltar ao app.
/// Só pergunta quando a saída foi por esse toque (AppLifecycleListener).
mixin InteressadoContatoMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  AppLifecycleListener? _ouvinte;
  Lead? _saiuCom;
  String? _saiuPor;

  LeadRepository get repoInteressados;

  /// Chamado depois de anotar o contato (recarregar a tela).
  Future<void> aoAnotarContato();

  @override
  void initState() {
    super.initState();
    _ouvinte = AppLifecycleListener(onResume: _voltou);
  }

  @override
  void dispose() {
    _ouvinte?.dispose();
    super.dispose();
  }

  Future<void> contatarInteressado(Lead lead, String tipo) async {
    _saiuCom = lead;
    _saiuPor = tipo;
    final abriu = await abrirContatoInteressado(lead, tipo);
    if (!abriu) {
      _saiuCom = null;
      _saiuPor = null;
      if (mounted) {
        FeedbackHelper.showWarn(
          context,
          tipo == 'WHATSAPP'
              ? 'Não deu para abrir o WhatsApp deste número.'
              : 'Não deu para ligar para este número.',
        );
      }
    }
  }

  Future<void> _voltou() async {
    final lead = _saiuCom;
    final tipo = _saiuPor;
    _saiuCom = null;
    _saiuPor = null;
    if (lead == null || !mounted) return;
    if (!interessadoPerguntarConversa(saiuPor: tipo)) return;
    final anotou = await showConversouSheet(
      context,
      repo: repoInteressados,
      lead: lead,
      tipo: tipo!,
    );
    if (anotou && mounted) await aoAnotarContato();
  }
}
