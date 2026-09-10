import 'package:flutter/material.dart';

import '../../../core/widgets/fx_input_deco.dart';

class IaChatComposer extends StatelessWidget {
  const IaChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.focusNode,
    this.loading = false,
    this.hint = 'Pergunte ao assistente…',
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode? focusNode;
  final bool loading;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        8,
        8 +
            (mq.viewInsets.bottom > 0 ? 0 : mq.padding.bottom),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: FxInputDeco.build(context, hint),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Enviar',
            icon: const Icon(Icons.send_rounded),
            onPressed: loading ? null : onSend,
          ),
        ],
      ),
    );
  }
}
