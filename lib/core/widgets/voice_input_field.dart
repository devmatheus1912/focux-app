import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceInputField extends StatefulWidget {
  final Function(String) onSubmitted;
  const VoiceInputField({super.key, required this.onSubmitted});

  @override
  State<VoiceInputField> createState() => _VoiceInputFieldState();
}

class _VoiceInputFieldState extends State<VoiceInputField> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "";
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() {
            _text = val.recognizedWords;
            _controller.text = _text;
          });
        });
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_controller.text.isNotEmpty) {
        widget.onSubmitted(_controller.text);
        _controller.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Digite ou fale sua mensagem...',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                widget.onSubmitted(val);
                _controller.clear();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton(
          mini: true,
          onPressed: _listen,
          backgroundColor: _isListening ? Colors.red : Theme.of(context).primaryColor,
          child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          color: Theme.of(context).primaryColor,
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              widget.onSubmitted(_controller.text);
              _controller.clear();
            }
          },
        )
      ],
    );
  }
}
