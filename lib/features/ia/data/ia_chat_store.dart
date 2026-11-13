import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uma mensagem da conversa com a IA Focux: [autor] PERSONAL ou IA.
class IaChatMsg {
  const IaChatMsg({required this.autor, required this.texto});

  final String autor;
  final String texto;

  bool get daIa => autor == 'IA';

  Map<String, dynamic> toJson() => {'autor': autor, 'texto': texto};

  factory IaChatMsg.fromJson(Map<String, dynamic> j) => IaChatMsg(
    autor: j['autor'] == 'IA' ? 'IA' : 'PERSONAL',
    texto: j['texto'] as String? ?? '',
  );
}

/// Conversa guardada no aparelho (não vai para o servidor).
class IaConversa {
  const IaConversa({
    required this.id,
    required this.atualizadaEm,
    required this.mensagens,
    this.alunoId,
    this.alunoNome,
  });

  final String id;
  final DateTime atualizadaEm;
  final List<IaChatMsg> mensagens;
  final int? alunoId;
  final String? alunoNome;

  /// A primeira pergunta, curta, para a lista de conversas.
  String get titulo {
    final primeira =
        mensagens.where((m) => !m.daIa).map((m) => m.texto.trim()).firstOrNull ??
        'Conversa';
    return primeira.length > 60 ? '${primeira.substring(0, 60)}…' : primeira;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'atualizadaEm': atualizadaEm.toIso8601String(),
    'alunoId': alunoId,
    'alunoNome': alunoNome,
    'mensagens': [for (final m in mensagens) m.toJson()],
  };

  factory IaConversa.fromJson(Map<String, dynamic> j) => IaConversa(
    id: j['id'] as String? ?? '',
    atualizadaEm:
        DateTime.tryParse(j['atualizadaEm'] as String? ?? '') ?? DateTime.now(),
    alunoId: (j['alunoId'] as num?)?.toInt(),
    alunoNome: j['alunoNome'] as String?,
    mensagens: [
      for (final m in (j['mensagens'] as List?) ?? const [])
        if (m is Map) IaChatMsg.fromJson(Map<String, dynamic>.from(m)),
    ],
  );
}

/// Até as 20 últimas conversas, mais recente primeiro.
class IaChatStore {
  static const _chave = 'ia_focux_conversas_v1';
  static const maxConversas = 20;

  Future<List<IaConversa>> listar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chave);
      if (raw == null) return const [];
      final lista = jsonDecode(raw);
      if (lista is! List) return const [];
      return [
        for (final c in lista)
          if (c is Map) IaConversa.fromJson(Map<String, dynamic>.from(c)),
      ]..sort((a, b) => b.atualizadaEm.compareTo(a.atualizadaEm));
    } catch (_) {
      return const [];
    }
  }

  Future<void> salvar(IaConversa conversa) async {
    final todas = [
      conversa,
      ...(await listar()).where((c) => c.id != conversa.id),
    ].take(maxConversas).toList();
    await _gravar(todas);
  }

  Future<void> apagar(String id) async {
    await _gravar((await listar()).where((c) => c.id != id).toList());
  }

  /// "Apagar todas" (lista completa, com confirmação).
  Future<void> apagarTodas() => _gravar(const []);

  Future<void> _gravar(List<IaConversa> todas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chave,
        jsonEncode([for (final c in todas) c.toJson()]),
      );
    } catch (_) {
      // Sem armazenamento, a conversa vale só enquanto a tela está aberta.
    }
  }
}

final iaChatStoreProvider = Provider((ref) => IaChatStore());

final iaConversasProvider = FutureProvider.autoDispose<List<IaConversa>>(
  (ref) => ref.read(iaChatStoreProvider).listar(),
);

/// O que vai para o servidor como histórico: as últimas 12 mensagens.
List<Map<String, String>> iaHistoricoParaEnvio(List<IaChatMsg> msgs) {
  final ultimas = msgs.length > 12 ? msgs.sublist(msgs.length - 12) : msgs;
  return [
    for (final m in ultimas)
      {
        'autor': m.autor,
        'texto': m.texto.length > 2000 ? m.texto.substring(0, 2000) : m.texto,
      },
  ];
}
