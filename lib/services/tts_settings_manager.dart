import 'package:shared_preferences/shared_preferences.dart';

class TtsSettingsManager {
  static Future<void> saveSettings({
    required String lang,
    required double speechRate,
    required double pitch,
    required bool showFemaleVoices,
    required bool showMaleVoices,
    required Map<String, String>? selectedVoice,
    required String selectedGender,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('lang', lang);
    await prefs.setDouble('speechRate', speechRate);
    await prefs.setDouble('pitch', pitch);
    await prefs.setBool('showFemaleVoices', showFemaleVoices);
    await prefs.setBool('showMaleVoices', showMaleVoices);
    await prefs.setString('voiceGender', selectedGender);

    if (selectedVoice != null && selectedVoice['name'] != null) {
      await prefs.setString('voiceName', selectedVoice['name']!);
    } else {
      await prefs.remove('voiceName');
    }
  }

  static Future<TtsSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return TtsSettings(
      lang: prefs.getString('lang') ?? 'en-US',
      speechRate: prefs.getDouble('speechRate') ?? 0.5,
      pitch: prefs.getDouble('pitch') ?? 1.0,
      showFemaleVoices: prefs.getBool('showFemaleVoices') ?? true,
      showMaleVoices: prefs.getBool('showMaleVoices') ?? true,
      voiceName: prefs.getString('voiceName'),
      voiceGender: prefs.getString('voiceGender'),
    );
  }
}

class TtsSettings {
  final String lang;
  final double speechRate;
  final double pitch;
  final bool showFemaleVoices;
  final bool showMaleVoices;
  final String? voiceName;
  final String? voiceGender;

  TtsSettings({
    required this.lang,
    required this.speechRate,
    required this.pitch,
    required this.showFemaleVoices,
    required this.showMaleVoices,
    this.voiceName,
    this.voiceGender,
  });
}
