import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_word_app/main.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/screens/addingScreen.dart';
import 'package:flutter_word_app/services/isar_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

int count = 1;

class PracticeScreen extends ConsumerStatefulWidget {
  final IsarService isarService;
  const PracticeScreen({super.key, required this.isarService});

  @override
  PracticeScreenState createState() => PracticeScreenState();
}

class PracticeScreenState extends ConsumerState<PracticeScreen> {
  String? currentlySpeaking;
  int _currentIndex = 0;
  bool _showMeaning = false;
  String _selectedTag = 'Temel'; // Varsayılan olarak "Kötü" kelimelerle başla
  late Future<List<Word>> _wordsFuture;
  dynamic selectedVoice;
  FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ttsServiceProvider);
    });

    _wordsFuture = _getWordsFromDb();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<List<Word>> _getWordsFromDb() async {
    return await widget.isarService.getAllWords();
  }

  List<Word> _filterWords(List<Word> words) {
    return words.where((word) => word.type == _selectedTag).toList();
  }

  Future<void> _updateTag(Word word, String newTag) async {
    // 1. Kategoriyi güncelle
    word.type = newTag;
    await widget.isarService.updateWord(word);

    // 2. Yeni filtrelenmiş listeyi al
    final allWords = await widget.isarService.getAllWords();
    final currentFilteredWords = _filterWords(allWords);

    // 3. Sonraki kelime indexini hesapla
    int newIndex = _currentIndex;

    // Eğer son kelime değilse bir sonrakine geç
    if (newIndex < currentFilteredWords.length - 1) {
      newIndex++;
    } else {
      // Son kelimeyse başa dön
      newIndex = 0;
    }

    // 4. Güncelle
    setState(() {
      _showMeaning = false;
      _currentIndex = newIndex;
    });
  }

  Color _getColorForTag(String tag) {
    switch (tag) {
      case 'İyi':
        return Colors.green[400]!;
      case 'Orta':
        return Colors.orange[400]!;
      case 'Temel':
        return Colors.red[400]!;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Genel Tekrar', style: GoogleFonts.poppins()),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded), // Daha anlamlı ikon
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        "Seviye Seç",
                        textAlign: TextAlign.center,
                      ),
                      content: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'Temel',
                            label: Text('Temel'),
                            icon: Icon(Icons.thumb_down),
                          ),
                          ButtonSegment(
                            value: 'Orta',
                            label: Column(children: [Text('Orta')]),
                            icon: Icon(Icons.thumbs_up_down),
                          ),
                          ButtonSegment(
                            value: 'İyi',
                            label: Text('İyi'),
                            icon: Icon(Icons.thumb_up),
                          ),
                        ],
                        selected: {_selectedTag},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedTag = newSelection.first;
                            _currentIndex = 0;
                            _showMeaning = false;
                            _wordsFuture = _getWordsFromDb();
                          });
                          Navigator.pop(context); // Dialog'u kapat
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.2);
                            }
                            return Theme.of(
                              context,
                            ).colorScheme.surfaceVariant.withOpacity(0.1);
                          }),
                          foregroundColor: MaterialStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Theme.of(context).colorScheme.primary;
                            }
                            return Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color;
                          }),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
              );
            },
          ),
        ],
      ),

      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FutureBuilder<List<Word>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Hata: BURADA BİR HATA VAR ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kelime bulunamadı',
                    style: GoogleFonts.poppins(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AddPage(isarService: widget.isarService),
                          ),
                        ),
                    child: const Text('Kelime Ekleme Sayfasına Git'),
                  ),
                ],
              ),
            );
          }

          final filteredWords = _filterWords(snapshot.data!);

          if (filteredWords.isEmpty) {
            final List<String> categories = ['Temel', 'Orta', 'İyi'];
            final int currentIndex = categories.indexOf(_selectedTag);

            final bool showLeft = currentIndex > 0;
            final bool showRight = currentIndex < categories.length - 1;

            return Column(
              children: [
                const SizedBox(height: 10),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              Icons.emoji_events,
                              size: 80,
                              color: Colors.amberAccent.shade200,
                            ),
                          ),
                          const SizedBox(height: 20),
                          AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 800),
                            child: Text(
                              'Tebrikler! 🎉',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$_selectedTag kategorisindeki tüm kelimeleri \ntamamladın!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (showLeft)
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedTag =
                                          categories[currentIndex - 1];
                                      _currentIndex = 0;
                                      _showMeaning = false;
                                      _wordsFuture = _getWordsFromDb();
                                    });
                                  },
                                ),
                              const SizedBox(width: 20),
                              if (showRight)
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedTag =
                                          categories[currentIndex + 1];
                                      _currentIndex = 0;
                                      _showMeaning = false;
                                      _wordsFuture = _getWordsFromDb();
                                    });
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (_currentIndex >= filteredWords.length) {
            _currentIndex = 0;
          }

          final currentWord = filteredWords[_currentIndex];
          final color = _getColorForTag(currentWord.type);

          return Column(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _showMeaning = !_showMeaning),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child:
                          _showMeaning
                              ? _buildMeaningCard(
                                currentWord,
                                color,
                                key: ValueKey(
                                  '${_showMeaning ? 'm' : 'w'}_$_currentIndex',
                                ),
                              )
                              : _buildWordCard(
                                currentWord,
                                key: ValueKey(
                                  '${_showMeaning ? 'm' : 'w'}_$_currentIndex',
                                ),
                              ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTagButton('Temel', Colors.red, currentWord),
                    _buildTagButton('Orta', Colors.orange, currentWord),
                    _buildTagButton('İyi', Colors.green, currentWord),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWordCard(Word word, {Key? key}) {
    //flutterTts.stop(); // kart değişince otomatik durdur
    final ttsService = ref.read(ttsServiceProvider);
    ttsService.stop(); // kart değişince otomatik durdur
    bool isSpeaking = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          key: key,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.5 - 40,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      word.word,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 20),
                    if (!word.word.contains("Tebrikler")) ...[
                      IconButton(
                        icon: Icon(
                          isSpeaking ? Icons.stop_circle : Icons.volume_up,
                          size: 36,
                          color: const Color(0xFF6C63FF),
                        ),
                        onPressed: () async {
                          final ttsService = ref.read(ttsServiceProvider);
                          if (isSpeaking) {
                            await ttsService.stop();
                            setState(() {
                              isSpeaking = false;
                            });
                          } else {
                            await ttsService.stop();
                            setState(() {
                              isSpeaking = true;
                            });
                            await ttsService.speak(
                              word.word,
                              onComplete: () {
                                setState(() {
                                  isSpeaking = false;
                                });
                              },
                            );
                            flutterTts.setCompletionHandler(() {
                              setState(() => isSpeaking = false);
                            });
                          }
                        },
                        tooltip: 'Kelimeyi Seslendir',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeaningCard(Word word, Color color, {Key? key}) {
    final ttsService = ref.read(ttsServiceProvider);
    ttsService.stop(); // kart değiştiğinde ses kesilir

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          key: key,
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(77),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(
                  word.meaning,
                  style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                if (word.examples?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 20),
                  ...word.examples!.map(
                    (example) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SelectableText(
                              example,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              currentlySpeaking == example
                                  ? Icons.stop_circle
                                  : Icons.volume_up,
                              size: 24,
                              color: const Color(0xFF6C63FF),
                            ),
                            onPressed: () async {
                              final ttsService = ref.read(ttsServiceProvider);
                              if (currentlySpeaking == example) {
                                await ttsService.stop();
                                setState(() {
                                  currentlySpeaking = null;
                                });
                              } else {
                                await ttsService.stop();
                                setState(() {
                                  currentlySpeaking = example;
                                });
                                await ttsService.speak(
                                  example,
                                  onComplete:
                                      () => setState(
                                        () => currentlySpeaking = null,
                                      ),
                                );
                                flutterTts.setCompletionHandler(() {
                                  setState(() {
                                    currentlySpeaking = null;
                                  });
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagButton(String tag, Color color, Word currentWord) {
    String tilda = '# ';
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withAlpha(50),
        foregroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withAlpha(80)),
        ),
      ),
      onPressed: () => _updateTag(currentWord, tag),
      child: Text(
        tilda + tag,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  void refreshData() {}
}
