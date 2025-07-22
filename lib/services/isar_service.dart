import 'package:flutter/widgets.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      isar = await Isar.open([WordSchema], directory: directory.path);
      debugPrint('Isar database opened successfully');
    } catch (e) {
      debugPrint('Error opening Isar: $e');
    }
  }

  // Future<void> saveWord(Word word) async {
  //   try {
  //     await isar.writeTxn(() async {
  //       final id = await isar.words.put(word);
  //       debugPrint(
  //         'YENİ KELİME ${word.word} KAYDEDİLDİ: $id değeri ile eklendi',
  //       );
  //     });
  //   } catch (e) {
  //     debugPrint('Error saving word: $e');
  //   }
  // }
  // IsarService'teki saveWord metodunu şu şekilde güncelleyin:
  Future<bool> saveWord(Word word) async {
    try {
      await isar.writeTxn(() async {
        await isar.words.put(
          word,
        ); // put() yerine putSync() de deneyebilirsiniz
      });
      print('Kelime başarıyla kaydedildi: ${word.id}');
      return true;
    } catch (e, stack) {
      print('Kayıt hatası: $e');
      print('Stack trace: $stack');
      return false;
    }
  }

  Future<List<Word>> getWordsByTag(String tag) async {
    final allWords = await getAllWords();
    return allWords.where((word) => word.type == tag).toList();
  }
  // Future<bool> saveWord(Word word) async {
  //   try {
  //     await isar.writeTxn(() async {
  //       await isar.words.put(word); // put metodu id'yi otomatik günceller
  //     });
  //     return true;
  //   } catch (e) {
  //     debugPrint('Error saving word: $e');
  //     return false;
  //   }
  // }

  Future<List<Word>> getAllWords() async {
    try {
      final words = await isar.words.where().findAll();
      return words;
    } catch (e) {
      debugPrint('KELİMELER GETİRİLEMEDİ : $e');
      return [];
    }
  }

  Future<List<Word>> getWordsToReviewToday() async {
    final now = DateTime.now();
    return await isar.words
        .filter()
        .nextReviewLessThan(now, include: true)
        .sortByNextReview()
        .findAll();
  }

  // Future<List<Word>> getWordsToReviewToday() async {
  //   final now = DateTime.now();
  //   final oneWeekLater = now.add(Duration(days: 7));

  //   return await isar.words
  //       .filter()
  //       .nextReviewLessThan(oneWeekLater, include: true)
  //       .sortByNextReview()
  //       .findAll();
  // }

  Future<void> markWordAsReviewed(Word word) async {
    final newLevel =
        word.type == 'Orta'
            ? word.repetitionLevel + 1
            : word.repetitionLevel + 2;
    final next = _calculateNextReview(newLevel);

    await isar.writeTxn(() async {
      word.repetitionLevel = newLevel;
      word.nextReview = next;
      await isar.words.put(word);
    });
  }

  Future<void> markWordAsForgotten(Word word) async {
    await isar.writeTxn(() async {
      word.repetitionLevel = 0;
      word.nextReview = DateTime.now().add(Duration(minutes: 10));
      await isar.words.put(word);
    });
  }

  DateTime _calculateNextReview(int level) {
    switch (level) {
      case 1:
        return DateTime.now().add(Duration(minutes: 30)); //minutes: 10
      case 2:
        return DateTime.now().add(Duration(hours: 1)); //hours: 1
      case 3:
        return DateTime.now().add(Duration(days: 1)); //days: 1
      case 4:
        return DateTime.now().add(Duration(days: 3)); //days: 3
      case 5:
        return DateTime.now().add(Duration(days: 7)); //days: 7
      default:
        return DateTime.now().add(Duration(days: 15)); //days: 15
    }
  }

  Future<void> updateWord(Word word) async {
    try {
      await isar.writeTxn(() async {
        final id = await isar.words.put(word);
        debugPrint('KELİME OLAN ${word.word} $id değeri ile GÜNCELLENDİ');
      });
    } catch (e) {
      debugPrint('KELİME GÜNCELLEME HATASI: $e');
    }
  }

  Future<void> toggleWordLearned(int id) async {
    try {
      await isar.writeTxn(() async {
        final word = await isar.words.get(id);
        if (word != null) {
          word.islearned = !word.islearned;
          await isar.words.put(word);
          debugPrint('KELİME OLAN ${word.word} $id değeri ile GÜNCELLENDİ');
        } else {
          debugPrint('KELİME BULUNAMADI: $id');
        }
      });
    } catch (e) {
      debugPrint('KELİME GÜNCELLEME HATASI: $e');
    }
  }

  Future<Word?> getWordById(int id) async {
    return await isar.words.get(id);
  }

  Future<List<Word>> searchWords(String query) async {
    return await isar.words
        .where()
        .filter()
        .wordContains(query, caseSensitive: false)
        .or()
        .meaningContains(query, caseSensitive: false)
        .findAll();
  }

  // // Günlük tekrar kelimeleri
  // // isar_service.dart
  // Stream<List<Word>> getWordsDueForReview() {
  //   try {
  //     final now = DateTime.now();
  //     return isar.words
  //         .filter()
  //         .nextReviewLessThan(now)
  //         .sortByNextReview()
  //         .watch();
  //   } on IsarError catch (e) {
  //     debugPrint('Isar error: $e');
  //     return Stream.error(e);
  //   }
  // }

  // Kelime ekleme
  Future<void> addWord(Word word) async {
    await isar.writeTxn(() => isar.words.put(word));
  }

  // Tekrar tarihini güncelleme
  Future<void> updateWordReview(Word word) async {
    await isar.writeTxn(() => isar.words.put(word));
  }

  Future<void> deleteWord(int id) async {
    try {
      await isar.writeTxn(() async {
        final success = await isar.words.delete(id);
        if (success) {
          debugPrint('KELİME $id ID ile SİLİNDİ');
        } else {
          debugPrint('KELİME BULUNAMADI: $id');
        }
      });
    } catch (e) {
      debugPrint('KELİME SİLME HATASI: $e');
    }
  }

  Future<int> deleteWords(List<int> ids) async {
    int deletedCount = 0;
    await isar.writeTxn(() async {
      deletedCount = await isar.words.deleteAll(ids);
    });
    return deletedCount;
  }
}
