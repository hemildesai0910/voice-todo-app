import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;

  Future<void> initialize() async {
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      
      if (available) {
        await _flutterTts.setLanguage("en-US");
        await _flutterTts.setSpeechRate(0.9);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
      }
    } catch (e) {
      debugPrint('Error initializing voice services: $e');
    }
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isListening) {
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  bool get isListening => _isListening;
  
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
} 