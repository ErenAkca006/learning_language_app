import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:isar/isar.dart';

class StatisticsService {
  final Isar isar;

  StatisticsService(this.isar);

  Future<List<DailyWordCount>> getDailyWordCounts({int dayCount = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: dayCount - 1));
      final endDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: 1));

      final words =
          await isar.words
              .where()
              .filter()
              .createdAtBetween(startDate, endDate)
              .findAll();

      // Tüm tarihleri 0 ile başlat
      final dailyCounts = <DateTime, int>{};
      for (var i = 0; i < dayCount; i++) {
        final date = startDate.add(Duration(days: i));
        dailyCounts[date] = 0;
      }

      // Kelimeleri tarihlere göre grupla
      for (final word in words) {
        final date = DateTime(
          word.createdAt.year,
          word.createdAt.month,
          word.createdAt.day,
        );
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }

      return dailyCounts.entries
          .map((e) => DailyWordCount(e.key, e.value))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('getDailyWordCounts error: $e');
      return [];
    }
  }

  // Toplam kelime sayısını getir
  Future<int> getTotalWordCount() async {
    return await isar.words.count();
  }

  // Tekrar seviyesine göre kelime sayılarını getir
  Future<Map<int, int>> getWordsByRepetitionLevel() async {
    final words = await isar.words.where().findAll();
    final counts = <int, int>{};

    for (var word in words) {
      counts[word.repetitionLevel] = (counts[word.repetitionLevel] ?? 0) + 1;
    }

    return counts;
  }
}

class DailyWordCount {
  final DateTime date;
  final int count;

  DailyWordCount(this.date, this.count);
}
