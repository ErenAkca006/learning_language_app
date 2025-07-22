import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/services/isar_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AddPage extends StatefulWidget {
  final IsarService isarService;  
  const AddPage({super.key, required this.isarService});

  @override
  State<AddPage> createState() => _AddPageState();
}

// ignore: unused_element
late Future<List<Word>> _getAllWord;

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final _englishController = TextEditingController();
  final _turkishController = TextEditingController();
  final _storyController = TextEditingController();
  final _exampleControllers = [TextEditingController()];
  String _selectedWordType = "Temel";
  bool islearned = false;
  List<String> wordCase = ['Temel', 'Orta', 'İyi'];

  @override
  void dispose() {
    _englishController.dispose();
    _turkishController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getAllWord = _getAllWordsFromDb();
 
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      // DEBUG: Kontrollerin içeriğini yazdır
      print('Example Controllers: EREN AKCA');
      _exampleControllers.forEach((c) => print(c.text.trim()));

      final exampleSentences =
          _exampleControllers
              .map((controller) => controller.text.trim())
              .where((sentence) => sentence.isNotEmpty)
              .toList();

      print('Valid Examples DOLU MU: $exampleSentences'); // Bu liste dolu mu?

      final newWord = Word(
        word: _englishController.text.trim(),
        meaning: _turkishController.text.trim(),
        example: _storyController.text.trim(),
        examples: exampleSentences,
        type: _selectedWordType,
        story: _storyController.text.trim(),
        repetitionLevel: 0,
        nextReview: DateTime.now(),
        createdAt: DateTime.now(),
      );

      print('Kaydedilecek Word Objesi:');
      print('Word: ${newWord.word}');
      print('Examples: ${newWord.examples}'); // Burada dolu olmalı

      final isSaved = await widget.isarService.saveWord(newWord);

      if (isSaved && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFF1E2139),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF6C63FF).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kelime başarıyla eklendi',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Builder(
                    builder:
                        (context) => IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(20),
            duration: Duration(seconds: 2),
          ),
        );

        // Ana sayfaya verinin güncellendiği bilgisini gönder
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Kelime eklenemedi'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Word',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E2139),
        iconTheme: const IconThemeData(color: Color(0xFF6C63FF)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),
              // English Word Field
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter english word";
                  }
                  return null;
                },
                controller: _englishController,
                style: GoogleFonts.poppins(
                  // 👈 Buraya dikkat
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  labelText: "English Word",
                  labelStyle: GoogleFonts.poppins(
                    // 👈 Buraya da dikkat
                    color: Color(0xFF6C63FF),
                  ),
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E2139),
                  prefixIcon: const Icon(
                    Icons.language,
                    color: Color(0xFF6C63FF),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Turkish Word Field
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter turkish word";
                  }
                  return null;
                },
                controller: _turkishController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Turkish Word",
                  labelStyle: TextStyle(color: Color(0xFF6C63FF)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E2139),
                  prefixIcon: Icon(Icons.translate, color: Color(0xFF6C63FF)),
                ),
              ),
              const SizedBox(height: 24),

              // Word Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedWordType,
                style: const TextStyle(color: Colors.white),
                dropdownColor: const Color(0xFF1E2139),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                  label: Text(
                    "Word Type",
                    style: TextStyle(color: Color(0xFF6C63FF)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E2139),
                  prefixIcon: Icon(Icons.category, color: Color(0xFF6C63FF)),
                ),
                items:
                    wordCase.map((e) {
                      return DropdownMenuItem(
                        child: Text(
                          e,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: e,
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWordType = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Word Story Field
              TextFormField(
                controller: _storyController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Word Story",
                  labelStyle: TextStyle(color: Color(0xFF6C63FF)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF6C63FF),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1E2139),
                  prefixIcon: Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                maxLines: 3,
              ),
              // Örnek Cümleler Başlığı
              const SizedBox(height: 16),
              Text(
                "Example Sentences",
                style: TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              // Cümle Cümle TextField'lar
              ..._exampleControllers.asMap().entries.map((entry) {
                int index = entry.key;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: entry.value,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Example sentence ${index + 1}",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: const Color(0xFF1E2139),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[600]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6C63FF),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (index > 0)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              _exampleControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),

              // ➕ Cümle Ekle Butonu
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _exampleControllers.add(TextEditingController());
                    });
                  },
                  icon: Icon(Icons.add, color: Color(0xFF6C63FF)),
                  label: Text(
                    "Cümle Ekle",
                    style: TextStyle(color: Color(0xFF6C63FF)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              ElevatedButton(
                onPressed: _saveWord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shadowColor: const Color(0xFFFF6584).withOpacity(0.3),
                ),
                child: const Text(
                  "SAVE WORD",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF121421),
    );
  }

  void refresh() {
    setState(() {
      _getAllWord = _getAllWordsFromDb();
    });
  }

  Future<List<Word>> _getAllWordsFromDb() async {
    return await widget.isarService.getAllWords();
  }
}


  // Future<void> _saveWord() async {
  //   if (_formKey.currentState!.validate()) {
  //     try {
  //       final newWord = Word(
  //         word: _englishController.text,
  //         meaning: _turkishController.text,
  //         example: _storyController.text,
  //         type: _selectedWordType,
  //         // imagePath: _imagefile?.path, // Eğer Word modelinizde imagePath alanı varsa
  //       );

  //       await widget.isarService.saveWord(newWord);

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text(
  //             '✅ Kelime başarıyla eklendi',
  //             style: TextStyle(color: Colors.white),
  //           ),
  //           backgroundColor: const Color.fromARGB(255, 0, 0, 0),
  //           behavior: SnackBarBehavior.floating,
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           margin: EdgeInsets.only(bottom: 30, left: 20, right: 20),
  //           duration: Duration(seconds: 2),
  //           elevation: 6,
  //         ),
  //       );

  //       // Formu temizle
  //       _englishController.clear();
  //       _turkishController.clear();
  //       _storyController.clear();
  //       _formKey.currentState?.reset();
  //       setState(() {
  //         _imagefile = null;
  //         _selectedWordType = "Temel";
  //       });

  //       // Eğer ekleme sonrası başka bir işlem yapılacaksa
  //       // Örneğin, önceki sayfaya dönmek için:
  //       // Navigator.pop(context, true); // true, başarılı olduğunu belirtir
  //     } catch (e) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Hata: Kelime eklenemedi - $e'),
  //           backgroundColor: Colors.red,
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //     }
  //   }
  // }