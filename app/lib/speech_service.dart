import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _speech.initialize(
      onError: (error) => print('❌ Speech error: $error'),
      onStatus: (status) => print('🎤 Speech status: $status'),
    );
    
    return _isInitialized;
  }

  Future<String?> listenForDestination() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_speech.isAvailable) {
      print('❌ Speech recognition not available');
      return null;
    }

    String? result;
    
    await _speech.listen(
      onResult: (speechResult) {
        if (speechResult.finalResult) {
          result = _extractDestination(speechResult.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 5),
      pauseFor: const Duration(seconds: 3),
    );

    // Wait for result
    await Future.delayed(const Duration(seconds: 6));
    await _speech.stop();
    
    return result;
  }

  String? _extractDestination(String spokenText) {
    print('🗣️ Heard: $spokenText');
    
    // Simple extraction - look for common navigation phrases
    String lower = spokenText.toLowerCase();
    
    // Remove common navigation prefixes
    List<String> prefixes = [
      'navigate to ',
      'take me to ',
      'go to ',
      'directions to ',
      'route to ',
      'find ',
    ];
    
    for (String prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        return spokenText.substring(prefix.length).trim();
      }
    }
    
    // If no prefix, assume the entire text is the destination
    return spokenText.trim();
  }

  bool get isListening => _speech.isListening;

  void cancel() {
    _speech.cancel();
  }

  void dispose() {
    _speech.stop();
  }
}
