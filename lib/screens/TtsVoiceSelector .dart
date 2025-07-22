import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_word_app/services/tts_settings_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsSettingsScreen extends StatefulWidget {
  const TtsSettingsScreen({super.key});

  @override
  _TtsSettingsScreenState createState() => _TtsSettingsScreenState();
}

class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  final FlutterTts _tts = FlutterTts();
  final List<String> _supportedLanguages = ['en-US', 'en-GB'];
  Set<String> _favoriteVoiceNames = {};
  bool _showOnlyFavorites = false;

  String _selectedGender = "male";
  String _currentLang = 'en-US';
  List<Map<String, String>> _voices = [];
  List<Map<String, String>> _filteredVoices = [];
  Map<String, String>? _selectedVoice;

  double _speechRate = 0.5;
  double _pitch = 1.0;

  bool _isLoading = true;
  bool _isSpeaking = false;
  bool _showFemaleVoices = true;
  bool _showMaleVoices = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadFavorites();
    _tts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });

    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });

    _tts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      _showError('TTS Hatası: $msg');
    });
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favoriteVoices') ?? [];
    final showFav = prefs.getBool('showOnlyFavorites') ?? false;

    setState(() {
      _favoriteVoiceNames = favList.toSet();
      _showOnlyFavorites = showFav;
    });
  }

  Future<void> _toggleFavorite(String voiceName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favoriteVoiceNames.contains(voiceName)) {
        _favoriteVoiceNames.remove(voiceName);
      } else {
        _favoriteVoiceNames.add(voiceName);
      }
    });
    await prefs.setStringList('favoriteVoices', _favoriteVoiceNames.toList());
    _filterVoices(); // Liste güncellensin
  }

  Future<void> _loadSettings() async {
    final settings = await TtsSettingsManager.loadSettings();

    _currentLang = settings.lang;
    _speechRate = settings.speechRate;
    _pitch = settings.pitch;
    _showFemaleVoices = settings.showFemaleVoices;
    _showMaleVoices = settings.showMaleVoices;
    _selectedGender = settings.voiceGender ?? 'female';

    await _initTts(settings.voiceName); // 💡 Artık name ile
    setState(() {});
  }

  Future<void> _initTts([String? savedVoiceName]) async {
    setState(() => _isLoading = true);

    try {
      await _tts.setLanguage(_currentLang);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);

      final voicesData = await _tts.getVoices;
      _voices = _convertVoicesToList(voicesData, _currentLang);
      _filterVoices();

      if (savedVoiceName != null) {
        final matchedVoice = _filteredVoices.firstWhere(
          (v) => v['name'] == savedVoiceName,
          orElse: () => _findBestVoice() ?? _filteredVoices.first,
        );
        _selectedVoice = matchedVoice;
      } else {
        _selectedVoice = _filteredVoices.first;
      }

      if (_selectedVoice != null) {
        debugPrint('🎤 Seçilen Ses: ${_selectedVoice!['name']}');
        await _tts.setVoice(_selectedVoice!);
      }
    } catch (e) {
      _showError('TTS Başlatma Hatası: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterVoices() {
    setState(() {
      _filteredVoices =
          _voices.where((voice) {
            final name = voice['name']?.toLowerCase() ?? '';

            final isMale =
                name.contains('tpd') ||
                name.contains('iol') ||
                name.contains('iom') ||
                name.contains('gbd') ||
                name.contains('rjs') ||
                name.contains('gbb') ||
                name.contains('man');

            if (_selectedGender == 'male' && isMale) return true;
            if (_selectedGender == 'female' && !isMale) return true;
            // Favorilere göre filtre
            // if (_showOnlyFavorites &&
            //     !_favoriteVoiceNames.contains(voice['name'])) {
            //   return true;
            // }
            return false;
          }).toList();

      if (_filteredVoices.isNotEmpty &&
          !_filteredVoices.contains(_selectedVoice)) {
        _selectedVoice = _filteredVoices.first;
      }
    });
  }

  List<Map<String, String>> _convertVoicesToList(
    dynamic voicesData,
    String lang,
  ) {
    final List<Map<String, String>> result = [];

    if (voicesData is List) {
      for (var voice in voicesData) {
        if (voice is Map && voice['locale'] == lang) {
          final converted = voice.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          );
          result.add(Map<String, String>.from(converted));
        }
      }
    }

    return result;
  }

  Map<String, String>? _findBestVoice() {
    try {
      return _filteredVoices.firstWhere(
        (v) => v['name']?.contains('local') ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSettings() async {
    await TtsSettingsManager.saveSettings(
      lang: _currentLang,
      speechRate: _speechRate,
      showFemaleVoices: _showFemaleVoices,
      showMaleVoices: _showMaleVoices,
      selectedVoice: _selectedVoice,
      pitch: _pitch,
      selectedGender: _selectedGender,
    );
    // Ayarlar kaydedildiğinde kullanıcıya bildirim göster
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2139),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ayarlar başarıyla kaydedildi!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white),
                onPressed: () {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  if (messenger != null) {
                    messenger.hideCurrentSnackBar();
                  } else {
                    debugPrint("ScaffoldMessenger bulunamadı");
                  }
                },
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _speakTest() async {
    try {
      if (_isSpeaking) {
        await _tts.stop();
        setState(() {
          _isSpeaking = false;
        });
      } else {
        // Önce dil, sonra ses!
        await _tts.setLanguage(_currentLang);
        if (_selectedVoice != null) {
          await _tts.setVoice(_selectedVoice!);
        }
        await _tts.setSpeechRate(_speechRate);
        await _tts.setPitch(_pitch);

        setState(() => _isSpeaking = true);
        await _tts.speak("Can you hear this voice clearly?");
      }
    } catch (e) {
      _showError('Okuma Hatası: ${e.toString()}');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ses Ayarları'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Ayarları Kaydet',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSettingCard(
                      title: 'AKSAN',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(
                            color: Colors.grey[700]!,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _currentLang,
                          isExpanded: true,
                          dropdownColor: Color(0xFF1E2139),
                          underline: SizedBox(),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          items:
                              _supportedLanguages.map((lang) {
                                return DropdownMenuItem(
                                  value: lang,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.language,
                                            size: 16,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            lang,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() => _currentLang = value);
                              await _initTts();
                            }
                          },
                        ),
                      ),
                    ),
                    if (_voices.isNotEmpty) ...[
                      _showOnlyFavorites
                          ? _buildSettingCard(
                            title: 'SES',
                            child: Column(
                              children: [
                                // Kadın/Erkek filtreleme butonları
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedGender = 'female';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _selectedGender == 'female'
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withOpacity(0.2)
                                                  : Theme.of(context).cardColor,
                                          foregroundColor:
                                              _selectedGender == 'female'
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.secondary
                                                  : Colors.grey[400],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.horizontal(
                                                  left: Radius.circular(8),
                                                ),
                                            side: BorderSide(
                                              color:
                                                  _selectedGender == 'female'
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.secondary
                                                      : Colors.grey[600]!,
                                              width: 1,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.female, size: 18),
                                            SizedBox(width: 8),
                                            Text('Kadın'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedGender = 'male';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _selectedGender == 'male'
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.2)
                                                  : Theme.of(context).cardColor,
                                          foregroundColor:
                                              _selectedGender == 'male'
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                  : Colors.grey[400],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.horizontal(
                                                  right: Radius.circular(8),
                                                ),
                                            side: BorderSide(
                                              color:
                                                  _selectedGender == 'male'
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Colors.grey[600]!,
                                              width: 1,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.male, size: 18),
                                            SizedBox(width: 8),
                                            Text('Erkek'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Favorilerden seçilmiş ve cinsiyete göre filtrelenmiş sesler listesi
                                Builder(
                                  builder: (_) {
                                    final favVoices =
                                        _voices.where((voice) {
                                          final isFav = _favoriteVoiceNames
                                              .contains(voice['name']);
                                          final isMale =
                                              (voice['name']
                                                      ?.toLowerCase()
                                                      .contains(
                                                        RegExp(
                                                          r'tpd|iol|iom|gbd|rjs|gbb',
                                                        ),
                                                      ) ??
                                                  false);
                                          final genderMatch =
                                              _selectedGender == 'male'
                                                  ? isMale
                                                  : !isMale;
                                          return isFav && genderMatch;
                                        }).toList();

                                    if (favVoices.isEmpty) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Text(
                                          'Favorilere eklenmiş ses bulunamadı',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      );
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(
                                          color: Colors.grey[700]!,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              150, // 2 * kVoiceItemHeight
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: favVoices.length,
                                          itemBuilder: (context, index) {
                                            final voice = favVoices[index];
                                            final name =
                                                voice['name']?.toLowerCase() ??
                                                '';
                                            final isMale =
                                                name.contains('tpd') ||
                                                name.contains('iol') ||
                                                name.contains('iom') ||
                                                name.contains('gbd') ||
                                                name.contains('rjs') ||
                                                name.contains('gbb');
                                            final isSelected =
                                                _selectedVoice == voice;
                                            final isFavorite =
                                                _favoriteVoiceNames.contains(
                                                  voice['name'],
                                                );

                                            return InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  _selectedVoice = voice;
                                                  _tts.setVoice(
                                                    _selectedVoice!,
                                                  );
                                                });
                                                await _tts.speak(
                                                  'Can you hear this voice clearly?',
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      isSelected
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.1)
                                                          : Colors.transparent,
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: Colors.grey[700]!,
                                                      width:
                                                          index <
                                                                  favVoices
                                                                          .length -
                                                                      1
                                                              ? 1
                                                              : 0,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                        4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isMale
                                                                ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                      0.1,
                                                                    )
                                                                : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              isMale
                                                                  ? Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                  : Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .secondary,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Icon(
                                                        isMale
                                                            ? Icons.male
                                                            : Icons.female,
                                                        size: 16,
                                                        color:
                                                            isMale
                                                                ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary
                                                                : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        voice['name'] ??
                                                            'Bilinmeyen Ses',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    ),
                                                    if (voice['language'] !=
                                                        null)
                                                      Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors.grey[800],
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          voice['language']!,
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[300],
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                      ),
                                                    SizedBox(width: 8),
                                                    IconButton(
                                                      icon: Icon(
                                                        isFavorite
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color:
                                                            isFavorite
                                                                ? Colors
                                                                    .redAccent
                                                                : Colors
                                                                    .grey[400],
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        _toggleFavorite(
                                                          voice['name']!,
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                          : _buildSettingCard(
                            title: 'SES',
                            child: Column(
                              children: [
                                // Filtreleme Butonları
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedGender = 'female';
                                            _filterVoices();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _selectedGender == 'female'
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withOpacity(0.2)
                                                  : Theme.of(context).cardColor,
                                          foregroundColor:
                                              _selectedGender == 'female'
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.secondary
                                                  : Colors.grey[400],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.horizontal(
                                                  left: Radius.circular(8),
                                                ),
                                            side: BorderSide(
                                              color:
                                                  _selectedGender == 'female'
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.secondary
                                                      : Colors.grey[600]!,
                                              width: 1,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.female, size: 18),
                                            SizedBox(width: 8),
                                            Text('Kadın'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedGender = 'male';
                                            _filterVoices();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              _selectedGender == 'male'
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.2)
                                                  : Theme.of(context).cardColor,
                                          foregroundColor:
                                              _selectedGender == 'male'
                                                  ? Theme.of(
                                                    context,
                                                  ).colorScheme.primary
                                                  : Colors.grey[400],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.horizontal(
                                                  right: Radius.circular(8),
                                                ),
                                            side: BorderSide(
                                              color:
                                                  _selectedGender == 'male'
                                                      ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                      : Colors.grey[600]!,
                                              width: 1,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.male, size: 18),
                                            SizedBox(width: 8),
                                            Text('Erkek'),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),

                                // Ses Seçim Listesi
                                if (_filteredVoices.isEmpty)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'Filtreleme kriterlerine uygun ses bulunamadı',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      border: Border.all(
                                        color: Colors.grey[700]!,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: 150, // 2 * kVoiceItemHeight
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _filteredVoices.length,
                                        itemBuilder: (context, index) {
                                          final voice = _filteredVoices[index];
                                          final name =
                                              voice['name']?.toLowerCase() ??
                                              '';
                                          final isMale =
                                              name.contains('tpd') ||
                                              name.contains('iol') ||
                                              name.contains('iom') ||
                                              name.contains('gbd') ||
                                              name.contains('rjs') ||
                                              name.contains('gbb');
                                          final isSelected =
                                              _selectedVoice == voice;
                                          final isFavorite = _favoriteVoiceNames
                                              .contains(voice['name']);

                                          return InkWell(
                                            onTap: () async {
                                              setState(() {
                                                _selectedVoice = voice;
                                                _tts.setVoice(_selectedVoice!);
                                              });
                                              await _tts.speak(
                                                'Can you hear this voice clearly?',
                                              );
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1)
                                                        : Colors.transparent,
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey[700]!,
                                                    width:
                                                        index <
                                                                _filteredVoices
                                                                        .length -
                                                                    1
                                                            ? 1
                                                            : 0,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isMale
                                                              ? Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .primary
                                                                  .withOpacity(
                                                                    0.1,
                                                                  )
                                                              : Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            isMale
                                                                ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .primary
                                                                : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .secondary,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      isMale
                                                          ? Icons.male
                                                          : Icons.female,
                                                      size: 16,
                                                      color:
                                                          isMale
                                                              ? Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .primary
                                                              : Theme.of(
                                                                    context,
                                                                  )
                                                                  .colorScheme
                                                                  .secondary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      voice['name'] ??
                                                          'Bilinmeyen Ses',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (voice['language'] != null)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[800],
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        voice['language']!,
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[300],
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ),
                                                  SizedBox(width: 8),
                                                  IconButton(
                                                    icon: Icon(
                                                      isFavorite
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      color:
                                                          isFavorite
                                                              ? Colors.redAccent
                                                              : Colors
                                                                  .grey[400],
                                                      size: 20,
                                                    ),
                                                    onPressed: () {
                                                      _toggleFavorite(
                                                        voice['name']!,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                    ],
                    SizedBox(height: 16),
                    _buildSettingCard(
                      title: 'KONUŞMA HIZI',
                      child: Slider(
                        min: 0.1,
                        max: 1.0,
                        divisions: 18,
                        value: _speechRate,
                        label: _speechRate.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() {
                            _speechRate = value;
                            _tts.setSpeechRate(_speechRate);
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(
                            _isSpeaking ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(_isSpeaking ? 'Durdur' : 'Test Oku'),
                          onPressed: _speakTest,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.refresh),
                          label: Text("Sıfırla"),
                          onPressed: _sifirla,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildSettingCard({required String title, required Widget child}) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (title == 'SES') ...[_buildFavoriteToggle()],
              ],
            ),
            SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  void _sifirla() async {
    setState(() {
      _currentLang = 'en-US';
      _speechRate = 0.5;
      _pitch = 1.0;
      _selectedGender = 'female';
    });

    // TTS ayarlarını uygula
    await _tts.setLanguage(_currentLang);
    await _tts.setSpeechRate(_speechRate);
    await _tts.setPitch(_pitch);

    // Yeni dil için ses listesini yeniden al
    final voicesData = await _tts.getVoices;
    _voices = _convertVoicesToList(voicesData, _currentLang);

    // Yeni dile göre filtrele
    _filterVoices();

    if (_filteredVoices.isNotEmpty) {
      final hasDefaultVoice = _filteredVoices.any(
        (voice) => voice['name'] == 'en-us-x-sfg-network',
      );

      _selectedVoice =
          hasDefaultVoice
              ? _filteredVoices.firstWhere(
                (voice) => voice['name'] == 'en-us-x-sfg-network',
              )
              : _filteredVoices.first;
    } else {
      _selectedVoice = null;
    }

    if (_selectedVoice != null) {
      await _tts.setVoice(_selectedVoice!);
      //_tts.speak("Can you hear this voice clearly?");
    }

    setState(() {}); // Tüm verileri güncelle
  }

  Widget _buildFavoriteToggle() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(
          _showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
          color:
              _showOnlyFavorites
                  ? theme.colorScheme.secondary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
          size: 18,
        ),
        SizedBox(width: 6),
        Text(
          'Favoriler',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(width: 8),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: _showOnlyFavorites,
            onChanged: (val) async {
              final prefs = await SharedPreferences.getInstance();
              setState(() {
                _showOnlyFavorites = val;
              });
              await prefs.setBool('showOnlyFavorites', val);
              _filterVoices(); // toggle değişince filtreyi tekrar uygula
            },
            activeColor: Colors.white,
            activeTrackColor: theme.colorScheme.primary.withOpacity(1),
            inactiveThumbColor: theme.colorScheme.onSurface.withOpacity(1),
            inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0),
          ),
        ),
      ],
    );
  }
}
