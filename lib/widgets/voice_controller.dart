import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import '../services/gemini_service.dart';

class VoiceController extends StatefulWidget {
  const VoiceController({Key? key}) : super(key: key);

  @override
  State<VoiceController> createState() => _VoiceControllerState();
}

class _VoiceControllerState extends State<VoiceController> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press the button and start speaking';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );
    if (!available) {
      setState(() {
        _text = 'Speech recognition not available';
      });
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _text = 'Listening...';
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _text = result.recognizedWords;
              if (result.finalResult) {
                _isListening = false;
                _processVoiceCommand(result.recognizedWords);
              }
            });
          },
        );
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _processVoiceCommand(String command) {
    final geminiService = context.read<GeminiService>();
    command = command.toLowerCase();

    if (command.contains('generate') && command.contains('insight')) {
      geminiService.generateInsight('Generate comprehensive business insights');
    } else if (command.contains('show') && command.contains('revenue')) {
      geminiService.generateInsight('Analyze revenue trends and provide insights');
    } else if (command.contains('customer')) {
      geminiService.generateInsight('Analyze customer behavior and satisfaction');
    } else if (command.contains('market')) {
      geminiService.generateInsight('Analyze market trends and opportunities');
    } else if (command.contains('performance')) {
      geminiService.generateInsight('Analyze overall business performance metrics');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command not recognized: $command'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voice Assistant',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _isListening ? _stopListening : _startListening,
                  color: _isListening
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try saying: "Show me revenue trends" or "Generate insights"',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
} 