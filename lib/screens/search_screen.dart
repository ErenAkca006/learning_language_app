import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/isar_service.dart';

class SearchScreen extends StatefulWidget {
  final IsarService isarService;

  const SearchScreen({super.key, required this.isarService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Word> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialWords();
  }

  Future<void> _loadInitialWords() async {
    final words = await widget.isarService.getAllWords();
    setState(() {
      _searchResults = words;
    });
  }

  Future<void> _searchWords(String query) async {
    if (query.isEmpty) {
      await _loadInitialWords();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await widget.isarService.searchWords(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelime Ara')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kelime veya anlam ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchWords('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchWords(value);
              },
            ),
          ),
          _isSearching
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final word = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(word.word),
                        subtitle: Text(word.meaning),
                        trailing: Text(word.type),
                        onTap: () {
                          // Kelime detayına gitmek için
                        },
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
