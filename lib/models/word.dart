import 'package:isar/isar.dart';

part 'word.g.dart';

@collection
class Word {
  Id id = Isar.autoIncrement;

  late String word; // The word itself
  late String meaning; // The meaning of the word 
  late String example;  // An example sentence using the word 
  List<String> examples; // A list of example sentences using the word
  late String type; 
  String? story;
  bool islearned = false;
  int repetitionLevel;
  DateTime nextReview;

  @Index()  
  late DateTime createdAt = DateTime.now();
  
  Word({
    required this.word,
    required this.meaning,
    required this.example,
    required this.type,
    this.story,
    required this.repetitionLevel,
    required this.nextReview, 
    required DateTime createdAt, 
    List<String> examples = const [],
  }): examples = examples; 

  @override
  String toString() {
    return 'Word(id: $id, word: $word, meaning: $meaning, example: $example, type: $type, story: $story, islearned: $islearned)';
  }
}
