import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/services/isar_service.dart';

class WordProvider with ChangeNotifier {
  final IsarService _isarService = IsarService();

  List<Word> _words = [];
  List<Word> get words => _words;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadWords() async {
    _isLoading = true;
    notifyListeners();

    _words = await _isarService.getAllWords();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWord(Word word) async {
    await _isarService.addWord(word);
    await loadWords(); // veritabanından tekrar çek ve güncelle
  }

  Future<void> deleteWord(int id) async {
    await _isarService.deleteWord(id);
    await loadWords(); // aynı şekilde listeyi tazele
  }

  Future<void> toggleLearned(int id) async {
    await _isarService.toggleWordLearned(id);
    await loadWords(); // güncellemeden sonra reload
  }

  Future<void> refreshWords() async {
    await loadWords();
  }
}
