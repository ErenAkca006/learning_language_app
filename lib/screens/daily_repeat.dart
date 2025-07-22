import 'package:flutter/material.dart';
import 'package:flutter_word_app/main.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_word_app/screens/statistics_page.dart';
import 'package:flutter_word_app/services/isar_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';

int count = 1;

class RepeatPage extends ConsumerStatefulWidget {
  final IsarService isarService;
  const RepeatPage({super.key, required this.isarService});

  @override
  RepeatPageState createState() => RepeatPageState();
}

// ignore: unused_element
late Future<List<Word>> _getAllWord;

class RepeatPageState extends ConsumerState<RepeatPage> {
  int _currentIndex = 0;
  bool _showMeaning = false;
  late Future<List<Word>> _wordsFuture;
  List<Word> _activeWords = [];
  FlutterTts flutterTts = FlutterTts();
  List<dynamic> voices = [];
  dynamic selectedVoice;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ttsServiceProvider);
    });
    _fetchWords();
  }

  String _calculateNextReview(int level, String tag) {
    if (tag == "İyi") {
      level += 2;
    }
    if (tag == "Orta") {
      level += 1;
    }
    if (tag == "Temel") {
      level = 0;
    }
    switch (level) {
      case 0:
        return "10 dk";
      case 1:
        return "30 dk";
      case 2:
        return "1 saat";
      case 3:
        return "1 gün";
      case 4:
        return "3 gün";
      case 5:
        return "7 gün";
      default:
        return "15 gün";
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _fetchWords() {
    _wordsFuture = widget.isarService.getWordsToReviewToday().then((words) {
      setState(() {
        _activeWords = words;
        _currentIndex = 0;
      });
      return words;
    });
  }

  Future<void> _handleTagSelection(Word word, String tag) async {
    word.type = tag;
    if (tag == 'Temel') {
      await widget.isarService.markWordAsForgotten(word);
    } else {
      await widget.isarService.markWordAsReviewed(word);
    }
    await widget.isarService.isar.writeTxn(() async {
      await widget.isarService.isar.words.put(word);
    });

    setState(() {
      _showMeaning = false;
      _activeWords.removeAt(_currentIndex);

      if (_activeWords.isEmpty) {
        // Tüm kelimeler bittiğinde yeni kelimeleri yükle
        Future.delayed(const Duration(milliseconds: 500), () {
          _fetchWords();
        });
      } else {
        _currentIndex = _currentIndex % _activeWords.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Günlük Tekrar', style: GoogleFonts.poppins()), 
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWords,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: FutureBuilder<List<Word>>(
        future: _wordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || _activeWords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Bugünlük tekrar yok 🔥",
                    style: GoogleFonts.poppins(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  StatisticsPage(isar: widget.isarService.isar),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "İstatistikleri Gör",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.analytics_outlined,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final currentWord = _activeWords[_currentIndex];

          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showMeaning = !_showMeaning),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _showMeaning
                            ? _buildMeaningCard(currentWord)
                            : _buildWordCard(currentWord),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withAlpha(50),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.red.withAlpha(80)),
                        ),
                      ),
                      onPressed:
                          () => _handleTagSelection(currentWord, 'Temel'),
                      child: Text(
                        "# ${_calculateNextReview(currentWord.repetitionLevel, "Temel")}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withAlpha(50),
                        foregroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.orange.withAlpha(80)),
                        ),
                      ),
                      onPressed: () => _handleTagSelection(currentWord, 'Orta'),
                      child: Text(
                        "# ${_calculateNextReview(currentWord.repetitionLevel, "Orta")}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withAlpha(50),
                        foregroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.green.withAlpha(80)),
                        ),
                      ),
                      onPressed: () => _handleTagSelection(currentWord, 'İyi'),
                      child: Text(
                        "# ${_calculateNextReview(currentWord.repetitionLevel, "İyi")}",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWordCard(Word word) {
    final ttsService = ref.read(ttsServiceProvider);
    ttsService.stop(); // kart değişince otomatik durdur
    bool isSpeaking = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            Container(
              key: ValueKey('word_${word.word}'),
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
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
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
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
                              setState(() => isSpeaking = false);
                            } else {
                              await ttsService.stop();
                              ttsService.speak(word.word);
                              setState(() => isSpeaking = true);

                              flutterTts.setCompletionHandler(() {
                                setState(() => isSpeaking = false);
                              });
                            }
                          },
                          tooltip: 'Kelimeyi Seslendir',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeaningCard(Word word, {Key? key}) {
    final ttsService = ref.read(ttsServiceProvider);
    ttsService.stop(); // kart değiştiğinde ses kesilir
    String? currentlySpeaking;

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
                color: Colors.black.withOpacity(0.3),
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
                                ttsService.speak(example);
                                setState(() {
                                  currentlySpeaking = example;
                                });
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

  Future<List<Word>> _getAllWordsFromDb() async {
    return await widget.isarService.getAllWords();
  }

  void refreshData() {
    setState(() {
      _getAllWord = _getAllWordsFromDb();
    });
  }
}
