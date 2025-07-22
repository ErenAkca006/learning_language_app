import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsService with ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  String _currentLang = 'en-US';
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String? _voiceName; // 👈 artık voiceId yerine voiceName

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _currentLang = prefs.getString('lang') ?? 'en-US';
    _speechRate = prefs.getDouble('speechRate') ?? 0.5;
    _pitch = prefs.getDouble('pitch') ?? 1.0;
    _voiceName = prefs.getString('voiceName'); // 👈 voiceName yükleniyor

    await _applySettings();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> updateSettings({
    String? lang,
    double? speechRate,
    double? pitch,
    String? voiceName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (lang != null) {
      _currentLang = lang;
      await prefs.setString('lang', lang);
    }
    if (speechRate != null) {
      _speechRate = speechRate;
      await prefs.setDouble('speechRate', speechRate);
    }
    if (pitch != null) {
      _pitch = pitch;
      await prefs.setDouble('pitch', pitch);
    }
    if (voiceName != null) {
      _voiceName = voiceName;
      await prefs.setString('voiceName', voiceName);
    }

    await _applySettings();
    notifyListeners();
  }

  Future<void> _applySettings() async {
    await _tts.setLanguage(_currentLang);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);

    final voices = await _tts.getVoices;
    if (voices is List) {
      final selectedVoice = voices.firstWhere(
        (v) => v['name']?.toString() == _voiceName,
        orElse: () => voices.first,
      );

      final voiceMap = Map<String, String>.from(
        selectedVoice.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ),
      );

      debugPrint(
        '🗣️ Seçilen Ses: ${voiceMap['name']} (ID: ${voiceMap['id']})',
      );
      await _tts.setVoice(voiceMap);
    }
  }

  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    _tts.setCompletionHandler(() {
      if (onComplete != null) onComplete();
    });
    await _tts.speak(text);
  }

  Future<void> setCompletionHandler(VoidCallback onComplete) async {
    _tts.setCompletionHandler(onComplete);
  }

  Future<void> stop() => _tts.stop();

  // Getterlar
  String get currentLang => _currentLang;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  String? get voiceName => _voiceName;

  Future<void> awaitSpeakCompletion(bool awaitCompletion) async {
    await _tts.awaitSpeakCompletion(awaitCompletion);
  }
}
